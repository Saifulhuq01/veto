package com.veto.veto

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import android.util.Log
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import org.json.JSONArray

class VetoWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.veto_widget_layout)

        // 1. Read current lockdown state from SharedPreferences (from "veto_rules" file)
        val prefs = context.getSharedPreferences("veto_rules", Context.MODE_PRIVATE)
        val isLockdownActive = prefs.getBoolean("is_lockdown_active", false)

        // 2. Read lockdown end time from FlutterSharedPreferences
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val endEpoch = flutterPrefs.getLong("flutter.lockdown_end_time", 0L)

        // 3. Set up click pending intent on the main container to launch MainActivity (opens App)
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId + 100,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)

        // 4. Update status indicator & action button
        if (isLockdownActive) {
            views.setImageViewResource(R.id.widget_status_dot, R.drawable.widget_status_active_dot)
            views.setTextViewText(R.id.widget_status_text, "Active")
            
            // Format end time if available and in the future
            val endText = if (endEpoch > System.currentTimeMillis()) {
                try {
                    val sdf = SimpleDateFormat("h:mm a", Locale.getDefault())
                    "Focusing (Ends " + sdf.format(Date(endEpoch)) + ")"
                } catch (e: Exception) {
                    "Lockdown Active"
                }
            } else {
                "Lockdown Active"
            }
            views.setTextViewText(R.id.widget_button, endText)
            views.setInt(R.id.widget_button, "setBackgroundResource", R.drawable.widget_button_active_background)
            views.setTextColor(R.id.widget_button, android.graphics.Color.parseColor("#4EDEA3"))
            
            // Clicking button also opens dashboard when active
            views.setOnClickPendingIntent(R.id.widget_button, openAppPendingIntent)
        } else {
            views.setImageViewResource(R.id.widget_status_dot, R.drawable.widget_status_inactive_dot)
            views.setTextViewText(R.id.widget_status_text, "Inactive")
            
            views.setTextViewText(R.id.widget_button, "Engage Lockdown")
            views.setInt(R.id.widget_button, "setBackgroundResource", R.drawable.widget_button_background)
            views.setTextColor(R.id.widget_button, android.graphics.Color.parseColor("#05050A"))

            // Setup pending intent to trigger lockdown click by launching MainActivity
            val engageIntent = Intent(context, MainActivity::class.java).apply {
                action = "com.veto.veto.ENGAGE_LOCKDOWN"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                engageIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_button, pendingIntent)
        }

        // 5. Update Screen Time Today
        val screenTime = getScreenTimeToday(context)
        views.setTextViewText(R.id.widget_stat_screen_time, screenTime)

        // 6. Update Active Rules Count
        val activeRules = getActiveRulesCount(context)
        val rulesText = if (activeRules > 0) "$activeRules Active" else "None"
        views.setTextViewText(R.id.widget_stat_rules_count, rulesText)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun getScreenTimeToday(context: Context): String {
        try {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    context.packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    context.packageName
                )
            }
            if (mode != android.app.AppOpsManager.MODE_ALLOWED) {
                return "--"
            }

            val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
            val calendar = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
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
            val totalMinutes = totalMillis / (1000 * 60)
            val hours = totalMinutes / 60
            val mins = totalMinutes % 60
            return if (hours > 0) {
                "${hours}h ${mins}m"
            } else {
                "${mins}m"
            }
        } catch (e: Exception) {
            return "--"
        }
    }

    private fun getActiveRulesCount(context: Context): Int {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean("flutter.system_directives_enabled", true)
        if (!enabled) return 0
        
        var count = 0
        // App limits
        val limitsJson = prefs.getString("flutter.veto_app_limits", null)
        if (limitsJson != null) {
            try {
                val arr = JSONArray(limitsJson)
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    if (obj.optBoolean("isActive", true)) {
                        count++
                    }
                }
            } catch (e: Exception) {
                // ignore
            }
        }
        // Blocked Websites
        val websitesJson = prefs.getString("flutter.blocked_websites", null)
        if (websitesJson != null) {
            try {
                val arr = JSONArray(websitesJson)
                count += arr.length()
            } catch (e: Exception) {
                // ignore
            }
        }
        return count
    }
}
