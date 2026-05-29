package com.veto.veto

import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.SocketTimeoutException
import java.nio.ByteBuffer
import org.json.JSONArray

class VetoVpnService : VpnService(), Runnable {

    companion object {
        private const val TAG = "VetoVpnService"
        const val ACTION_START = "com.veto.veto.START_VPN"
        const val ACTION_STOP = "com.veto.veto.STOP_VPN"
    }

    private var vpnThread: Thread? = null
    private var vpnInterface: ParcelFileDescriptor? = null
    private var isRunning = false
    private var blockedWebsitesList: List<String> = emptyList()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent != null) {
            when (intent.action) {
                ACTION_START -> startVpn()
                ACTION_STOP -> stopVpn()
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }

    @Synchronized
    private fun startVpn() {
        if (isRunning) return
        isRunning = true
        loadBlockedWebsites()
        vpnThread = Thread(this, "VetoVpnThread").apply { start() }
        Log.d(TAG, "VetoVpnService started")
    }

    @Synchronized
    private fun stopVpn() {
        if (!isRunning) return
        isRunning = false
        try {
            vpnInterface?.close()
        } catch (e: Exception) {
            // ignore
        }
        vpnInterface = null
        vpnThread?.interrupt()
        vpnThread = null
        Log.d(TAG, "VetoVpnService stopped")
        stopSelf()
    }

    private fun loadBlockedWebsites() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean("flutter.block_websites_enabled", false)
        if (!enabled) {
            blockedWebsitesList = emptyList()
            return
        }
        val jsonStr = prefs.getString("flutter.blocked_websites", null)
        blockedWebsitesList = if (jsonStr != null) {
            try {
                val arr = JSONArray(jsonStr)
                val list = mutableListOf<String>()
                for (i in 0 until arr.length()) {
                    list.add(arr.getString(i).trim().lowercase())
                }
                list
            } catch (e: Exception) {
                emptyList()
            }
        } else {
            emptyList()
        }
        Log.d(TAG, "Loaded ${blockedWebsitesList.size} blocked websites: $blockedWebsitesList")
    }

    override fun run() {
        var socket: DatagramSocket? = null
        try {
            val builder = Builder()
            builder.setSession("Veto DNS Blocker")
            builder.addAddress("10.0.0.2", 32)
            
            // Route DNS requests into the VPN TUN interface
            builder.addRoute("8.8.8.8", 32)
            builder.addRoute("8.8.4.4", 32)
            builder.addRoute("1.1.1.1", 32)
            builder.addRoute("1.0.0.1", 32)

            builder.addDnsServer("8.8.8.8")
            builder.addDnsServer("1.1.1.1")

            vpnInterface = builder.establish()
            if (vpnInterface == null) {
                Log.e(TAG, "Failed to establish VPN interface")
                return
            }

            val tunnel = FileInputStream(vpnInterface!!.fileDescriptor)
            val output = FileOutputStream(vpnInterface!!.fileDescriptor)
            val packet = ByteArray(32767)

            socket = DatagramSocket()
            protect(socket)

            while (isRunning) {
                val readBytes = tunnel.read(packet)
                if (readBytes > 0) {
                    processPacket(packet, readBytes, output, socket)
                }
            }
        } catch (e: InterruptedException) {
            Log.d(TAG, "VPN Thread interrupted")
        } catch (e: Exception) {
            Log.e(TAG, "Error in VPN loop: ${e.message}", e)
        } finally {
            try {
                socket?.close()
            } catch (e: Exception) {}
            stopVpn()
        }
    }

    private fun processPacket(packet: ByteArray, len: Int, output: FileOutputStream, socket: DatagramSocket) {
        try {
            // IPv4 check: Version 4
            if ((packet[0].toInt() shr 4) != 4) return

            val ihl = (packet[0].toInt() and 0x0F) * 4
            val protocol = packet[9].toInt() and 0xFF

            // Protocol 17 = UDP
            if (protocol != 17) return

            // Destination port
            val destPort = ((packet[ihl + 2].toInt() and 0xFF) shl 8) or (packet[ihl + 3].toInt() and 0xFF)

            // DNS Query is UDP Port 53
            if (destPort != 53) return

            val dnsStart = ihl + 8
            val domain = getQuestionDomain(packet, dnsStart)
            if (domain.isEmpty()) return

            var isBlocked = false
            for (blocked in blockedWebsitesList) {
                if (domain.endsWith(blocked) || domain == blocked || domain.contains(".$blocked")) {
                    isBlocked = true
                    break
                }
            }

            if (isBlocked) {
                Log.d(TAG, "VPN Blocking domain: $domain")
                buildNxDomainResponse(packet, len, ihl)
                output.write(packet, 0, len)
            } else {
                // Forward DNS query to the original requested destination IP
                val destIp = InetAddress.getByAddress(byteArrayOf(packet[16], packet[17], packet[18], packet[19]))
                val udpPayloadLen = (((packet[ihl + 4].toInt() and 0xFF) shl 8) or (packet[ihl + 5].toInt() and 0xFF)) - 8
                if (udpPayloadLen <= 0) return

                val dnsPayload = ByteArray(udpPayloadLen)
                System.arraycopy(packet, ihl + 8, dnsPayload, 0, udpPayloadLen)

                val outPacket = DatagramPacket(dnsPayload, dnsPayload.size, destIp, 53)
                socket.send(outPacket)

                // Receive DNS Response
                val responseBuf = ByteArray(32767)
                val inPacket = DatagramPacket(responseBuf, responseBuf.size)
                socket.soTimeout = 1000 // 1 second timeout
                try {
                    socket.receive(inPacket)
                } catch (e: SocketTimeoutException) {
                    return // Drop query on timeout
                }

                val responseDnsLen = inPacket.length
                val totalResponseLen = ihl + 8 + responseDnsLen
                val responsePacket = ByteArray(totalResponseLen)

                // Copy original IP & UDP headers
                System.arraycopy(packet, 0, responsePacket, 0, ihl + 8)
                // Copy DNS payload
                System.arraycopy(responseBuf, 0, responsePacket, ihl + 8, responseDnsLen)

                // Swap IPs
                for (i in 0 until 4) {
                    responsePacket[12 + i] = packet[16 + i]
                    responsePacket[16 + i] = packet[12 + i]
                }

                // Swap ports
                responsePacket[ihl] = packet[ihl + 2]
                responsePacket[ihl + 1] = packet[ihl + 3]
                responsePacket[ihl + 2] = packet[ihl]
                responsePacket[ihl + 3] = packet[ihl + 1]

                // Update IP length
                responsePacket[2] = ((totalResponseLen shr 8) and 0xFF).toByte()
                responsePacket[3] = (totalResponseLen and 0xFF).toByte()

                // Update UDP length
                val udpLen = responseDnsLen + 8
                responsePacket[ihl + 4] = ((udpLen shr 8) and 0xFF).toByte()
                responsePacket[ihl + 5] = (udpLen and 0xFF).toByte()

                // Clear UDP Checksum
                responsePacket[ihl + 6] = 0
                responsePacket[ihl + 7] = 0

                // IP Checksum recalculation
                responsePacket[10] = 0
                responsePacket[11] = 0
                val ipChecksum = computeIPChecksum(responsePacket, 0, ihl)
                responsePacket[10] = ((ipChecksum.toInt() shr 8) and 0xFF).toByte()
                responsePacket[11] = (ipChecksum.toInt() and 0xFF).toByte()

                output.write(responsePacket, 0, totalResponseLen)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing packet: ${e.message}")
        }
    }

    private fun getQuestionDomain(packet: ByteArray, dnsStart: Int): String {
        var offset = dnsStart + 12
        val domain = StringBuilder()
        while (offset < packet.size) {
            val len = packet[offset].toInt() and 0xFF
            if (len == 0) break
            if (domain.isNotEmpty()) domain.append(".")
            offset++
            if (offset + len > packet.size) break
            domain.append(String(packet, offset, len, Charsets.US_ASCII))
            offset += len
        }
        return domain.toString()
    }

    private fun buildNxDomainResponse(packet: ByteArray, len: Int, ihl: Int) {
        // Swap IPs
        for (i in 0 until 4) {
            val temp = packet[12 + i]
            packet[12 + i] = packet[16 + i]
            packet[16 + i] = temp
        }

        // Swap ports
        val tempPort0 = packet[ihl]
        val tempPort1 = packet[ihl + 1]
        packet[ihl] = packet[ihl + 2]
        packet[ihl + 1] = packet[ihl + 3]
        packet[ihl + 2] = tempPort0
        packet[ihl + 3] = tempPort1

        // Clear UDP Checksum
        packet[ihl + 6] = 0
        packet[ihl + 7] = 0

        // Set DNS flags to Response + NXDOMAIN (0x8183)
        val dnsStart = ihl + 8
        packet[dnsStart + 2] = 0x81.toByte()
        packet[dnsStart + 3] = 0x83.toByte()

        // Clear answer/auth/add records counts
        packet[dnsStart + 6] = 0
        packet[dnsStart + 7] = 0
        packet[dnsStart + 8] = 0
        packet[dnsStart + 9] = 0
        packet[dnsStart + 10] = 0
        packet[dnsStart + 11] = 0

        // Recompute IP Checksum
        packet[10] = 0
        packet[11] = 0
        val ipChecksum = computeIPChecksum(packet, 0, ihl)
        packet[10] = ((ipChecksum.toInt() shr 8) and 0xFF).toByte()
        packet[11] = (ipChecksum.toInt() and 0xFF).toByte()
    }

    private fun computeIPChecksum(packet: ByteArray, offset: Int, length: Int): Short {
        var sum = 0
        var i = offset
        while (i < offset + length - 1) {
            val word = ((packet[i].toInt() and 0xFF) shl 8) or (packet[i + 1].toInt() and 0xFF)
            sum += word
            i += 2
        }
        if (i < offset + length) {
            sum += (packet[i].toInt() and 0xFF) shl 8
        }
        while (sum shr 16 != 0) {
            sum = (sum and 0xFFFF) + (sum shr 16)
        }
        return (sum.inv()).toShort()
    }
}
