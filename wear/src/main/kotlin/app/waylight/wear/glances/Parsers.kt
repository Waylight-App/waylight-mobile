package app.waylight.wear.glances

import java.time.Instant
import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.format.DateTimeParseException
import org.json.JSONArray
import org.json.JSONObject

/** Maps the server's answers to glances; every function is pure and tested. */
object Parsers {
    /** The enabled modules of `GET /api/modules`. */
    fun modules(json: String): Set<String> {
        val array = JSONObject(json).optJSONArray("modules") ?: return emptySet()
        return (0 until array.length()).map { array.optString(it) }.toSet()
    }

    /**
     * The modules with a compact state in `GET /api/modules` (server #634),
     * in the server's order; `null` when the server does not send the list
     * yet. Entries whose path is not a module's compact endpoint are left
     * out, so the server cannot point the watch elsewhere.
     */
    fun compactEndpoints(json: String): List<CompactEndpoint>? {
        val array = JSONObject(json).optJSONArray("compact") ?: return null
        return (0 until array.length()).mapNotNull { i ->
            val o = array.optJSONObject(i) ?: return@mapNotNull null
            val module = o.optString("module")
            val path = o.optString("path")
            if (module.isEmpty() || !COMPACT_PATH.matches(path)) return@mapNotNull null
            val params = o.optJSONArray("params")?.let { p -> (0 until p.length()).map { p.optString(it) } }.orEmpty()
            CompactEndpoint(module, path, params)
        }
    }

    private val COMPACT_PATH = Regex("^/api/[A-Za-z0-9_-]+/compact$")

    /** A `CompactState` of [module]. */
    fun compact(module: String, json: String): CompactGlance {
        val o = JSONObject(json)
        return CompactGlance(
            module = module,
            title = GlanceText.fromJson(o.optJSONObject("title")) ?: GlanceText(""),
            detail = GlanceText.fromJson(o.optJSONObject("detail"))?.takeIf { it.text.isNotEmpty() },
            level = Level.parse(o.optString("level")),
            count = if (o.has("count") && !o.isNull("count")) o.optInt("count") else null,
            action = GlanceAction.fromJson(o.optJSONObject("action")),
            empty = o.optBoolean("empty"),
        )
    }

    /** The number of open to-dos in `GET /api/todos`, for servers without the compact state. */
    fun openTodos(json: String): Int {
        val array = JSONArray(json)
        return (0 until array.length()).count { array.optJSONObject(it)?.optBoolean("done") == false }
    }

    /** The first open to-do in `GET /api/todos`, in the server's order. */
    fun firstOpenTodo(json: String): OpenTodo? {
        val array = JSONArray(json)
        for (i in 0 until array.length()) {
            val t = array.optJSONObject(i) ?: continue
            val id = t.optString("id")
            if (t.optBoolean("done") || id.isEmpty()) continue
            return OpenTodo(id, t.optString("title"), t.optString("due"), t.optInt("version"))
        }
        return null
    }

    /**
     * The smart home entities of `GET /api/smarthome/entities` that the
     * server lets this account switch or press, at most [limit].
     */
    fun devices(json: String, limit: Int = MAX_DEVICES): List<Device> {
        val array = JSONArray(json)
        return (0 until array.length()).asSequence().mapNotNull { i ->
            val e = array.optJSONObject(i) ?: return@mapNotNull null
            val action = when (e.optString("action")) {
                "toggle" -> DeviceAction.TOGGLE
                "press" -> DeviceAction.PRESS
                else -> return@mapNotNull null
            }
            Device(e.optString("id"), e.optString("name").ifEmpty { e.optString("id") }, e.optString("state"), action)
        }.filter { it.id.isNotEmpty() }.take(limit).toList()
    }

    /** A watch list stays short; the phone and the web show the rest. */
    const val MAX_DEVICES = 6

    /** My status in `GET /api/presence`; `null` for guests and kiosk displays. */
    fun presence(json: String): Presence? {
        val mine = JSONObject(json).optJSONObject("mine") ?: return null
        return Presence.parse(mine.optString("status"))
    }

    /**
     * The next event of `GET /api/calendar/events`: the earliest timed event
     * that has not ended at [now], otherwise the earliest all-day event that
     * has not ended. A running meeting is more useful than a holiday that
     * lasts all day.
     */
    fun nextEvent(json: String, now: Instant, zone: ZoneId): NextEvent? {
        val events = JSONObject(json).optJSONArray("events") ?: return null
        data class Candidate(val event: NextEvent, val end: Instant)
        val candidates = (0 until events.length()).mapNotNull { i ->
            val e = events.optJSONObject(i) ?: return@mapNotNull null
            val startText = e.optString("start")
            val allDay = e.optBoolean("allDay") || startText.length == DATE_LENGTH
            val start = instant(startText, zone) ?: return@mapNotNull null
            val end = instant(e.optString("end"), zone)
                ?: if (allDay) start.atZone(zone).plusDays(1).toInstant() else start
            Candidate(NextEvent(e.optString("summary"), start.toEpochMilli(), allDay), end)
        }.filter { it.end.isAfter(now) }
        val (allDay, timed) = candidates.partition { it.event.allDay }
        return (timed.minByOrNull { it.event.startMillis } ?: allDay.minByOrNull { it.event.startMillis })?.event
    }

    private const val DATE_LENGTH = 10

    private fun instant(text: String, zone: ZoneId): Instant? = try {
        if (text.length == DATE_LENGTH) {
            LocalDate.parse(text).atStartOfDay(zone).toInstant()
        } else {
            OffsetDateTime.parse(text).toInstant()
        }
    } catch (e: DateTimeParseException) {
        null
    }
}
