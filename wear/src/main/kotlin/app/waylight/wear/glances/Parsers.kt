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

    /** A `CompactState` of [module]. */
    fun compact(module: String, json: String): CompactGlance {
        val o = JSONObject(json)
        return CompactGlance(
            module = module,
            title = o.optJSONObject("title")?.optString("text").orEmpty(),
            detail = o.optJSONObject("detail")?.optString("text")?.takeIf { it.isNotEmpty() },
            level = Level.parse(o.optString("level")),
            count = if (o.has("count") && !o.isNull("count")) o.optInt("count") else null,
        )
    }

    /** The number of open to-dos in `GET /api/todos`, for servers without the compact state. */
    fun openTodos(json: String): Int {
        val array = JSONArray(json)
        return (0 until array.length()).count { array.optJSONObject(it)?.optBoolean("done") == false }
    }

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
