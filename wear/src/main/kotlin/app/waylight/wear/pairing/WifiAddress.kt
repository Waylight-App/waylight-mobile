package app.waylight.wear.pairing

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import java.net.Inet4Address
import java.net.InetAddress
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.distinctUntilChanged

/**
 * The watch's IPv4 address in the Wi-Fi, or `null` while there is none.
 * Collecting asks the system to turn Wi-Fi on: a watch near its phone
 * usually stays on Bluetooth, where the phone app cannot reach it.
 */
fun wifiAddress(context: Context): Flow<InetAddress?> = callbackFlow {
    val connectivity = context.getSystemService(ConnectivityManager::class.java)
    val callback = object : ConnectivityManager.NetworkCallback() {
        override fun onLinkPropertiesChanged(network: Network, linkProperties: LinkProperties) {
            trySend(
                linkProperties.linkAddresses
                    .map { it.address }
                    .firstOrNull { it is Inet4Address && !it.isLoopbackAddress },
            )
        }

        override fun onLost(network: Network) {
            trySend(null)
        }

        override fun onUnavailable() {
            trySend(null)
        }
    }
    trySend(null)
    connectivity.requestNetwork(
        NetworkRequest.Builder().addTransportType(NetworkCapabilities.TRANSPORT_WIFI).build(),
        callback,
    )
    awaitClose { connectivity.unregisterNetworkCallback(callback) }
}.distinctUntilChanged()
