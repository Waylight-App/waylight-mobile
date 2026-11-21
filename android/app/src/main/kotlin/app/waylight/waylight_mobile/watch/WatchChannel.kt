package app.waylight.waylight_mobile.watch

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Encryption for pairing a watch (`app.waylight/watch`, #239). Dart builds
 * the message and sends it; only the sealing happens here, because the
 * platform's AES-GCM needs no extra Dart package.
 */
object WatchChannel {
    private const val CHANNEL = "app.waylight/watch"

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "seal" -> {
                    val key = call.argument<ByteArray>("key")
                    val plaintext = call.argument<ByteArray>("plaintext")
                    if (key == null || plaintext == null || key.size != WatchHandover.KEY_BYTES) {
                        result.error("invalid", "key or plaintext missing", null)
                    } else {
                        result.success(WatchHandover.seal(key, plaintext))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
