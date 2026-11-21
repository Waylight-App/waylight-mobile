package app.waylight.waylight_mobile.controls

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The device controls for Flutter (`app.waylight/controls`, #194), in the
 * app and in the headless engine of a background run. [onFinished] runs
 * when the run reports its end.
 */
object ControlsChannel {
    private const val CHANNEL = "app.waylight/controls"

    fun register(context: Context, messenger: BinaryMessenger, onFinished: () -> Unit = {}) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "save" -> {
                    DeviceControls.save(context, call.argument<String>("state").orEmpty())
                    result.success(null)
                }
                "clear" -> {
                    DeviceControls.clear(context)
                    result.success(null)
                }
                "finished" -> {
                    onFinished()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
