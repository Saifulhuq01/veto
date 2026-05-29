package com.veto.veto

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageStatsManager
import android.app.usage.UsageEvents
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import java.util.Calendar

class VetoForegroundService : Service() {

    companion object {
        private const val TAG = "VetoForegroundService"
        private const val CHANNEL_ID = "veto_foreground_channel"
        private const val NOTIFICATION_ID = 8888
        private const val POLL_INTERVAL_MS = 2500L
    }

    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var currentBlockedPackage: String? = null
    private var isPollerRunning = false

    private val checkLimitsRunnable = object : Runnable {
        override fun run() {
            if (isPollerRunning) {
                checkAppLimits()
                handler.postDelayed(this, POLL_INTERVAL_MS)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                buildNotification(),
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, buildNotification())
        }
        
        if (!isPollerRunning) {
            isPollerRunning = true
            handler.post(checkLimitsRunnable)
            Log.d(TAG, "Foreground service started, poller initiated")
        }

        return START_STICKY
    }

    override fun onDestroy() {
        isPollerRunning = false
        handler.removeCallbacks(checkLimitsRunnable)
        removeOverlay()
        Log.d(TAG, "Foreground service stopped")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Veto Enforcements"
            val descriptionText = "Monitors daily application limits and schedules"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Veto Directives Active")
            .setContentText("Foreground limits and website blocking are enforced.")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOngoing(true)
            .build()
    }

    private fun checkAppLimits() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val masterEnabled = prefs.getBoolean("flutter.system_directives_enabled", true)
        if (!masterEnabled) {
            removeOverlay()
            return
        }

        val foregroundPackage = getForegroundPackage() ?: return
        if (foregroundPackage == packageName) {
            // Don't block Veto itself
            removeOverlay()
            return
        }

        val limits = getAppLimits()
        val limitRule = limits.firstOrNull { it.packageName == foregroundPackage && it.isActive }

        if (limitRule != null) {
            val usageMinutes = getAppUsageMinutesToday(foregroundPackage)
            if (usageMinutes >= limitRule.limitMinutes) {
                if (currentBlockedPackage != foregroundPackage) {
                    showOverlay(limitRule.appName, limitRule.limitMinutes, foregroundPackage)
                }
            } else {
                if (currentBlockedPackage == foregroundPackage) {
                    removeOverlay()
                }
            }
        } else {
            if (currentBlockedPackage != null && foregroundPackage != currentBlockedPackage) {
                removeOverlay()
            }
        }
    }

    private fun getForegroundPackage(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        val events = usm.queryEvents(time - 15000, time)
        val event = UsageEvents.Event()
        var lastForegroundApp: String? = null
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                lastForegroundApp = event.packageName
            }
        }
        return lastForegroundApp
    }

    private fun getAppUsageMinutesToday(packageName: String): Long {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        if (stats != null) {
            for (usageStats in stats) {
                if (usageStats.packageName == packageName) {
                    return usageStats.totalTimeInForeground / (1000 * 60)
                }
            }
        }
        return 0L
    }

    private fun showOverlay(appName: String, limitMinutes: Int, targetPackage: String) {
        if (!Settings.canDrawOverlays(this)) {
            Log.w(TAG, "Cannot draw overlay: SYSTEM_ALERT_WINDOW permission not granted")
            return
        }

        handler.post {
            removeOverlay()

            currentBlockedPackage = targetPackage

            // Setup LayoutParams
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                },
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.CENTER
            }

            // Create beautiful glassmorphic block page programmatically
            val root = FrameLayout(this).apply {
                setBackgroundColor(Color.parseColor("#FF0D0D11")) // Obsidian Dark Canvas
            }

            val card = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                val pad = dpToPx(32)
                setPadding(pad, pad, pad, pad)
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#E6121217")) // Translucent card background
                    cornerRadius = dpToPx(24).toFloat()
                    setStroke(dpToPx(1), Color.parseColor("#1AFFFFFF"))
                }
            }

            val cardParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER
                val margin = dpToPx(32)
                setMargins(margin, 0, margin, 0)
            }
            root.addView(card, cardParams)

            // Lock Icon
            val lockIcon = ImageView(this).apply {
                setImageResource(android.R.drawable.ic_lock_lock)
                setColorFilter(Color.parseColor("#FF6B6B")) // Coral color
            }
            val lockParams = LinearLayout.LayoutParams(dpToPx(48), dpToPx(48)).apply {
                bottomMargin = dpToPx(18)
            }
            card.addView(lockIcon, lockParams)

            // Title
            val titleText = TextView(this).apply {
                text = "LIMIT EXCEEDED"
                setTextColor(Color.WHITE)
                textSize = 20f
                typeface = Typeface.create("sans-serif", Typeface.BOLD)
                letterSpacing = 0.1f
                gravity = Gravity.CENTER
            }
            val titleParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(8)
            }
            card.addView(titleText, titleParams)

            // Message
            val msgText = TextView(this).apply {
                text = "Your daily allowance for $appName has expired."
                setTextColor(Color.parseColor("#B3FFFFFF"))
                textSize = 14f
                typeface = Typeface.create("sans-serif", Typeface.NORMAL)
                gravity = Gravity.CENTER
            }
            val msgParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(4)
            }
            card.addView(msgText, msgParams)

            // Detail
            val detailText = TextView(this).apply {
                text = "Limit set: ${limitMinutes}m daily"
                setTextColor(Color.parseColor("#80FF6B6B"))
                textSize = 12f
                typeface = Typeface.create("sans-serif", Typeface.ITALIC)
                gravity = Gravity.CENTER
            }
            val detailParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(24)
            }
            card.addView(detailText, detailParams)

            // Go Back Button
            val backButton = Button(this).apply {
                text = "Go Back"
                setTextColor(Color.WHITE)
                isAllCaps = false
                typeface = Typeface.create("sans-serif", Typeface.BOLD)
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#FF00E676")) // Emerald green
                    cornerRadius = dpToPx(28).toFloat()
                }
                setPadding(dpToPx(32), 0, dpToPx(32), 0)
                setOnClickListener {
                    val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                        addCategory(Intent.CATEGORY_HOME)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(homeIntent)
                    removeOverlay()
                }
            }
            val btnParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(48)
            )
            card.addView(backButton, btnParams)

            try {
                windowManager?.addView(root, params)
                overlayView = root
                Log.d(TAG, "Limit overlay drawn for $targetPackage")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to add window overlay: ${e.message}")
            }
        }
    }

    private fun removeOverlay() {
        handler.post {
            overlayView?.let {
                try {
                    windowManager?.removeView(it)
                } catch (e: Exception) {}
                overlayView = null
                currentBlockedPackage = null
                Log.d(TAG, "Limit overlay removed")
            }
        }
    }

    private fun dpToPx(dp: Int): Int {
        val density = resources.displayMetrics.density
        return (dp * density).toInt()
    }

    class AppLimitRule(
        val packageName: String,
        val appName: String,
        val limitMinutes: Int,
        val isActive: Boolean
    )

    private fun getAppLimits(): List<AppLimitRule> {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("flutter.veto_app_limits", null) ?: return emptyList()
        return try {
            val arr = JSONArray(jsonStr)
            val list = mutableListOf<AppLimitRule>()
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val packName = obj.getString("packageName")
                val appName = obj.optString("appName", packName)
                val limit = obj.getInt("dailyLimitMinutes")
                val active = obj.optBoolean("isActive", true)
                list.add(AppLimitRule(packName, appName, limit, active))
            }
            list
        } catch (e: Exception) {
            emptyList()
        }
    }
}
