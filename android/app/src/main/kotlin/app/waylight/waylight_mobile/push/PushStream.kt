package app.waylight.waylight_mobile.push

import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL

/**
 * Holds the Server-Sent Events stream of the relay (server ADR 0027): it
 * connects, hands every event to [onEvent], and reconnects with backoff
 * until [stop]. Runs on its own thread; [wake] cuts a pending wait short,
 * e.g. when the network comes back.
 */
class PushStream(
    private val url: URL,
    private val key: StreamKey,
    private val settings: PushSettings,
    private val onEvent: (SseEvent) -> Unit,
    private val nowSeconds: () -> Long = { System.currentTimeMillis() / 1000 },
) : Runnable {
    @Volatile private var running = true
    @Volatile private var connection: HttpURLConnection? = null
    private val backoff = Backoff()
    private val lock = Object()

    override fun run() {
        while (running) {
            val wait = try {
                connectOnce()
            } catch (e: IOException) {
                backoff.next()
            }
            if (running) pause(wait)
        }
    }

    /** Ends the stream and the loop. */
    fun stop() {
        running = false
        connection?.disconnect()
        wake()
    }

    /** Ends a pending wait so the next attempt starts now. */
    fun wake() {
        synchronized(lock) { lock.notifyAll() }
    }

    /** Reads one connection to its end and returns the wait before the next. */
    private fun connectOnce(): Long {
        val conn = (url.openConnection() as HttpURLConnection).apply {
            connectTimeout = CONNECT_TIMEOUT_MS
            // The relay sends a heartbeat every 25 seconds; silence beyond
            // this means the connection is dead.
            readTimeout = READ_TIMEOUT_MS
            setRequestProperty("Accept", "text/event-stream")
            setRequestProperty("Authorization", key.authorization(nowSeconds()))
            settings.lastEventId?.let { setRequestProperty("Last-Event-ID", it) }
        }
        connection = conn
        try {
            when (conn.responseCode) {
                HttpURLConnection.HTTP_OK -> Unit
                HTTP_TOO_MANY_REQUESTS -> return (conn.getHeaderField("Retry-After")?.toLongOrNull() ?: 60) * 1000
                else -> return backoff.next()
            }
            backoff.reset()
            val parser = SseParser()
            conn.inputStream.bufferedReader().useLines { lines ->
                for (line in lines) {
                    if (!running) break
                    val event = parser.feed(line) ?: continue
                    onEvent(event)
                    // Saved after the event is shown, so a crash in between
                    // means the event comes again rather than never.
                    event.id?.let { settings.lastEventId = it }
                }
            }
            return backoff.next()
        } finally {
            conn.disconnect()
            connection = null
        }
    }

    private fun pause(millis: Long) {
        synchronized(lock) { lock.wait(millis) }
    }

    private companion object {
        const val CONNECT_TIMEOUT_MS = 15_000
        const val READ_TIMEOUT_MS = 70_000
        const val HTTP_TOO_MANY_REQUESTS = 429
    }
}
