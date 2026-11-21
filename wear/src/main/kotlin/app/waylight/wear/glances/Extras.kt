package app.waylight.wear.glances

import org.json.JSONArray
import org.json.JSONObject

/**
 * The first open to-do (`GET /api/todos`), which the app and the tile can
 * tick off (#245). [due] and [version] are sent back with the change, so
 * the due date stays and a newer change elsewhere wins.
 */
data class OpenTodo(val id: String, val title: String, val due: String, val version: Int) {
    fun toJson(): JSONObject = JSONObject().put("id", id).put("title", title).put("due", due).put("version", version)

    companion object {
        fun fromJson(o: JSONObject?): OpenTodo? = o?.let {
            OpenTodo(it.getString("id"), it.optString("title"), it.optString("due"), it.optInt("version"))
        }
    }
}

/** How a smart home entity reacts to a tap. */
enum class DeviceAction { TOGGLE, PRESS }

/** A smart home entity the server allows to switch (`GET /api/smarthome/entities`). */
data class Device(val id: String, val name: String, val state: String, val action: DeviceAction) {
    fun toJson(): JSONObject = JSONObject().put("id", id).put("name", name).put("state", state).put("action", action.name)

    companion object {
        fun fromJson(o: JSONObject): Device? {
            val action = DeviceAction.entries.firstOrNull { it.name == o.optString("action") } ?: return null
            return Device(o.getString("id"), o.optString("name"), o.optString("state"), action)
        }
    }
}

/** One chip of a [GlanceAction], e.g. *office* of the presence status. */
data class GlanceChoice(val id: String, val label: GlanceText, val body: String?, val selected: Boolean) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id)
        put("label", label.toJson())
        body?.let { put("body", it) }
        put("selected", selected)
    }

    companion object {
        fun fromJson(o: JSONObject): GlanceChoice = GlanceChoice(
            id = o.optString("id"),
            label = GlanceText.fromJson(o.optJSONObject("label")) ?: GlanceText(""),
            body = bodyOf(o),
            selected = o.optBoolean("selected"),
        )
    }
}

/**
 * The primary action of a compact state (server #598): one request, or one
 * request per choice. [body] is the JSON to send, kept as text.
 */
data class GlanceAction(
    val id: String,
    val label: GlanceText,
    val method: String,
    val path: String,
    val body: String?,
    val choices: List<GlanceChoice>,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id)
        put("label", label.toJson())
        put("method", method)
        put("path", path)
        body?.let { put("body", it) }
        put("choices", JSONArray().apply { choices.forEach { put(it.toJson()) } })
    }

    companion object {
        /**
         * Reads the server's `CompactAction` or what [toJson] wrote; `null`
         * when it is missing or would leave the API (only `POST`, `PUT`,
         * `PATCH` and `DELETE` to `/api/…` are sent).
         */
        fun fromJson(o: JSONObject?): GlanceAction? {
            if (o == null) return null
            val method = o.optString("method").uppercase()
            val path = o.optString("path")
            if (method !in METHODS || !path.startsWith("/api/") || ".." in path) return null
            val choices = o.optJSONArray("choices")?.let { a ->
                (0 until a.length()).mapNotNull { a.optJSONObject(it)?.let(GlanceChoice::fromJson) }
            }.orEmpty()
            return GlanceAction(
                id = o.optString("id"),
                label = GlanceText.fromJson(o.optJSONObject("label")) ?: GlanceText(""),
                method = method,
                path = path,
                body = bodyOf(o),
                choices = choices,
            )
        }

        private val METHODS = setOf("POST", "PUT", "PATCH", "DELETE")
    }
}

// The server sends the body as a JSON object; the stored snapshot keeps it
// as text.
private fun bodyOf(o: JSONObject): String? = when (val body = o.opt("body")) {
    is JSONObject -> body.toString()
    is String -> body.takeIf { it.isNotEmpty() }
    else -> null
}
