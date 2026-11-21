package app.waylight.waylight_mobile

import androidx.activity.result.ActivityResultLauncher
import androidx.fragment.app.FragmentActivity
import com.journeyapps.barcodescanner.ScanContract
import com.journeyapps.barcodescanner.ScanOptions
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Reads a barcode or QR code with the camera (`app.waylight/scan`, #196).
 * ZXing recognises it on the device (ADR 0014); the library's screen asks
 * for the camera permission when it opens. No image is kept.
 */
class ScanChannel(activity: FragmentActivity) {
    private var pending: MethodChannel.Result? = null

    // Registered while the activity is created, as the result API requires.
    private val launcher: ActivityResultLauncher<ScanOptions> =
        activity.registerForActivityResult(ScanContract()) { result ->
            pending?.success(result.contents)
            pending = null
        }

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scan" -> {
                    // One scan at a time; an earlier one ends without a value.
                    pending?.success(null)
                    pending = result
                    val options = ScanOptions()
                        .setDesiredBarcodeFormats(FORMATS)
                        .setPrompt(call.argument<String>("prompt") ?: "")
                        .setBeepEnabled(false)
                        .setOrientationLocked(false)
                    launcher.launch(options)
                }
                else -> result.notImplemented()
            }
        }
    }

    private companion object {
        const val CHANNEL = "app.waylight/scan"

        // Shipping labels use Code 128 (sometimes Code 39, Interleaved 2 of 5
        // or Data Matrix); pairing and carrier links use QR codes.
        val FORMATS = listOf(
            ScanOptions.CODE_128,
            ScanOptions.CODE_39,
            ScanOptions.ITF,
            ScanOptions.DATA_MATRIX,
            ScanOptions.QR_CODE,
        )
    }
}
