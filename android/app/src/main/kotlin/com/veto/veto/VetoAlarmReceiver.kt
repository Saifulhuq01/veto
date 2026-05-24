package com.veto.veto

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.util.Log

class VetoAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val CHANNEL_ID = "veto_planner_reminders"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val blockId = intent.getStringExtra("id") ?: "0"
        val title = intent.getStringExtra("title") ?: "Focus Block"
        val desc = intent.getStringExtra("description") ?: "Time to focus."
        val type = intent.getStringExtra("type") ?: "starting_now"
        
        // Unique ID based on ID + type so notifications don't overwrite each other
        val id = (blockId + "_" + type).hashCode()

        val notificationTitle = if (type == "30_min_before") {
            "Upcoming Focus Block: $title"
        } else {
            "Focus Session Starting: $title"
        }

        val notificationDesc = if (type == "30_min_before") {
            "Starts in 30 minutes. Get ready to lock down!"
        } else {
            desc
        }

        Log.d("VetoAlarmReceiver", "Alarm received type $type: $title")

        showNotification(context, id, notificationTitle, notificationDesc)
    }

    private fun showNotification(context: Context, notificationId: Int, title: String, message: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create Channel if Android O+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Veto Focus Reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Reminders for scheduled focus blocks"
                enableLights(true)
                lightColor = Color.parseColor("#10B981") // Veto signature green
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Open app on click
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action button to Engage Lockdown
        val engageIntent = Intent(context, MainActivity::class.java).apply {
            action = "com.veto.veto.ENGAGE_LOCKDOWN"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val engagePendingIntent = PendingIntent.getActivity(
            context,
            notificationId + 1,
            engageIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build notification using pure framework class
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentTitle(title)
            .setContentText(message)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            
        // Add actionable "Engage Lockdown" button
        val actionIcon = android.R.drawable.ic_media_play
        val actionTitle = "Engage Lockdown"
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH) {
            val action = Notification.Action.Builder(
                actionIcon,
                actionTitle,
                engagePendingIntent
            ).build()
            builder.addAction(action)
        } else {
            @Suppress("DEPRECATION")
            builder.addAction(actionIcon, actionTitle, engagePendingIntent)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            builder.setCategory(Notification.CATEGORY_REMINDER)
            builder.setColor(Color.parseColor("#10B981")) // Veto emerald accent
        }

        notificationManager.notify(notificationId, builder.build())
    }
}
