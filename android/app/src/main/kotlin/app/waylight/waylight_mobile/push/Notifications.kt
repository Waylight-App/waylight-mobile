package app.waylight.waylight_mobile.push

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import app.waylight.waylight_mobile.MainActivity
import app.waylight.waylight_mobile.R

/** The notification channels of push and the notifications shown on them. */
object Notifications {
    private const val MESSAGES = "waylight"
    private const val CONNECTION = "waylight_connection"

    /** ID of the permanent notification of the push service. */
    const val CONNECTION_ID = 1

    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel(MESSAGES, "Waylight", NotificationManager.IMPORTANCE_DEFAULT))
        // The permanent notification is required for the foreground service;
        // its channel is silent and can be hidden in the system settings.
        manager.createNotificationChannel(
            NotificationChannel(CONNECTION, context.getString(R.string.push_connection_channel), NotificationManager.IMPORTANCE_MIN),
        )
    }

    /** The permanent notification while the stream is held. */
    fun connection(context: Context): Notification =
        NotificationCompat.Builder(context, CONNECTION)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(context.getString(R.string.push_connection_title))
            .setContentText(context.getString(R.string.push_connection_text))
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setContentIntent(open(context, "waylight://settings", CONNECTION_ID))
            .build()

    /** Shows a decrypted message; tapping it opens its waylight:// link. */
    fun show(context: Context, content: PushContent) {
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return
        val notification = NotificationCompat.Builder(context, MESSAGES)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(content.title)
            .setContentText(content.body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(content.body))
            .setContentIntent(open(context, content.link ?: "waylight://", content.hashCode()))
            .setAutoCancel(true)
            .build()
        try {
            manager.notify(content.hashCode(), notification)
        } catch (e: SecurityException) {
            // The permission was withdrawn in the system settings.
        }
    }

    private fun open(context: Context, link: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse(link)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
}
