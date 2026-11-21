package app.waylight.waylight_mobile.reminders

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import app.waylight.waylight_mobile.MainActivity
import app.waylight.waylight_mobile.R

/** Shows a reminder when its alarm fires (#190); tapping opens its link. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_ID, -1)
        val reminder = Reminders.find(context, id) ?: return
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return
        Reminders.createChannels(context)
        val open = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse(reminder.link)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val notification = NotificationCompat.Builder(context, Reminders.channelOf(reminder.kind))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(reminder.title)
            .setContentText(reminder.body)
            .setContentIntent(
                PendingIntent.getActivity(context, id, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE),
            )
            .setAutoCancel(true)
            .build()
        try {
            manager.notify(TAG, id, notification)
        } catch (e: SecurityException) {
            // The permission was withdrawn in the system settings.
        }
    }

    companion object {
        const val EXTRA_ID = "reminder_id"

        /** The notification tag; the same item keeps one notification. */
        const val TAG = "waylight_reminder"
    }
}
