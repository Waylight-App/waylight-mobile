package app.waylight.waylight_mobile

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

/**
 * Network changes for the choice of a server address (`app.waylight/network`,
 * #189): an event whenever the default network appears, goes away or
 * changes its transport. No network name is read, so no location
 * permission is needed.
 */
object NetworkChannel {
    private const val CHANNEL = "app.waylight/network"

    fun register(context: Context, engine: FlutterEngine) {
        val connectivity = context.getSystemService(ConnectivityManager::class.java) ?: return
        val main = Handler(Looper.getMainLooper())
        EventChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var callback: ConnectivityManager.NetworkCallback? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    val notify = { main.post { events.success(null) } }
                    callback = object : ConnectivityManager.NetworkCallback() {
                        private var wifi: Boolean? = null

                        override fun onAvailable(network: Network) {
                            notify()
                        }

                        override fun onLost(network: Network) {
                            notify()
                        }

                        override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
                            // Capabilities change often (signal strength); only a
                            // change between Wi-Fi and other transports counts.
                            val isWifi = caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
                            if (wifi != null && wifi != isWifi) notify()
                            wifi = isWifi
                        }
                    }.also { connectivity.registerDefaultNetworkCallback(it) }
                }

                override fun onCancel(arguments: Any?) {
                    callback?.let { connectivity.unregisterNetworkCallback(it) }
                    callback = null
                }
            },
        )
    }
}
