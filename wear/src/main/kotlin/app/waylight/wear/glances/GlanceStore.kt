package app.waylight.wear.glances

import android.content.Context

/**
 * The last [Snapshot] in the app's private preferences, so the tile can
 * draw without a network request. Deleted on sign-out.
 */
class GlanceStore(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun load(): Snapshot? = prefs.getString(KEY, null)?.let(Snapshot::fromJson)

    fun save(snapshot: Snapshot) {
        prefs.edit().putString(KEY, snapshot.toJson()).commit()
    }

    fun clear() {
        prefs.edit().clear().commit()
    }

    private companion object {
        const val PREFS = "glances"
        const val KEY = "snapshot"
    }
}
