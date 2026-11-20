package app.waylight.waylight_mobile.push

/** One Server-Sent Event with data; comments and retry hints are not events. */
data class SseEvent(val id: String?, val data: String)

/**
 * An incremental parser for text/event-stream (WHATWG HTML, "Server-sent
 * events"): it is fed one line at a time and returns an event when a blank
 * line completes one. Only the fields the relay sends are kept.
 */
class SseParser {
    private var id: String? = null
    private val data = StringBuilder()

    /** The last event ID seen, to resume with Last-Event-ID. */
    var lastId: String? = null
        private set

    /** Feeds one line without its line break; returns a completed event. */
    fun feed(line: String): SseEvent? {
        if (line.isEmpty()) return dispatch()
        if (line.startsWith(":")) return null
        val colon = line.indexOf(':')
        val field = if (colon < 0) line else line.substring(0, colon)
        var value = if (colon < 0) "" else line.substring(colon + 1)
        if (value.startsWith(" ")) value = value.substring(1)
        when (field) {
            "id" -> if (!value.contains('\u0000')) id = value
            "data" -> {
                if (data.isNotEmpty()) data.append('\n')
                data.append(value)
            }
        }
        return null
    }

    private fun dispatch(): SseEvent? {
        id?.let { lastId = it }
        if (data.isEmpty()) {
            id = null
            return null
        }
        val event = SseEvent(id, data.toString())
        id = null
        data.setLength(0)
        return event
    }
}
