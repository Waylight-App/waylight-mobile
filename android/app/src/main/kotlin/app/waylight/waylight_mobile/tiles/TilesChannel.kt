package app.waylight.waylight_mobile.tiles

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The tiles for Flutter (`app.waylight/tiles`, #192), in the app and in
 * the headless engine of a tile's action. [onFinished] runs when the
 * action reports its end.
 */
object TilesChannel {
    private const val CHANNEL = "app.waylight/tiles"

    fun register(context: Context, messenger: BinaryMessenger, onFinished: () -> Unit = {}) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "save" -> {
                    QuickTiles.save(context, call.argument<String>("kind").orEmpty(), call.argument<String>("state").orEmpty())
                    result.success(null)
                }
                "offer" -> {
                    QuickTiles.offer(context, call.argument<String>("kind").orEmpty(), call.argument<Boolean>("offered") == true)
                    result.success(null)
                }
                "choose" -> {
                    QuickTiles.choose(context, call.argument<String>("id").orEmpty(), call.argument<String>("name").orEmpty())
                    result.success(null)
                }
                "choice" -> result.success(
                    QuickTiles.choice(context)?.let { (id, name) -> mapOf("id" to id, "name" to name) },
                )
                "clear" -> {
                    QuickTiles.clear(context)
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
