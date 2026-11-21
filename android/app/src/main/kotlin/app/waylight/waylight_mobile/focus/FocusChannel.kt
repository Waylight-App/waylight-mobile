package app.waylight.waylight_mobile.focus

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** The focus timer for Flutter (`app.waylight/focus`, #191). */
object FocusChannel {
    private const val CHANNEL = "app.waylight/focus"

    fun register(context: Context, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "state" -> result.success(FocusTimer.state(context)?.toJson()?.toString())
                "start" -> {
                    val phase = call.argument<String>("phase") ?: FocusTimer.FOCUS
                    val length = (call.argument<Number>("lengthMs"))?.toLong() ?: FocusTimer.lengthOf(phase)
                    FocusTimer.start(context, phase, length)
                    result.success(null)
                }
                "pause" -> { FocusTimer.pause(context); result.success(null) }
                "resume" -> { FocusTimer.resume(context); result.success(null) }
                "stop" -> { FocusTimer.stop(context); result.success(null) }
                "takeFinished" -> result.success(FocusTimer.takeFinished(context).toString())
                else -> result.notImplemented()
            }
        }
    }
}
