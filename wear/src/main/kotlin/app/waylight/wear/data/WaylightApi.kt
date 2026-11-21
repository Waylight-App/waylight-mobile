package app.waylight.wear.data

import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONException
import org.json.JSONObject

/** The server answered with an HTTP error [status]. */
class ApiException(val status: Int) : IOException("HTTP $status")

/**
 * A thin client for the Waylight API on [server]. Calls block; run them on
 * a background thread. With a [token], requests carry it as bearer token;
 * the server does not ask app sessions for a CSRF token.
 */
class WaylightApi(private val server: ServerAddress, private val token: String? = null) {
    /** An HTTP answer. */
    class Response(val status: Int, val body: String)

    /** `GET` of [path]; throws [ApiException] for an error status. */
    fun get(path: String): String {
        val res = request("GET", path, null)
        if (res.status !in 200..299) throw ApiException(res.status)
        return res.body
    }

    /**
     * Redeems a pairing [code] for an app session of [device]
     * (`POST /api/auth/app-sessions`) and returns its bearer token.
     */
    fun redeemPairingCode(device: String, code: String): String {
        val body = JSONObject().put("device", device).put("pairingCode", code).toString()
        val res = request("POST", "/api/auth/app-sessions", body)
        if (res.status !in 200..299) throw ApiException(res.status)
        val token = try {
            JSONObject(res.body).optString("token")
        } catch (e: JSONException) {
            ""
        }
        if (token.isEmpty()) throw ApiException(res.status)
        return token
    }

    /**
     * Sends [method] to [path] with an optional JSON [body]; throws
     * [ApiException] for an error status.
     */
    fun send(method: String, path: String, body: String?) {
        val res = request(method, path, body)
        if (res.status !in 200..299) throw ApiException(res.status)
    }

    /** Ends the session the token belongs to (`POST /api/auth/logout`). */
    fun logout() {
        request("POST", "/api/auth/logout", null)
    }

    private fun request(method: String, path: String, body: String?): Response {
        val conn = URL(server.resolve(path)).openConnection() as HttpURLConnection
        try {
            conn.requestMethod = method
            conn.connectTimeout = CONNECT_TIMEOUT_MS
            conn.readTimeout = READ_TIMEOUT_MS
            // A redirect could carry the bearer token to another host.
            conn.instanceFollowRedirects = false
            conn.setRequestProperty("Accept", "application/json")
            token?.let { conn.setRequestProperty("Authorization", "Bearer $it") }
            if (body != null) {
                conn.doOutput = true
                conn.setRequestProperty("Content-Type", "application/json")
                conn.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
            }
            val status = conn.responseCode
            val stream = if (status >= 400) conn.errorStream else conn.inputStream
            val text = stream?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }.orEmpty()
            return Response(status, text)
        } finally {
            conn.disconnect()
        }
    }

    private companion object {
        const val CONNECT_TIMEOUT_MS = 10_000
        const val READ_TIMEOUT_MS = 15_000
    }
}
