package app.waylight.waylight_mobile.home

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import app.waylight.waylight_mobile.MainActivity
import app.waylight.waylight_mobile.R
import org.json.JSONObject

/**
 * A home screen widget that draws one card of [HomeWidgetStore] (#42). The
 * app formats the text; this class only lays it out and opens the card's
 * link on a tap. Before the first refresh it asks to open the app.
 */
abstract class SnapshotWidget(private val kind: String) : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        draw(context, manager, ids, kind)
    }

    companion object {
        fun draw(context: Context, manager: AppWidgetManager, ids: IntArray, kind: String) {
            val card = HomeWidgetStore.read(context, kind)?.let { runCatching { JSONObject(it) }.getOrNull() }
            val views = RemoteViews(context.packageName, R.layout.home_widget)
            if (card == null) {
                views.setTextViewText(R.id.title, "Waylight")
                views.setTextViewText(R.id.body, context.getString(R.string.home_widget_open_app))
                views.setViewVisibility(R.id.footer, View.GONE)
                views.setViewVisibility(R.id.summary, View.GONE)
            } else {
                val lines = card.optJSONArray("lines")
                val text = (0 until (lines?.length() ?: 0)).joinToString("\n") { lines!!.optString(it) }
                views.setTextViewText(R.id.title, card.optString("title"))
                views.setTextViewText(R.id.body, text.ifEmpty { card.optString("empty") })
                views.setTextViewText(R.id.footer, card.optString("footer"))
                views.setViewVisibility(R.id.footer, View.VISIBLE)
                drawSummary(context, views, card)
            }
            val link = card?.optString("link")?.takeIf { it.startsWith("waylight:") } ?: "waylight://"
            val open = Intent(Intent.ACTION_VIEW, Uri.parse(link), context, MainActivity::class.java)
            views.setOnClickPendingIntent(
                R.id.root,
                PendingIntent.getActivity(
                    context,
                    kind.hashCode(),
                    open,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
            manager.updateAppWidget(ids, views)
        }

        /**
         * The title line of the widget's compact state (#242), coloured only
         * when it needs attention, as in the app's small tiles.
         */
        private fun drawSummary(context: Context, views: RemoteViews, card: JSONObject) {
            val summary = card.optString("summary")
            if (summary.isEmpty()) {
                views.setViewVisibility(R.id.summary, View.GONE)
                return
            }
            val color = when (card.optString("level")) {
                "attention" -> R.color.home_widget_attention
                "problem" -> R.color.home_widget_problem
                else -> R.color.home_widget_muted
            }
            views.setTextViewText(R.id.summary, summary)
            views.setTextColor(R.id.summary, context.getColor(color))
            views.setViewVisibility(R.id.summary, View.VISIBLE)
        }
    }
}

/** Open to-dos due today or overdue. */
class TodosWidget : SnapshotWidget("todos")

/** The next departures at the dashboard's stop. */
class DeparturesWidget : SnapshotWidget("departures")
