package app.waylight.waylight_mobile

import android.app.Activity
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The device (`app.waylight/device`): system version and model and the
 * share sheet for diagnostic reports (#197), and keeping the screen on for
 * the wall display (#193).
 */
class DeviceChannel(private val activity: Activity) {
    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "describe" -> result.success(
                    "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT}), ${Build.MANUFACTURER} ${Build.MODEL}",
                )
                "share" -> {
                    val text = call.argument<String>("text").orEmpty()
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_SUBJECT, call.argument<String>("subject"))
                        putExtra(Intent.EXTRA_TEXT, text)
                    }
                    activity.startActivity(Intent.createChooser(send, null))
                    result.success(null)
                }
                // The wall display keeps the screen on (#193).
                "keepScreenOn" -> {
                    val flag = android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    if (call.argument<Boolean>("on") == true) activity.window.addFlags(flag) else activity.window.clearFlags(flag)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private companion object {
        const val CHANNEL = "app.waylight/device"
    }
}
