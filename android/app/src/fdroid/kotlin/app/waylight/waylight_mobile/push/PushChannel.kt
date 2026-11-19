package app.waylight.waylight_mobile.push

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The push channel of the F-Droid build: it has no push service, so it
 * reports push notifications as unavailable (ADR 0008).
 */
class PushChannel(@Suppress("UNUSED_PARAMETER") activity: Activity) {
    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "available" -> result.success(false)
                else -> result.error("unavailable", "This build has no push notifications.", null)
            }
        }
    }

    fun onPermissionResult(@Suppress("UNUSED_PARAMETER") requestCode: Int, @Suppress("UNUSED_PARAMETER") grantResults: IntArray) =
        Unit

    companion object {
        const val CHANNEL = "app.waylight/push"
    }
}
