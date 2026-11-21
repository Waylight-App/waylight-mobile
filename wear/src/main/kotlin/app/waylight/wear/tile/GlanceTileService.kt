package app.waylight.wear.tile

import android.content.Context
import androidx.concurrent.futures.CallbackToFutureAdapter
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.DimensionBuilders.expand
import androidx.wear.protolayout.DimensionBuilders.sp
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import app.waylight.wear.MainActivity
import app.waylight.wear.R
import app.waylight.wear.data.SessionStore
import app.waylight.wear.glances.GlanceFormat
import app.waylight.wear.glances.GlanceStore
import app.waylight.wear.glances.Level
import app.waylight.wear.glances.Refresh
import app.waylight.wear.glances.Snapshot
import com.google.common.util.concurrent.ListenableFuture

/**
 * The Waylight tile: next event, open to-dos, my status and the other
 * compact states, with the age of the data. It draws the stored snapshot
 * and asks for a refresh when that is stale, so it never waits for the
 * network. A tap opens the app.
 */
class GlanceTileService : TileService() {
    override fun onTileRequest(requestParams: RequestBuilders.TileRequest): ListenableFuture<TileBuilders.Tile> {
        val paired = SessionStore(this).hasSession()
        val snapshot = if (paired) GlanceStore(this).load() else null
        if (paired && (snapshot == null || System.currentTimeMillis() - snapshot.fetchedAt > Refresh.STALE_AFTER_MS)) {
            Refresh.soon(this)
        }
        val tile = TileBuilders.Tile.Builder()
            .setResourcesVersion(RESOURCES_VERSION)
            // The system asks again after this time, so the age stays honest
            // even when no refresh comes through.
            .setFreshnessIntervalMillis(Refresh.STALE_AFTER_MS)
            .setTileTimeline(TimelineBuilders.Timeline.fromLayoutElement(layout(this, paired, snapshot)))
            .build()
        return done(tile)
    }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> =
        done(ResourceBuilders.Resources.Builder().setVersion(RESOURCES_VERSION).build())

    private fun <T : Any> done(value: T): ListenableFuture<T> =
        CallbackToFutureAdapter.getFuture { completer ->
            completer.set(value)
            "tile"
        }

    private companion object {
        const val RESOURCES_VERSION = "1"
        const val MAX_COMPACT_ROWS = 3

        // The tile's colours: Wear OS tiles are always dark.
        const val WHITE = 0xFFFFFFFF.toInt()
        const val GREY = 0xFFB0B0B0.toInt()
        const val AMBER = 0xFFF2B441.toInt()
        const val ATTENTION = 0xFFFFBA3B.toInt()
        const val PROBLEM = 0xFFFFB4AB.toInt()

        fun layout(context: Context, paired: Boolean, snapshot: Snapshot?): LayoutElementBuilders.LayoutElement {
            val column = LayoutElementBuilders.Column.Builder()
                .setWidth(expand())
                .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
            when {
                !paired -> column.addContent(text(context.getString(R.string.tile_not_paired), 14f, WHITE, maxLines = 3))
                snapshot == null -> column.addContent(text(context.getString(R.string.loading), 14f, GREY))
                else -> {
                    snapshot.nextEvent?.let { event ->
                        column.addContent(text(GlanceFormat.eventWhen(context, event), 13f, AMBER))
                        column.addContent(text(event.summary, 15f, WHITE, maxLines = 2, bold = true))
                        column.addContent(spacer())
                    }
                    snapshot.compact.take(MAX_COMPACT_ROWS).forEach { glance ->
                        val color = when (glance.level) {
                            Level.ATTENTION -> ATTENTION
                            Level.PROBLEM -> PROBLEM
                            else -> WHITE
                        }
                        column.addContent(text(GlanceFormat.compactTitle(context, glance), 13f, color))
                    }
                    snapshot.presence?.let { column.addContent(text(GlanceFormat.presence(context, it), 13f, WHITE)) }
                    column.addContent(spacer())
                    column.addContent(text(GlanceFormat.updated(context, snapshot.fetchedAt), 11f, GREY))
                }
            }
            val open = ModifiersBuilders.Clickable.Builder()
                .setId("open")
                .setOnClick(
                    ActionBuilders.LaunchAction.Builder()
                        .setAndroidActivity(
                            ActionBuilders.AndroidActivity.Builder()
                                .setPackageName(context.packageName)
                                .setClassName(MainActivity::class.java.name)
                                .build(),
                        )
                        .build(),
                )
                .build()
            return LayoutElementBuilders.Box.Builder()
                .setWidth(expand())
                .setHeight(expand())
                .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
                .setVerticalAlignment(LayoutElementBuilders.VERTICAL_ALIGN_CENTER)
                .setModifiers(
                    ModifiersBuilders.Modifiers.Builder()
                        .setClickable(open)
                        .setPadding(
                            // Keeps the text inside the round screen.
                            ModifiersBuilders.Padding.Builder()
                                .setStart(dp(24f))
                                .setEnd(dp(24f))
                                .setTop(dp(24f))
                                .setBottom(dp(24f))
                                .build(),
                        )
                        .build(),
                )
                .addContent(column.build())
                .build()
        }

        fun text(value: String, size: Float, color: Int, maxLines: Int = 1, bold: Boolean = false): LayoutElementBuilders.Text {
            val style = LayoutElementBuilders.FontStyle.Builder()
                .setSize(sp(size))
                .setColor(argb(color))
            if (bold) style.setWeight(LayoutElementBuilders.FONT_WEIGHT_BOLD)
            return LayoutElementBuilders.Text.Builder()
                .setText(value)
                .setMaxLines(maxLines)
                .setOverflow(LayoutElementBuilders.TEXT_OVERFLOW_ELLIPSIZE_END)
                .setFontStyle(style.build())
                .build()
        }

        fun spacer(): LayoutElementBuilders.Spacer =
            LayoutElementBuilders.Spacer.Builder().setHeight(dp(4f)).build()
    }
}
