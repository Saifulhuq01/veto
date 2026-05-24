package com.veto.veto

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

class VetoWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.veto_widget_layout)

        // Read current lockdown state from SharedPreferences (from "veto_rules" file)
        val prefs = context.getSharedPreferences("veto_rules", Context.MODE_PRIVATE)
        val isLockdownActive = prefs.getBoolean("is_lockdown_active", false)

        if (isLockdownActive) {
            views.setTextViewText(R.id.widget_status, "Lockdown Active")
            views.setTextViewText(R.id.widget_button, "Focusing...")
            views.setViewVisibility(R.id.widget_button, View.GONE) // Hide button or change text
        } else {
            views.setTextViewText(R.id.widget_status, "Lockdown Inactive")
            views.setViewVisibility(R.id.widget_button, View.VISIBLE)
            views.setTextViewText(R.id.widget_button, "Engage Lockdown")

            // Setup pending intent to trigger lockdown click by launching MainActivity
            val intent = Intent(context, MainActivity::class.java).apply {
                action = "com.veto.veto.ENGAGE_LOCKDOWN"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_button, pendingIntent)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
