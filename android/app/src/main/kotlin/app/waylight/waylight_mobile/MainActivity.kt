package app.waylight.waylight_mobile

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import app.waylight.waylight_mobile.home.HomeWidgetChannel
import app.waylight.waylight_mobile.push.PushChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// local_auth shows the system's biometric prompt, which needs a
// FragmentActivity (#46).
class MainActivity : FlutterFragmentActivity() {
    // The push channel exists in both flavours (ADR 0008); only the store
    // flavour's one talks to Firebase.
    private val push = PushChannel(this)

    override fun onCreate(savedInstanceState: Bundle?) {
        intent = asShareLink(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(asShareLink(intent))
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        push.register(flutterEngine)
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
    }
}

/**
 * Turns text shared from another app (#21) into the deep link
 * waylight://share?text=…, which the router handles like every other link,
 * signed out included. Other intents pass unchanged.
 */
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
