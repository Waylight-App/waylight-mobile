package app.waylight.waylight_mobile.controls

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.service.controls.Control
import android.service.controls.DeviceTypes
import android.service.controls.templates.ControlButton
import android.service.controls.templates.ControlTemplate
import android.service.controls.templates.StatelessTemplate
import android.service.controls.templates.ToggleTemplate
import androidx.annotation.RequiresApi
import app.waylight.waylight_mobile.MainActivity
import app.waylight.waylight_mobile.R
import org.json.JSONException
import org.json.JSONObject

/**
 * What Android's device controls show (#194). Flutter writes the entities
 * of the smart home module with their states in the app's language; the
 * controls only draw them, as the tiles and home screen widgets do
 * (ADR 0009).
 */
object DeviceControls {
    private const val PREFS = "waylight_device_controls"
    private const val KEY_STATE = "state"
    private const val KEY_SAVED_AT = "savedAt"
    private const val SMART_HOME_LINK = "waylight://smart-home"

    data class Entry(
        val id: String,
        val name: String,
        val type: String,
        val device: String,
        val on: Boolean,
        val status: String,
    )

    /** The last controls Flutter saved, whether their states are current and why not. */
    data class Snapshot(val available: Boolean, val reason: String, val entries: List<Entry>)

    /**
     * Stores [json]. An unavailable snapshot carries no controls, so the
     * known ones stay and are drawn as unavailable.
     */
    fun save(context: Context, json: String) {
        val incoming = parse(json) ?: return
        val merged = if (incoming.available) incoming else incoming.copy(entries = snapshot(context).entries)
        prefs(context).edit()
            .putString(KEY_STATE, encode(merged))
            // Always a change, so waiting publishers learn that a run ended.
            .putLong(KEY_SAVED_AT, System.currentTimeMillis())
            .apply()
    }

    fun clear(context: Context) {
        prefs(context).edit().remove(KEY_STATE).putLong(KEY_SAVED_AT, System.currentTimeMillis()).apply()
    }

    fun snapshot(context: Context): Snapshot =
        prefs(context).getString(KEY_STATE, null)?.let(::parse) ?: Snapshot(false, "", emptyList())

    fun listen(context: Context, listener: SharedPreferences.OnSharedPreferenceChangeListener) =
        prefs(context).registerOnSharedPreferenceChangeListener(listener)

    fun unlisten(context: Context, listener: SharedPreferences.OnSharedPreferenceChangeListener) =
        prefs(context).unregisterOnSharedPreferenceChangeListener(listener)

    /** A control for the system's picker, without a state. */
    @RequiresApi(Build.VERSION_CODES.R)
    fun stateless(context: Context, entry: Entry): Control =
        Control.StatelessBuilder(entry.id, appIntent(context))
            .setTitle(entry.name)
            .setSubtitle(context.getString(R.string.device_controls_subtitle))
            .setDeviceType(deviceType(entry.device))
            .build()

    /**
     * The control [id] with its state. Unknown ids are not found; while
     * the states are not current the control is disabled and says why,
     * never showing a state that may be wrong.
     */
    @RequiresApi(Build.VERSION_CODES.R)
    fun stateful(context: Context, id: String, snapshot: Snapshot): Control {
        val entry = snapshot.entries.firstOrNull { it.id == id }
        val builder = Control.StatefulBuilder(id, appIntent(context))
            .setTitle(entry?.name ?: id)
            .setSubtitle(context.getString(R.string.device_controls_subtitle))
            .setDeviceType(deviceType(entry?.device))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // The system setting decides whether controls work on the lock screen.
            builder.setAuthRequired(false)
        }
        when {
            entry == null && snapshot.available -> builder.setStatus(Control.STATUS_NOT_FOUND)
            entry == null || !snapshot.available -> builder
                .setStatus(Control.STATUS_DISABLED)
                .setStatusText(snapshot.reason.ifEmpty { context.getString(R.string.device_controls_sign_in) })
            else -> builder
                .setStatus(Control.STATUS_OK)
                .setStatusText(entry.status)
                .setControlTemplate(template(entry))
        }
        return builder.build()
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun template(entry: Entry): ControlTemplate = when (entry.type) {
        "toggle" -> ToggleTemplate(entry.id, ControlButton(entry.on, entry.name))
        "button" -> StatelessTemplate(entry.id)
        else -> ControlTemplate.getNoTemplateObject()
    }

    private fun deviceType(device: String?): Int = when (device) {
        "light" -> DeviceTypes.TYPE_LIGHT
        "switcher" -> DeviceTypes.TYPE_SWITCH
        "routine" -> DeviceTypes.TYPE_ROUTINE
        "sensor" -> DeviceTypes.TYPE_UNKNOWN
        else -> DeviceTypes.TYPE_GENERIC_ON_OFF
    }

    private fun appIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse(SMART_HOME_LINK)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun parse(json: String): Snapshot? = try {
        val o = JSONObject(json)
        val list = o.optJSONArray("controls")
        val entries = (0 until (list?.length() ?: 0)).mapNotNull { i ->
            val c = list?.optJSONObject(i) ?: return@mapNotNull null
            val id = c.optString("id")
            if (id.isEmpty()) {
                null
            } else {
                Entry(
                    id = id,
                    name = c.optString("name", id),
                    type = c.optString("type"),
                    device = c.optString("device"),
                    on = c.optBoolean("on"),
                    status = c.optString("status"),
                )
            }
        }
        Snapshot(o.optBoolean("available"), o.optString("reason"), entries)
    } catch (e: JSONException) {
        null
    }

    private fun encode(s: Snapshot): String {
        val controls = org.json.JSONArray()
        s.entries.forEach { e ->
            controls.put(
                JSONObject()
                    .put("id", e.id)
                    .put("name", e.name)
                    .put("type", e.type)
                    .put("device", e.device)
                    .put("on", e.on)
                    .put("status", e.status),
            )
        }
        return JSONObject()
            .put("available", s.available)
            .put("reason", s.reason)
            .put("controls", controls)
            .toString()
    }

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
