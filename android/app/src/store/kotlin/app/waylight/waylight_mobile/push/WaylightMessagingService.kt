package app.waylight.waylight_mobile.push

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Base64
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import app.waylight.waylight_mobile.MainActivity
import app.waylight.waylight_mobile.R
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Receives the push messages of the Waylight relay while the app is closed
 * (ADR 0008): decrypts them with the device key and shows them, without
 * starting Flutter. Tapping opens the message's waylight:// link.
 */
class WaylightMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        val sealed = message.data["p"] ?: return
        val key = DeviceKey(this).privateKey() ?: return
        val content = PushPayload.open(key, Base64.decode(sealed, Base64.DEFAULT)) ?: return
        show(this, content)
    }

    override fun onNewToken(token: String) {
        // The app registers the new token with the server the next time it
        // starts; the token is not readable for Flutter here.
        getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean(TOKEN_CHANGED, true).apply()
    }

    companion object {
        const val PREFS = "waylight_push"
        const val TOKEN_CHANGED = "token_changed"
        private const val CHANNEL = "waylight"

        fun show(context: Context, content: PushContent) {
            val manager = NotificationManagerCompat.from(context)
            if (!manager.areNotificationsEnabled()) return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(CHANNEL, "Waylight", NotificationManager.IMPORTANCE_DEFAULT)
                context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
            }
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse(content.link ?: "waylight://")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val tap = PendingIntent.getActivity(
                context,
                content.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val notification = NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(content.title)
                .setContentText(content.body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(content.body))
                .setContentIntent(tap)
                .setAutoCancel(true)
                .build()
            try {
                manager.notify(content.hashCode(), notification)
            } catch (e: SecurityException) {
                // The permission was withdrawn in the system settings.
            }
        }
    }
}
