package app.waylight.waylight_mobile.push

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Base64
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The push side for Flutter (`app.waylight/push`, ADR 0008): turning push
 * on returns the device ID the instance sends to and starts the stream;
 * the private keys never reach Dart.
 */
class PushChannel(private val activity: Activity) {
    private var pendingToken: MethodChannel.Result? = null

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "available" -> result.success(true)
                "token" -> token(result)
                "publicKey" -> result.success(Base64.encodeToString(DeviceKey(activity).publicKey(), Base64.NO_WRAP))
                "forget" -> forget(result)
                "batteryUnrestricted" -> result.success(batteryUnrestricted())
                "requestBatteryUnrestricted" -> {
                    requestBatteryUnrestricted()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun token(result: MethodChannel.Result) {
        // Android 13 asks for the notification permission at runtime; it is
        // only asked when the person turns notifications on.
        val needsPermission = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(activity, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        if (needsPermission) {
            pendingToken = result
            ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.POST_NOTIFICATIONS), PERMISSION_REQUEST)
        } else {
            start(result)
        }
    }

    fun onPermissionResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != PERMISSION_REQUEST) return
        val result = pendingToken ?: return
        pendingToken = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) start(result) else result.success(null)
    }

    private fun start(result: MethodChannel.Result) {
        val id = StreamKey().deviceId()
        PushSettings(activity).enabled = true
        PushService.start(activity)
        result.success(id)
    }

    private fun forget(result: MethodChannel.Result) {
        val settings = PushSettings(activity)
        settings.enabled = false
        settings.lastEventId = null
        PushService.stop(activity)
        DeviceKey(activity).forget()
        StreamKey().forget()
        result.success(null)
    }

    private fun batteryUnrestricted(): Boolean =
        activity.getSystemService(PowerManager::class.java).isIgnoringBatteryOptimizations(activity.packageName)

    // Asking the person directly is allowed for apps whose core function
    // breaks under battery optimisation, such as a push connection.
    @SuppressLint("BatteryLife")
    private fun requestBatteryUnrestricted() {
        activity.startActivity(
            Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:${activity.packageName}")),
        )
    }

    companion object {
        const val CHANNEL = "app.waylight/push"
        private const val PERMISSION_REQUEST = 4711
    }
}
