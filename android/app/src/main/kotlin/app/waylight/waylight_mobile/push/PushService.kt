package app.waylight.waylight_mobile.push

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.Network
import android.os.Build
import android.os.IBinder
import android.util.Base64
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import java.net.URL

/**
 * Keeps the relay's stream open while push is on (server ADR 0027). Android
 * only lets an app hold a connection in the background from a foreground
 * service, which shows a permanent notification.
 */
class PushService : Service() {
    private var stream: PushStream? = null
    private var thread: Thread? = null
    private val network = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            stream?.wake()
        }
    }

    override fun onCreate() {
        super.onCreate()
        Notifications.createChannels(this)
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_REMOTE_MESSAGING
        } else {
            0
        }
        ServiceCompat.startForeground(this, Notifications.CONNECTION_ID, Notifications.connection(this), type)
        getSystemService(ConnectivityManager::class.java).registerDefaultNetworkCallback(network)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!PushSettings(this).enabled) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (thread?.isAlive != true) {
            val s = PushStream(URL(RELAY_STREAM), StreamKey(), PushSettings(this), ::handle)
            stream = s
            thread = Thread(s, "waylight-push").apply { start() }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        getSystemService(ConnectivityManager::class.java).unregisterNetworkCallback(network)
        stream?.stop()
        stream = null
        thread = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun handle(event: SseEvent) {
        val key = DeviceKey(this).privateKey() ?: return
        val sealed = try {
            Base64.decode(event.data, Base64.DEFAULT)
        } catch (e: IllegalArgumentException) {
            return
        }
        // A payload that does not open was not sealed for this device and
        // is dropped.
        PushPayload.open(key, sealed)?.let { Notifications.show(this, it) }
    }

    companion object {
        /** The stream of the project's relay; instances send through the same relay. */
        const val RELAY_STREAM = "https://push.getwaylight.app/v1/stream"

        fun start(context: Context) {
            ContextCompat.startForegroundService(context, Intent(context, PushService::class.java))
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, PushService::class.java))
        }
    }
}
