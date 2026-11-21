package app.waylight.waylight_mobile.tiles

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.service.quicksettings.TileService
import org.json.JSONObject

/**
 * What the Quick Settings tiles show and the smart home entity the user
 * chose (#192). Flutter writes it in the app's language; the tiles only
 * draw it, as the home screen widgets do (ADR 0009).
 */
object QuickTiles {
    const val CAPTURE = "capture"
    const val SMART_HOME = "smartHome"
    const val STATUS = "status"

    private const val PREFS = "waylight_quick_tiles"

    data class State(val label: String, val subtitle: String, val active: Boolean)

    fun save(context: Context, kind: String, json: String) {
        prefs(context).edit().putString("state.$kind", json).apply()
        redraw(context, kind)
    }

    fun state(context: Context, kind: String): State? {
        val raw = prefs(context).getString("state.$kind", null) ?: return null
        return try {
            val o = JSONObject(raw)
            State(o.optString("label"), o.optString("subtitle"), o.optBoolean("active"))
        } catch (e: org.json.JSONException) {
            null
        }
    }

    /** Offers or hides a tile in the system's list of tiles to add. */
    fun offer(context: Context, kind: String, offered: Boolean) {
        val component = component(context, kind) ?: return
        val setting = if (offered) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        context.packageManager.setComponentEnabledSetting(component, setting, PackageManager.DONT_KILL_APP)
    }

    fun choose(context: Context, id: String, name: String) {
        prefs(context).edit().putString("choice.id", id).putString("choice.name", name).apply()
    }

    fun choice(context: Context): Pair<String, String>? {
        val p = prefs(context)
        val id = p.getString("choice.id", null) ?: return null
        return id to (p.getString("choice.name", null) ?: id)
    }

    fun clear(context: Context) {
        prefs(context).edit().clear().apply()
        listOf(CAPTURE, SMART_HOME, STATUS).forEach { redraw(context, it) }
    }

    /** Asks the system to call the tile's onStartListening again. */
    fun redraw(context: Context, kind: String) {
        val component = component(context, kind) ?: return
        TileService.requestListeningState(context, component)
    }

    private fun component(context: Context, kind: String): ComponentName? = when (kind) {
        CAPTURE -> ComponentName(context, CaptureTileService::class.java)
        SMART_HOME -> ComponentName(context, SmartHomeTileService::class.java)
        STATUS -> ComponentName(context, StatusTileService::class.java)
        else -> null
    }

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
