package app.waylight.waylight_mobile

import app.waylight.waylight_mobile.push.PushChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// local_auth shows the system's biometric prompt, which needs a
// FragmentActivity (#46).
class MainActivity : FlutterFragmentActivity() {
    // The push channel exists in both flavours (ADR 0008); only the store
    // flavour's one talks to Firebase.
    private val push = PushChannel(this)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        push.register(flutterEngine)
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
