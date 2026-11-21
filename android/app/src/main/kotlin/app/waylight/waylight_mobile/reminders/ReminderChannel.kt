package app.waylight.waylight_mobile.reminders

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Reminders on the device (`app.waylight/reminders`, #190): replaces the
 * scheduled list, cancels it and asks for the notification permission.
 */
class ReminderChannel(private val activity: Activity) {
    private var pendingPermission: MethodChannel.Result? = null

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "replaceAll" -> {
                    val list = call.argument<List<Map<String, Any?>>>("reminders").orEmpty().mapNotNull(::parse)
                    Reminders.createChannels(activity)
                    Reminders.replaceAll(activity, list)
                    result.success(null)
                }
                "cancelAll" -> {
                    Reminders.cancelAll(activity)
                    result.success(null)
                }
                "canNotify" -> result.success(NotificationManagerCompat.from(activity).areNotificationsEnabled())
                "requestPermission" -> requestPermission(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val needs = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(activity, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        if (!needs) {
            result.success(NotificationManagerCompat.from(activity).areNotificationsEnabled())
            return
        }
        pendingPermission = result
        ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.POST_NOTIFICATIONS), PERMISSION_REQUEST)
    }

    fun onPermissionResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != PERMISSION_REQUEST) return
        val result = pendingPermission ?: return
        pendingPermission = null
        result.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
    }

    private fun parse(m: Map<String, Any?>): Reminder? {
        val id = (m["id"] as? Number)?.toInt() ?: return null
        val at = (m["at"] as? Number)?.toLong() ?: return null
        return Reminder(
            id = id,
            at = at,
            kind = m["kind"] as? String ?: KIND_TODO,
            title = m["title"] as? String ?: "",
            body = m["body"] as? String ?: "",
            link = m["link"] as? String ?: "waylight://",
        )
    }

    private companion object {
        const val CHANNEL = "app.waylight/reminders"
        const val PERMISSION_REQUEST = 4712
    }
}
