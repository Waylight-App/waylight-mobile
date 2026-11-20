package app.waylight.waylight_mobile.push

import android.content.Context

/** What the push service keeps between runs: whether it is on and where the stream stopped. */
class PushSettings(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    var enabled: Boolean
        get() = prefs.getBoolean(ENABLED, false)
        set(value) = prefs.edit().putBoolean(ENABLED, value).apply()

    /** The ID of the last event shown; sent as Last-Event-ID so the relay can drop it. */
    var lastEventId: String?
        get() = prefs.getString(LAST_EVENT_ID, null)
        set(value) = prefs.edit().putString(LAST_EVENT_ID, value).apply()

    private companion object {
        const val PREFS = "waylight_push"
        const val ENABLED = "enabled"
        const val LAST_EVENT_ID = "last_event_id"
    }
}
