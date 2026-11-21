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
 * templates of the compact states the watch shows are string resources
 * here, in English and German; templates that are only placeholders or
 * read the same in both languages are left out. An unknown key, from a
 * newer server, falls back to the server's English text.
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
        "srv_4efa152402f99eaf" to R.string.srv_backups_none,
        "srv_690e8b1d63e37e2e" to R.string.srv_backups_failed,
        "srv_44460b43e14f12f1" to R.string.srv_backups_name_failed,
        "srv_8ede15696ca60c31" to R.string.srv_backups_overdue,
        "srv_654703b9e7d6cc6c" to R.string.srv_backups_name_overdue,
        "srv_122bbf8d15074197" to R.string.srv_backups_waiting,
        "srv_5533d9eb788ce382" to R.string.srv_backups_ok,
        "srv_54022920e535da37" to R.string.srv_backup_ok,
        "srv_dca29003ab21344d" to R.string.srv_backups_last_success,
        "srv_e40289b4499ed164" to R.string.srv_services_none,
        "srv_85ec6321e77d0b4a" to R.string.srv_services_running,
        "srv_09bd02ddefc751e8" to R.string.srv_services_name_down,
        "srv_ac66b193c5335c18" to R.string.srv_services_down,
        "srv_f724ce57caa5bee3" to R.string.srv_disks_none,
        "srv_26f374c0a67c8c36" to R.string.srv_disks_failing,
        "srv_fdd6ac3006cff821" to R.string.srv_disks_device_failing,
        "srv_2ac49ee2d1d4b8bc" to R.string.srv_disks_warning,
        "srv_ccd2d42e76e2629c" to R.string.srv_disks_device_warning,
        "srv_4590f8e90f51cb7d" to R.string.srv_disks_healthy,
        "srv_4886a197fd6d3ced" to R.string.srv_disks_some_healthy,
        "srv_a8b97fb3f9f0cd6b" to R.string.srv_disks_outdated,
        "srv_19f48a82e61c671a" to R.string.srv_docker_running,
        "srv_789f61f53fa5ac29" to R.string.srv_docker_unreachable,
        "srv_2a91fd7383166bf0" to R.string.srv_docker_unhealthy,
        "srv_da9839ea10b35eed" to R.string.srv_docker_stopped,
        "srv_7bdfe10b53bb1afd" to R.string.srv_parcels_none,
        "srv_75a6a213ce2bf505" to R.string.srv_parcels_on_the_way,
        "srv_2af79387a021fa8c" to R.string.srv_parcels_problem,
        "srv_f571f5204b6ac82d" to R.string.srv_parcels_today,
        "srv_a61c7e4a9008bf06" to R.string.srv_speedtest_none,
        "srv_91cee62ab90d375e" to R.string.srv_speedtest_unreachable,
        "srv_4f02e7bfc777a185" to R.string.srv_proxmox_running,
        "srv_310b2c277042df51" to R.string.srv_proxmox_unreachable,
        "srv_d0a400a5e85d849b" to R.string.srv_proxmox_nodes_offline,
        "srv_d94ddd59412dba1f" to R.string.srv_wireguard_connected,
        "srv_79255c3da312af57" to R.string.srv_wireguard_none,
        "srv_a7f77e98c90729a9" to R.string.srv_wireguard_outdated,
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
