package com.veto.veto

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.appwidget.AppWidgetManager
import android.content.ComponentName
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

    private fun updateVetoWidget() {
        try {
            val intent = Intent(this, VetoWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            val ids = AppWidgetManager.getInstance(application)
                .getAppWidgetIds(ComponentName(application, VetoWidgetProvider::class.java))
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            sendBroadcast(intent)
            Log.d("MainActivity", "Widget update broadcast sent, ids count: ${ids.size}")
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to update widget: ${e.message}", e)
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

                            // Update widget
                            updateVetoWidget()
                            
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("LOCKDOWN_STATE_FAILED", e.message, null)
                        }
                    }

                    "getTodayUsageMinutes" -> {
                        try {
                            val total = getTotalUsageMinutesToday(this)
                            result.success(total.toInt())
                        } catch (e: Exception) {
                            result.success(179) // fallback
                        }
                    }

                    "schedulePlannerReminders" -> {
                        try {
                            schedulePlannerReminders()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SCHEDULE_FAILED", e.message, null)
                        }
                    }

                    "triggerDirectivesReload" -> {
                        try {
                            val intent = Intent(VetoAccessibilityService.ACTION_RELOAD_RULES)
                            intent.setPackage(packageName())
                            sendBroadcast(intent)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    "getInstalledApps" -> {
                        try {
                            val pm = packageManager
                            val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
                                addCategory(Intent.CATEGORY_LAUNCHER)
                            }
                            val resolveInfos = pm.queryIntentActivities(mainIntent, 0)
                            val appsList = ArrayList<Map<String, String>>()
                            for (info in resolveInfos) {
                                val appName = info.loadLabel(pm).toString()
                                val packageName = info.activityInfo.packageName
                                appsList.add(mapOf("appName" to appName, "packageName" to packageName))
                            }
                            appsList.sortBy { it["appName"]?.lowercase() }
                            result.success(appsList)
                        } catch (e: Exception) {
                            result.error("GET_APPS_FAILED", e.message, null)
                        }
                    }

                    "checkNotificationPolicyAccess" -> {
                        try {
                            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                            val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                notificationManager.isNotificationPolicyAccessGranted
                            } else {
                                true
                            }
                            result.success(granted)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    "requestNotificationPolicyAccess" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                            }
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    "setNotificationDND" -> {
                        try {
                            val enabled = call.argument<Boolean>("enabled") ?: false
                            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                if (notificationManager.isNotificationPolicyAccessGranted) {
                                    notificationManager.setInterruptionFilter(
                                        if (enabled) android.app.NotificationManager.INTERRUPTION_FILTER_NONE
                                        else android.app.NotificationManager.INTERRUPTION_FILTER_ALL
                                    )
                                    result.success(true)
                                } else {
                                    result.success(false)
                                }
                            } else {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    "checkUsageStatsPermission" -> {
                        try {
                            val granted = isUsageStatsPermissionGranted(this)
                            result.success(granted)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }

                    "requestUsageStatsPermission" -> {
                        try {
                            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
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

    private fun scheduleAlarmCompat(alarmManager: AlarmManager, triggerTime: Long, pendingIntent: PendingIntent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
            } else {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
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
                
                val prepTime = startEpoch - (30 * 60 * 1000)

                // 1. Fire immediate notifications if matching current range
                if (now in startEpoch until endEpoch) {
                    Log.d("VetoAlarms", "Schedule active now: $title. Firing immediate starting_now reminder.")
                    fireImmediateReminder(context, id, title, description, "starting_now")
                } else if (now in prepTime until startEpoch) {
                    Log.d("VetoAlarms", "Schedule starting soon: $title. Firing immediate 30_min_before reminder.")
                    fireImmediateReminder(context, id, title, description, "30_min_before")
                }
                
                // 2. Schedule future alarm 30-min-before
                if (prepTime > now) {
                    val intent30 = Intent(context, VetoAlarmReceiver::class.java).apply {
                        putExtra("id", id)
                        putExtra("title", title)
                        putExtra("description", description)
                        putExtra("type", "30_min_before")
                    }
                    val pendingIntent30 = PendingIntent.getBroadcast(
                        context,
                        (id + "_30_min_before").hashCode(),
                        intent30,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    scheduleAlarmCompat(alarmManager, prepTime, pendingIntent30)
                    Log.d("VetoAlarms", "Scheduled 30-min-before alarm for $title at $prepTime")
                }

                // 3. Schedule future alarm starting-now
                if (startEpoch > now) {
                    val intentStart = Intent(context, VetoAlarmReceiver::class.java).apply {
                        putExtra("id", id)
                        putExtra("title", title)
                        putExtra("description", description)
                        putExtra("type", "starting_now")
                    }
                    val pendingIntentStart = PendingIntent.getBroadcast(
                        context,
                        (id + "_starting_now").hashCode(),
                        intentStart,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    scheduleAlarmCompat(alarmManager, startEpoch, pendingIntentStart)
                    Log.d("VetoAlarms", "Scheduled starting-now alarm for $title at $startEpoch")
                }
            }
        } catch (e: Exception) {
            Log.e("VetoAlarms", "Error scheduling reminders: ${e.message}")
        }
    }

    private fun fireImmediateReminder(context: Context, blockId: String, title: String, description: String, type: String) {
        val intent = Intent(context, VetoAlarmReceiver::class.java).apply {
            putExtra("id", blockId)
            putExtra("title", title)
            putExtra("description", description)
            putExtra("type", type)
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

    private fun isUsageStatsPermissionGranted(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName
            )
        } else {
            appOps.checkOpNoThrow(
                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName
            )
        }
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    private fun getTotalUsageMinutesToday(context: Context): Long {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
        val calendar = java.util.Calendar.getInstance().apply {
            set(java.util.Calendar.HOUR_OF_DAY, 0)
            set(java.util.Calendar.MINUTE, 0)
            set(java.util.Calendar.SECOND, 0)
            set(java.util.Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()
        val stats = usm.queryUsageStats(android.app.usage.UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        var totalMillis = 0L
        if (stats != null) {
            for (usageStats in stats) {
                totalMillis += usageStats.totalTimeInForeground
            }
        }
        return totalMillis / (1000 * 60)
    }

    /**
     * Helper to get the application package name.
     */
    private fun packageName(): String = applicationContext.packageName
}
