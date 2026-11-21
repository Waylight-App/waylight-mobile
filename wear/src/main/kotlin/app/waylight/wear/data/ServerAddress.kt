package app.waylight.wear.data

import java.net.URI
import java.net.URISyntaxException

/**
 * The base address of a Waylight server, such as
 * `https://home.example.org/waylight`: absolute, `http` or `https`, without
 * trailing slash, credentials, query or fragment. Create it with [parse].
 */
class ServerAddress private constructor(val url: String) {
    /** The host name or IP address, for display. */
    val host: String get() = URI(url).host.orEmpty()

    /** The URL of [path] on this server, e.g. `resolve("/api/todos")`. */
    fun resolve(path: String): String = url + path

    override fun equals(other: Any?): Boolean = other is ServerAddress && other.url == url

    override fun hashCode(): Int = url.hashCode()

    override fun toString(): String = url

    /** The outcome of [parse]. */
    sealed interface Parsed {
        /** A usable address. */
        data class Valid(val address: ServerAddress) : Parsed

        /** Plain `http://` to an address outside the home network (ADR 0006). */
        data object Insecure : Parsed

        /** Empty, not a URL, or with parts a server address cannot have. */
        data object Malformed : Parsed
    }

    companion object {
        /**
         * Parses what the user typed or the phone sent. The rules are those of
         * the phone app's `ServerAddress.parse`, with one difference: without
         * a scheme a private address gets `http://`, because typing the scheme
         * on a watch is tedious and home servers rarely have TLS. Every other
         * address without a scheme gets `https://`.
         */
        fun parse(input: String): Parsed {
            val text = input.trim()
            if (text.isEmpty()) return Parsed.Malformed
            val withScheme = when {
                "://" in text -> text
                hostOf("https://$text")?.let(::isPrivateHost) == true -> "http://$text"
                else -> "https://$text"
            }
            val uri = try {
                URI(withScheme)
            } catch (e: URISyntaxException) {
                return Parsed.Malformed
            }
            val scheme = uri.scheme?.lowercase()
            val host = uri.host?.lowercase()
            if (scheme != "http" && scheme != "https") return Parsed.Malformed
            if (host.isNullOrEmpty()) return Parsed.Malformed
            if (uri.rawUserInfo != null || uri.rawQuery != null || uri.rawFragment != null) {
                return Parsed.Malformed
            }
            if (scheme == "http" && !isPrivateHost(host)) return Parsed.Insecure
            val port = if (uri.port == -1) "" else ":${uri.port}"
            val path = uri.rawPath.orEmpty().trimEnd('/')
            return Parsed.Valid(ServerAddress("$scheme://$host$port$path"))
        }

        private fun hostOf(url: String): String? = try {
            URI(url).host
        } catch (e: URISyntaxException) {
            null
        }

        private val ipv4 = Regex("""^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$""")

        /**
         * Whether [host] is in the home network: loopback, RFC 1918 and
         * link-local IPv4, IPv6 unique local and link-local addresses,
         * `localhost`, `.local` and `.home.arpa` names. Only literals are
         * checked; names are never resolved here.
         */
        fun isPrivateHost(host: String): Boolean {
            val h = host.lowercase().removePrefix("[").removeSuffix("]")
            if (h == "localhost" || h.endsWith(".local") || h.endsWith(".home.arpa")) return true
            ipv4.matchEntire(h)?.let { match ->
                val octets = match.groupValues.drop(1).map { it.toInt() }
                if (octets.any { it > 255 }) return false
                val (a, b) = octets
                return a == 127 || a == 10 || (a == 172 && b in 16..31) ||
                    (a == 192 && b == 168) || (a == 169 && b == 254)
            }
            if (':' in h) {
                return h == "::1" || h.startsWith("fc") || h.startsWith("fd") ||
                    h.startsWith("fe8") || h.startsWith("fe9") || h.startsWith("fea") || h.startsWith("feb")
            }
            return false
        }
    }
}
