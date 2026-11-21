package app.waylight.wear.data

/** The watch's own app session on [server] (server #559). */
class Session(val server: ServerAddress, val token: String) {
    // The token must never end up in a log line.
    override fun toString(): String = "Session(server=$server)"
}
