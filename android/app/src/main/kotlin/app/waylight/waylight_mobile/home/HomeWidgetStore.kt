package app.waylight.waylight_mobile.home

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context

/**
 * The cards of the home screen widgets, as JSON written by the app. They
 * hold display text only, never credentials.
 */
object HomeWidgetStore {
    private const val PREFS = "home_widgets"

    /** The widget class that shows the card [kind]. */
    private val providers = mapOf(
        "todos" to TodosWidget::class.java,
        "departures" to DeparturesWidget::class.java,
    )

    fun save(context: Context, kind: String, card: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(kind, card).apply()
        redraw(context, kind)
    }

    fun clear(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
        providers.keys.forEach { redraw(context, it) }
    }

    fun read(context: Context, kind: String): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(kind, null)

    private fun redraw(context: Context, kind: String) {
        val provider = providers[kind] ?: return
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, provider))
        if (ids.isNotEmpty()) SnapshotWidget.draw(context, manager, ids, kind)
    }
}
