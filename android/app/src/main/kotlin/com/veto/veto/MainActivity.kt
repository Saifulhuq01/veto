package com.veto.veto

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Locale

/**
 * MainActivity — FlutterActivity with MethodChannel host for Veto.
 *
 * Handles:
 * - setDeepBlockRule: writes rule to SharedPreferences, broadcasts to AccessibilityService
 * - getActiveRules: reads rules from SharedPreferences
 * - isAccessibilityServiceEnabled: checks Settings.Secure
 * - openAccessibilitySettings: launches system accessibility settings
 * - getTodayUsageMinutes: reads from UsageStatsManager (stub for now)
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.veto.app/bridge"
    }

    private lateinit var rulesEngine: VetoRulesEngine
    private var methodChannel: MethodChannel? = null
    private var pendingEngageLockdown = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestNotificationPermission()
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == "com.veto.veto.ENGAGE_LOCKDOWN") {
            Log.d("MainActivity", "Engage lockdown intent received")
            pendingEngageLockdown = true
            triggerFlutterLockdownIfReady()
        }
    }

    private fun triggerFlutterLockdownIfReady() {
        if (pendingEngageLockdown && methodChannel != null) {
            methodChannel?.invokeMethod("triggerLockdown", null)
            pendingEngageLockdown = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        rulesEngine = VetoRulesEngine(this)

        val mChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = mChannel

        mChannel.setMethodCallHandler { call, result ->
                when (call.method) {

                    "setDeepBlockRule" -> {
                        try {
                            val packageName = call.argument<String>("packageName")
                                ?: return@setMethodCallHandler result.error(
                                    "INVALID_ARG", "packageName is required", null
                                )
                            val targets = call.argument<List<String>>("targets")
                                ?: return@setMethodCallHandler result.error(
                                    "INVALID_ARG", "targets is required", null
                                )
                            val enabled = call.argument<Boolean>("enabled")
                                ?: return@setMethodCallHandler result.error(
                                    "INVALID_ARG", "enabled is required", null
                                )

                            // Write to SharedPreferences
                            rulesEngine.setRule(packageName, targets, enabled)

                            // Broadcast to AccessibilityService to reload rules
                            val intent = Intent(VetoAccessibilityService.ACTION_RELOAD_RULES)
                            intent.setPackage(packageName())
                            sendBroadcast(intent)

                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SET_RULE_FAILED", e.message, null)
                        }
                    }

                    "getActiveRules" -> {
                        try {
                            val json = rulesEngine.getActiveRulesJson()
                            result.success(json)
                        } catch (e: Exception) {
                            result.error("GET_RULES_FAILED", e.message, null)
                        }
                    }

                    "isAccessibilityServiceEnabled" -> {
                        try {
                            val enabled = isAccessibilityServiceActive()
                            result.success(enabled)
                        } catch (e: Exception) {
                            result.error("CHECK_FAILED", e.message, null)
                        }
                    }

                    "openAccessibilitySettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_SETTINGS_FAILED", e.message, null)
                        }
                    }

                    "setLockdownActive" -> {
                        try {
                            val active = call.argument<Boolean>("active") ?: false
                            rulesEngine.setLockdownActive(active)
                            
                            // Broadcast to reload service state
                            val intent = Intent(VetoAccessibilityService.ACTION_RELOAD_RULES)
                            intent.setPackage(packageName())
                            sendBroadcast(intent)
                            
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("LOCKDOWN_STATE_FAILED", e.message, null)
                        }
                    }

                    "getTodayUsageMinutes" -> {
                        // TODO: Implement UsageStatsManager integration
                        // For now, return mock data matching the UI
                        result.success(179) // 2h 59m
                    }

                    "schedulePlannerReminders" -> {
                        try {
                            schedulePlannerReminders()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SCHEDULE_FAILED", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        // Trigger if there was a pending action before Flutter was loaded
        triggerFlutterLockdownIfReady()
        
        // Also run schedule sync on engine configuration
        schedulePlannerReminders()
    }

    /**
     * Check if VetoAccessibilityService is currently enabled in system settings.
     * Parses Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES.
     */
    private fun isAccessibilityServiceActive(): Boolean {
        val serviceId = "${packageName}/${VetoAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        return enabledServices.split(':').any { it.equals(serviceId, ignoreCase = true) }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 101)
            }
        }
    }

    private fun schedulePlannerReminders() {
        val context = applicationContext
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val jsonStr = prefs.getString("flutter.veto_planner_schedules", null)
        
        if (jsonStr.isNullOrEmpty()) {
            Log.d("VetoAlarms", "No schedules found to register reminders")
            return
        }
        
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        try {
            val jsonArray = JSONArray(jsonStr)
            val now = System.currentTimeMillis()
            
            for (i in 0 until jsonArray.length()) {
                val block = jsonArray.getJSONObject(i)
                val id = block.getString("id")
                val dateString = block.getString("dateString")
                val startTime = block.getString("startTime")
                val endTime = block.getString("endTime")
                val title = block.getString("title")
                val description = block.getString("description")
                
                val startEpoch = parseDateTimeToEpoch(dateString, startTime) ?: continue
                val endEpoch = parseDateTimeToEpoch(dateString, endTime) ?: continue
                
                // 1. Fire immediate notification if currently active
                if (now in startEpoch until endEpoch) {
                    Log.d("VetoAlarms", "Schedule active now: $title. Firing immediate reminder.")
                    fireImmediateReminder(context, id, title, description)
                }
                
                // 2. Schedule future alarm
                if (startEpoch > now) {
                    val intent = Intent(context, VetoAlarmReceiver::class.java).apply {
                        putExtra("id", id)
                        putExtra("title", "Focus Session Starting: $title")
                        putExtra("description", description)
                    }
                    
                    val pendingIntent = PendingIntent.getBroadcast(
                        context,
                        id.hashCode(),
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            startEpoch,
                            pendingIntent
                        )
                    } else {
                        alarmManager.setExact(
                            AlarmManager.RTC_WAKEUP,
                            startEpoch,
                            pendingIntent
                        )
                    }
                    Log.d("VetoAlarms", "Scheduled future alarm for $title at $startEpoch")
                }
            }
        } catch (e: Exception) {
            Log.e("VetoAlarms", "Error scheduling reminders: ${e.message}")
        }
    }

    private fun fireImmediateReminder(context: Context, blockId: String, title: String, description: String) {
        val intent = Intent(context, VetoAlarmReceiver::class.java).apply {
            putExtra("id", blockId)
            putExtra("title", "Active Focus Session: $title")
            putExtra("description", description)
        }
        context.sendBroadcast(intent)
    }

    private fun parseDateTimeToEpoch(dateString: String, timeString: String): Long? {
        return try {
            val format = SimpleDateFormat("yyyy-MM-dd hh:mm a", Locale.US)
            val parsedDate = format.parse("$dateString $timeString")
            parsedDate?.time
        } catch (e: Exception) {
            try {
                val format = SimpleDateFormat("yyyy-MM-dd h:mm a", Locale.US)
                val parsedDate = format.parse("$dateString $timeString")
                parsedDate?.time
            } catch (e2: Exception) {
                null
            }
        }
    }

    /**
     * Helper to get the application package name.
     */
    private fun packageName(): String = applicationContext.packageName
}
