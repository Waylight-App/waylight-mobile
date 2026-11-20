package app.waylight.waylight_mobile

import android.content.Context
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The wallpaper colours (`app.waylight/colors`, #198): the system accent
 * Android 12 derives from the wallpaper, or null on older versions.
 */
object ColorsChannel {
    private const val CHANNEL = "app.waylight/colors"

    fun register(context: Context, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "accent" -> result.success(
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        context.getColor(android.R.color.system_accent1_500)
                    } else {
                        null
                    },
                )
                else -> result.notImplemented()
            }
        }
    }
}
