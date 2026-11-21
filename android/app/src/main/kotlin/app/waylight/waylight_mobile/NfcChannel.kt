package app.waylight.waylight_mobile

import android.app.Activity
import android.nfc.FormatException
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.TagLostException
import android.nfc.tech.Ndef
import android.nfc.tech.NdefFormatable
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

/**
 * Writes a Waylight link onto an NFC tag (`app.waylight/nfc`, #195). NFC
 * is used only while the write sheet is open, through reader mode; tags
 * are read by the system's tag dispatch, which opens the link in the app.
 */
class NfcChannel(private val activity: Activity) {
    private val main = Handler(Looper.getMainLooper())
    private var pending: MethodChannel.Result? = null

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "state" -> result.success(
                    when {
                        adapter() == null -> "missing"
                        adapter()?.isEnabled != true -> "off"
                        else -> "ready"
                    },
                )
                "write" -> write(call.argument<String>("link").orEmpty(), result)
                "cancel" -> {
                    stop("cancelled")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun write(link: String, result: MethodChannel.Result) {
        val adapter = adapter()
        if (adapter == null || !adapter.isEnabled || link.isEmpty()) {
            result.success("unavailable")
            return
        }
        // One write at a time; an earlier one ends as cancelled.
        stop("cancelled")
        pending = result
        val message = NdefMessage(arrayOf(NdefRecord.createUri(link)))
        val flags = NfcAdapter.FLAG_READER_NFC_A or NfcAdapter.FLAG_READER_NFC_B or
            NfcAdapter.FLAG_READER_NFC_F or NfcAdapter.FLAG_READER_NFC_V or
            NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK or NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS
        adapter.enableReaderMode(activity, { tag -> finish(writeTo(tag, message)) }, flags, null)
    }

    /** Writes [message]; runs on the reader mode's binder thread. */
    private fun writeTo(tag: Tag, message: NdefMessage): String {
        val size = message.toByteArray().size
        Ndef.get(tag)?.let { ndef ->
            return try {
                ndef.connect()
                when {
                    !ndef.isWritable -> "locked"
                    ndef.maxSize < size -> "tooSmall"
                    else -> {
                        ndef.writeNdefMessage(message)
                        "written"
                    }
                }
            } catch (e: TagLostException) {
                "lost"
            } catch (e: IOException) {
                "failed"
            } catch (e: FormatException) {
                "failed"
            } finally {
                runCatching { ndef.close() }
            }
        }
        NdefFormatable.get(tag)?.let { blank ->
            return try {
                blank.connect()
                blank.format(message)
                "written"
            } catch (e: TagLostException) {
                "lost"
            } catch (e: IOException) {
                "failed"
            } catch (e: FormatException) {
                "failed"
            } finally {
                runCatching { blank.close() }
            }
        }
        return "unsupported"
    }

    private fun finish(outcome: String) = main.post { stop(outcome) }

    private fun stop(outcome: String) {
        val result = pending ?: return
        pending = null
        runCatching { adapter()?.disableReaderMode(activity) }
        result.success(outcome)
    }

    private fun adapter(): NfcAdapter? = NfcAdapter.getDefaultAdapter(activity)

    private companion object {
        const val CHANNEL = "app.waylight/nfc"
    }
}
