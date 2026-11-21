package app.waylight.wear.pairing

import java.io.Closeable
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException

/** A request the listener accepted: only `POST /pair` reaches the handler. */
internal sealed interface HandoverRequest {
    data class Pair(val body: String) : HandoverRequest

    /** Any other method or path. */
    data object NotFound : HandoverRequest

    /** Not HTTP, too large or cut off. */
    data object Bad : HandoverRequest
}

/**
 * Listens in the local network for the phone app's handover (ADR 0015).
 * A minimal HTTP/1.1 server: one connection at a time, one request per
 * connection, small bodies only. It stops after a request the handler
 * answers with 204, or after [MAX_REQUESTS] requests, so nobody in the
 * network can keep trying.
 */
class HandoverServer(bindAddress: InetAddress) : Closeable {
    private val socket = ServerSocket(0, BACKLOG, bindAddress)

    /** `ip:port` for the QR code. */
    val address: String = "${bindAddress.hostAddress}:${socket.localPort}"

    /**
     * Serves until [close] or the end of the handover. [handle] gets the
     * request body and returns the status for the phone: 204 when the watch
     * is paired, an error status otherwise. Blocks the calling thread.
     */
    fun serve(handle: (String) -> Int) {
        repeat(MAX_REQUESTS) {
            val client = try {
                socket.accept()
            } catch (e: SocketException) {
                return // closed
            }
            val status = client.use { answer(it, handle) }
            if (status == 204) {
                close()
                return
            }
        }
        close()
    }

    private fun answer(client: Socket, handle: (String) -> Int): Int {
        client.soTimeout = READ_TIMEOUT_MS
        val status = try {
            when (val request = readRequest(client.getInputStream())) {
                is HandoverRequest.Pair -> handle(request.body)
                HandoverRequest.NotFound -> 404
                HandoverRequest.Bad -> 400
            }
        } catch (e: IOException) {
            return 400
        }
        try {
            writeStatus(client.getOutputStream(), status)
        } catch (e: IOException) {
            // The phone gave up waiting; the outcome is visible on the watch.
        }
        return status
    }

    override fun close() {
        socket.close()
    }

    internal companion object {
        const val MAX_REQUESTS = 10
        const val MAX_HEADER_BYTES = 8 * 1024
        const val MAX_BODY_BYTES = 4 * 1024
        const val READ_TIMEOUT_MS = 10_000
        const val BACKLOG = 2

        /** Reads one request from [input]. */
        fun readRequest(input: InputStream): HandoverRequest {
            var budget = MAX_HEADER_BYTES
            fun line(): String? {
                val out = StringBuilder()
                while (true) {
                    val b = input.read()
                    if (b == -1) return null
                    if (--budget < 0) return null
                    if (b == '\n'.code) return out.toString().removeSuffix("\r")
                    out.append(b.toChar())
                }
            }
            val requestLine = line() ?: return HandoverRequest.Bad
            val parts = requestLine.split(' ')
            if (parts.size != 3 || !parts[2].startsWith("HTTP/1.")) return HandoverRequest.Bad
            var length = -1
            while (true) {
                val header = line() ?: return HandoverRequest.Bad
                if (header.isEmpty()) break
                val name = header.substringBefore(':').trim()
                if (name.equals("Content-Length", ignoreCase = true)) {
                    length = header.substringAfter(':').trim().toIntOrNull() ?: return HandoverRequest.Bad
                }
            }
            if (parts[0] != "POST" || parts[1] != "/pair") return HandoverRequest.NotFound
            if (length !in 1..MAX_BODY_BYTES) return HandoverRequest.Bad
            val body = ByteArray(length)
            var read = 0
            while (read < length) {
                val n = input.read(body, read, length - read)
                if (n == -1) return HandoverRequest.Bad
                read += n
            }
            return HandoverRequest.Pair(String(body, Charsets.UTF_8))
        }

        private fun writeStatus(output: OutputStream, status: Int) {
            val reason = when (status) {
                204 -> "No Content"
                400 -> "Bad Request"
                401 -> "Unauthorized"
                404 -> "Not Found"
                422 -> "Unprocessable Content"
                else -> "Bad Gateway"
            }
            output.write("HTTP/1.1 $status $reason\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".toByteArray(Charsets.US_ASCII))
            output.flush()
        }
    }
}
