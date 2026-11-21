package app.waylight.wear.complications

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.LongTextComplicationData
import androidx.wear.watchface.complications.data.NoDataComplicationData
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceUpdateRequester
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import app.waylight.wear.MainActivity
import app.waylight.wear.R
import app.waylight.wear.glances.GlanceFormat
import app.waylight.wear.glances.GlanceStore
import app.waylight.wear.glances.NextEvent
import app.waylight.wear.glances.Snapshot
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Complications for watch faces (#244), fed from the stored snapshot like
 * the tile. They never fetch themselves: [Refresh][app.waylight.wear.glances.Refresh]
 * asks for an update after every fetch, so the watch face, the tile and the
 * app show the same data.
 */
object Complications {
    /** Asks every watch face that shows one of our complications to redraw it. */
    fun requestUpdate(context: Context) {
        for (service in listOf(NextEventComplicationService::class.java, TodosComplicationService::class.java)) {
            ComplicationDataSourceUpdateRequester.create(context, ComponentName(context, service)).requestUpdateAll()
        }
    }

    /** The number of open to-dos, from the to-dos' compact state. */
    fun openTodos(snapshot: Snapshot?): Int? = snapshot?.compact?.firstOrNull { it.module == "todos" }?.count

    /** Shortens [text] to [max] characters for the small complication slots. */
    fun shorten(text: String, max: Int): String =
        if (text.length <= max) text else text.take(max - 1).trimEnd() + "…"

    // Short text slots fit about seven characters (Wear OS guidelines).
    const val SHORT_TITLE = 7

    internal fun openApp(context: Context): PendingIntent = PendingIntent.getActivity(
        context,
        0,
        Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        PendingIntent.FLAG_IMMUTABLE,
    )

    internal fun text(value: String) = PlainComplicationText.Builder(value).build()

    internal fun nextEvent(context: Context, type: ComplicationType, event: NextEvent?): ComplicationData {
        if (event == null) return NoDataComplicationData()
        val time = GlanceFormat.eventWhen(context, event)
        val description = text("${event.summary}, $time")
        return when (type) {
            ComplicationType.SHORT_TEXT -> ShortTextComplicationData.Builder(text(time), description)
                .setTitle(text(shorten(event.summary, SHORT_TITLE)))
                .setTapAction(openApp(context))
                .build()
            ComplicationType.LONG_TEXT -> LongTextComplicationData.Builder(text(event.summary), description)
                .setTitle(text(time))
                .setTapAction(openApp(context))
                .build()
            else -> NoDataComplicationData()
        }
    }

    internal fun todos(context: Context, type: ComplicationType, open: Int?): ComplicationData {
        if (open == null || type != ComplicationType.SHORT_TEXT) return NoDataComplicationData()
        val description = context.resources.getQuantityString(R.plurals.todos_open, open, open)
        return ShortTextComplicationData.Builder(text(open.toString()), text(description))
            .setTitle(text(context.getString(R.string.complication_todos_title)))
            .setTapAction(openApp(context))
            .build()
    }
}

/** The next calendar event: time and title (short) or title and time (long). */
class NextEventComplicationService : SuspendingComplicationDataSourceService() {
    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData {
        val snapshot = withContext(Dispatchers.IO) { GlanceStore(this@NextEventComplicationService).load() }
        return Complications.nextEvent(this, request.complicationType, snapshot?.nextEvent)
    }

    override fun getPreviewData(type: ComplicationType): ComplicationData =
        Complications.nextEvent(this, type, NextEvent(getString(R.string.complication_preview_event), PREVIEW_START, allDay = false))

    private companion object {
        // Any fixed time; the editor only shows the layout.
        const val PREVIEW_START = 1_763_719_200_000L
    }
}

/** The number of open to-dos. */
class TodosComplicationService : SuspendingComplicationDataSourceService() {
    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData {
        val snapshot = withContext(Dispatchers.IO) { GlanceStore(this@TodosComplicationService).load() }
        return Complications.todos(this, request.complicationType, Complications.openTodos(snapshot))
    }

    override fun getPreviewData(type: ComplicationType): ComplicationData = Complications.todos(this, type, PREVIEW_COUNT)

    private companion object {
        const val PREVIEW_COUNT = 3
    }
}
