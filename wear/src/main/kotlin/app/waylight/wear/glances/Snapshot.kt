package app.waylight.wear.glances

import org.json.JSONArray
import org.json.JSONObject

/** How a compact state wants to be shown; clients colour only the last two. */
enum class Level {
    NONE,
    OK,
    ATTENTION,
    PROBLEM;

    companion object {
        fun parse(value: String?): Level = when (value) {
            "ok" -> OK
            "attention" -> ATTENTION
            "problem" -> PROBLEM
            else -> NONE
        }
    }
}

/** The next calendar event; all-day events start at local midnight. */
data class NextEvent(val summary: String, val startMillis: Long, val allDay: Boolean)

/**
 * The compact state of a module (`GET /api/<module>/compact`, the server's
 * `CompactState`). [title] and [detail] are translated when shown
 * ([ServerTexts]). [empty] is true when the module has nothing to show yet
 * (server #619), such as a calendar that is not set up.
 */
data class CompactGlance(
    val module: String,
    val title: GlanceText,
    val detail: GlanceText?,
    val level: Level,
    val count: Int?,
    val action: GlanceAction? = null,
    val empty: Boolean = false,
)

/** My presence today (`GET /api/presence`): office, home, away or none. */
enum class Presence {
    OFFICE,
    HOME,
    AWAY,
    NONE;

    companion object {
        fun parse(value: String?): Presence = when (value) {
            "office" -> OFFICE
            "home" -> HOME
            "away" -> AWAY
            else -> NONE
        }
    }
}

/**
 * Everything the app and the tile show, fetched at [fetchedAt] (epoch
 * milliseconds). Missing parts are modules that are off or unknown to the
 * server.
 */
data class Snapshot(
    val fetchedAt: Long,
    val nextEvent: NextEvent?,
    val presence: Presence?,
    val compact: List<CompactGlance>,
    val firstTodo: OpenTodo? = null,
    val devices: List<Device> = emptyList(),
) {
    fun toJson(): String = JSONObject().apply {
        put("fetchedAt", fetchedAt)
        nextEvent?.let {
            put("nextEvent", JSONObject().put("summary", it.summary).put("start", it.startMillis).put("allDay", it.allDay))
        }
        presence?.let { put("presence", it.name) }
        put(
            "compact",
            JSONArray().apply {
                compact.forEach { c ->
                    put(
                        JSONObject().apply {
                            put("module", c.module)
                            put("title", c.title.toJson())
                            c.detail?.let { put("detail", it.toJson()) }
                            put("level", c.level.name)
                            c.count?.let { put("count", it) }
                            c.action?.let { put("action", it.toJson()) }
                            if (c.empty) put("empty", true)
                        },
                    )
                }
            },
        )
        firstTodo?.let { put("firstTodo", it.toJson()) }
        put("devices", JSONArray().apply { devices.forEach { put(it.toJson()) } })
    }.toString()

    companion object {
        /** Reads what [toJson] wrote; `null` for anything else. */
        fun fromJson(text: String): Snapshot? = try {
            val o = JSONObject(text)
            Snapshot(
                fetchedAt = o.getLong("fetchedAt"),
                nextEvent = o.optJSONObject("nextEvent")?.let {
                    NextEvent(it.getString("summary"), it.getLong("start"), it.optBoolean("allDay"))
                },
                presence = o.optString("presence").takeIf { it.isNotEmpty() }?.let { name ->
                    Presence.entries.firstOrNull { it.name == name }
                },
                compact = o.optJSONArray("compact")?.let { array ->
                    (0 until array.length()).map { i ->
                        val c = array.getJSONObject(i)
                        CompactGlance(
                            module = c.getString("module"),
                            title = storedText(c, "title") ?: GlanceText(""),
                            detail = storedText(c, "detail"),
                            level = Level.entries.firstOrNull { it.name == c.optString("level") } ?: Level.NONE,
                            count = if (c.has("count")) c.getInt("count") else null,
                            action = GlanceAction.fromJson(c.optJSONObject("action")),
                            empty = c.optBoolean("empty"),
                        )
                    }
                }.orEmpty(),
                firstTodo = OpenTodo.fromJson(o.optJSONObject("firstTodo")),
                devices = o.optJSONArray("devices")?.let { array ->
                    (0 until array.length()).mapNotNull { array.optJSONObject(it)?.let(Device::fromJson) }
                }.orEmpty(),
            )
        } catch (e: org.json.JSONException) {
            null
        }

        // Snapshots stored before #246 kept only the English text.
        private fun storedText(o: JSONObject, name: String): GlanceText? =
            GlanceText.fromJson(o.optJSONObject(name))
                ?: o.optString(name).takeIf { it.isNotEmpty() }?.let { GlanceText(it) }
    }
}
