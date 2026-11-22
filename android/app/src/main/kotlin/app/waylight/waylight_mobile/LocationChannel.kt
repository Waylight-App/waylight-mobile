package app.waylight.waylight_mobile

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Reads the approximate position of the phone (`app.waylight/location`,
 * #295) from the platform's LocationManager. It asks for the coarse
 * permission only when Dart calls it, which happens on a tap, and uses no
 * Google service.
 */
class LocationChannel(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "coarse" -> coarse(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun coarse(result: MethodChannel.Result) {
        if (granted()) {
            read(result)
            return
        }
        // One request at a time; an earlier one ends as denied.
        pending?.success(DENIED)
        pending = result
        ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION), PERMISSION_REQUEST)
    }

    fun onPermissionResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != PERMISSION_REQUEST) return
        val result = pending ?: return
        pending = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) read(result) else result.success(DENIED)
    }

    private fun granted() =
        ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    private fun read(result: MethodChannel.Result) {
        val manager = activity.getSystemService(LocationManager::class.java)
        if (manager == null) {
            result.success(UNAVAILABLE)
            return
        }
        try {
            val last = listOf(LocationManager.NETWORK_PROVIDER, LocationManager.PASSIVE_PROVIDER)
                .firstNotNullOfOrNull { manager.getLastKnownLocation(it) }
            when {
                last != null -> result.success(found(last))
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) ->
                    manager.getCurrentLocation(LocationManager.NETWORK_PROVIDER, null, ContextCompat.getMainExecutor(activity)) {
                        result.success(if (it != null) found(it) else UNAVAILABLE)
                    }
                else -> result.success(UNAVAILABLE)
            }
        } catch (e: SecurityException) {
            result.success(DENIED)
        }
    }

    private fun found(location: Location) =
        mapOf("status" to "ok", "lat" to location.latitude, "lon" to location.longitude)

    private companion object {
        const val CHANNEL = "app.waylight/location"
        const val PERMISSION_REQUEST = 4713
        val DENIED = mapOf("status" to "denied")
        val UNAVAILABLE = mapOf("status" to "unavailable")
    }
}
