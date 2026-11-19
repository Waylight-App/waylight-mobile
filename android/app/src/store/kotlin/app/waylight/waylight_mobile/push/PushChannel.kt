package app.waylight.waylight_mobile.push

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import android.util.Base64
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The push channel of the store build (ADR 0008): the FCM token behind the
 * notification permission, and the public half of the device key.
 */
class PushChannel(private val activity: Activity) {
    private var pendingToken: MethodChannel.Result? = null

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "available" -> result.success(FirebaseSetup.configured)
                "token" -> token(result)
                "publicKey" -> result.success(Base64.encodeToString(DeviceKey(activity).publicKey(), Base64.NO_WRAP))
                "forget" -> forget(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun token(result: MethodChannel.Result) {
        if (!FirebaseSetup.ensure(activity)) {
            result.success(null)
            return
        }
        // Android 13 asks for the notification permission at runtime; it is
        // only asked when the person turns notifications on.
        val needsPermission = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(activity, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        if (needsPermission) {
            pendingToken = result
            ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.POST_NOTIFICATIONS), PERMISSION_REQUEST)
        } else {
            fetchToken(result)
        }
    }

    fun onPermissionResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != PERMISSION_REQUEST) return
        val result = pendingToken ?: return
        pendingToken = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) fetchToken(result) else result.success(null)
    }

    private fun fetchToken(result: MethodChannel.Result) {
        FirebaseMessaging.getInstance().token
            .addOnSuccessListener { result.success(it) }
            .addOnFailureListener { result.error("token", it.message, null) }
    }

    private fun forget(result: MethodChannel.Result) {
        DeviceKey(activity).forget()
        if (FirebaseSetup.ensure(activity)) FirebaseMessaging.getInstance().deleteToken()
        result.success(null)
    }

    companion object {
        const val CHANNEL = "app.waylight/push"
        private const val PERMISSION_REQUEST = 4711
    }
}
