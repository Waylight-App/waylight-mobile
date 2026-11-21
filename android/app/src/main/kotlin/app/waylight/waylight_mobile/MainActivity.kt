package app.waylight.waylight_mobile

import android.content.Intent
import android.net.Uri
import android.nfc.NfcAdapter
import android.os.Bundle
import app.waylight.waylight_mobile.focus.FocusChannel
import app.waylight.waylight_mobile.home.HomeWidgetChannel
import app.waylight.waylight_mobile.push.PushChannel
import app.waylight.waylight_mobile.reminders.ReminderChannel
import app.waylight.waylight_mobile.tiles.TilesChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// local_auth shows the system's biometric prompt, which needs a
// FragmentActivity (#46).
class MainActivity : FlutterFragmentActivity() {
    // The push channel exists in both flavours (ADR 0008); only the store
    // flavour's one talks to Firebase.
    private val push = PushChannel(this)
    private val reminders = ReminderChannel(this)
    private val scan = ScanChannel(this)
    private val nfc = NfcChannel(this)

    override fun onCreate(savedInstanceState: Bundle?) {
        intent = asShareLink(asTagLink(intent))
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(asShareLink(asTagLink(intent)))
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        push.register(flutterEngine)
        reminders.register(flutterEngine)
        scan.register(flutterEngine)
        nfc.register(flutterEngine)
        TilesChannel.register(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        FocusChannel.register(applicationContext, flutterEngine)
        NetworkChannel.register(applicationContext, flutterEngine)
        DeviceChannel(this).register(flutterEngine)
        ColorsChannel.register(applicationContext, flutterEngine)
        HomeWidgetChannel.register(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        push.onPermissionResult(requestCode, grantResults)
        reminders.onPermissionResult(requestCode, grantResults)
    }
}

/**
 * Turns text shared from another app (#21) into the deep link
 * waylight://share?text=…, which the router handles like every other link,
 * signed out included. Other intents pass unchanged.
 */
/**
 * A Waylight NFC tag (#195) as the link it carries, so the router opens it
 * like any other `waylight://` link. Other intents stay as they are.
 */
internal fun asTagLink(intent: Intent): Intent {
    val data = intent.data
    if (intent.action != NfcAdapter.ACTION_NDEF_DISCOVERED || data?.scheme != "waylight") return intent
    return Intent(Intent.ACTION_VIEW, data)
}

internal fun asShareLink(intent: Intent): Intent {
    if (intent.action != Intent.ACTION_SEND || intent.type != "text/plain") return intent
    val text = listOfNotNull(
        intent.getStringExtra(Intent.EXTRA_SUBJECT),
        intent.getStringExtra(Intent.EXTRA_TEXT),
    ).filter { it.isNotBlank() }.distinct().joinToString("\n")
    if (text.isBlank()) return intent
    val link = Uri.Builder().scheme("waylight").authority("share").appendQueryParameter("text", text).build()
    return Intent(Intent.ACTION_VIEW, link)
}
