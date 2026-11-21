package app.waylight.wear.glances

import android.content.Context
import app.waylight.wear.R
import org.json.JSONObject

/**
 * A text of a compact state (the server's `CompactText`): the English
 * [text] with its parameters filled in, the [key] of its template in the
 * server's message catalogue and the [params] for the placeholders.
 */
data class GlanceText(
    val text: String,
    val key: String = "",
    val params: Map<String, String> = emptyMap(),
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("text", text)
        if (key.isNotEmpty()) put("key", key)
        if (params.isNotEmpty()) put("params", JSONObject(params))
    }

    companion object {
        /** Reads a `CompactText`; `null` when [o] is missing. */
        fun fromJson(o: JSONObject?): GlanceText? {
            if (o == null) return null
            val params = o.optJSONObject("params")?.let { p ->
                p.keys().asSequence().associateWith { p.optString(it) }
            }.orEmpty()
            return GlanceText(o.optString("text"), o.optString("key"), params)
        }
    }
}

/**
 * Translates the texts of compact states on the watch (#246). The server
 * sends English text plus the key of its template (`srv_` and the FNV-1a
 * hash of the English template, as in the web interface's catalogue). The
 * templates of the modules in [GlanceFetcher.COMPACT_MODULES] are string
 * resources here, in English and German; an unknown key, from a newer
 * server, falls back to the server's English text.
 */
object ServerTexts {
    /** The string resource of each known template key. */
    val templates: Map<String, Int> = mapOf(
        "srv_fe19a87a4c31a1ac" to R.string.srv_todos_open,
        "srv_8474d36c18713018" to R.string.srv_todos_nothing,
        "srv_4fd610086ba2117c" to R.string.srv_todos_overdue,
        "srv_3ae46504f4002e93" to R.string.srv_habits_none,
        "srv_47c68f21f5a3748b" to R.string.srv_habits_done,
        "srv_cf0e9452be96913b" to R.string.srv_focus_minutes,
        "srv_74b44643f778ca81" to R.string.srv_focus_sessions,
    )

    /** [text] in the watch's language. */
    fun resolve(context: Context, text: GlanceText): String {
        val id = templates[text.key] ?: return text.text
        return fill(context.getString(id), text.params)
    }

    /**
     * Replaces every `{name}` in [template] with its value. A placeholder
     * without a value stays visible, so a mismatch shows instead of hiding.
     */
    fun fill(template: String, params: Map<String, String>): String =
        PLACEHOLDER.replace(template) { match -> params[match.groupValues[1]] ?: match.value }

    private val PLACEHOLDER = Regex("""\{([A-Za-z0-9_]+)\}""")
}
