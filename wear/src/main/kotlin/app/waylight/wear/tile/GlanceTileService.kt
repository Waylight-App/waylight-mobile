package app.waylight.wear.tile

import android.content.Context
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import app.waylight.wear.R
import app.waylight.wear.data.SessionStore
import app.waylight.wear.glances.Actions
import app.waylight.wear.glances.GlanceFetcher
import app.waylight.wear.glances.GlanceFormat
import app.waylight.wear.glances.GlanceStore
import app.waylight.wear.glances.Snapshot
import app.waylight.wear.tile.TileParts.AMBER
import app.waylight.wear.tile.TileParts.GREY
import app.waylight.wear.tile.TileParts.WHITE
import app.waylight.wear.tile.TileParts.spacer
import app.waylight.wear.tile.TileParts.text
import com.google.common.util.concurrent.ListenableFuture

/**
 * The Waylight tile: next event, open to-dos, my status and the compact
 * states of the day's modules, with the age of the data. It draws the
 * stored snapshot and asks for a refresh when that is stale, so it never
 * waits for the network. A tap on the first open to-do ticks it off in the
 * background (#245); a tap anywhere else opens the app. The states of the
 * other modules are on the status tile ([StatusTileService]).
 */
class GlanceTileService : TileService() {
    override fun onTileRequest(requestParams: RequestBuilders.TileRequest): ListenableFuture<TileBuilders.Tile> {
        val paired = SessionStore(this).hasSession()
        var snapshot = if (paired) GlanceStore(this).load() else null
        // A tap on the to-do row reloads the tile with that row's id.
        val todo = snapshot?.firstTodo
        if (todo != null && requestParams.currentState.lastClickableId == TICK_OFF) {
            Actions.completeTodoSoon(this, todo)
            // Hidden until the refresh after the request shows the next one.
            snapshot = snapshot?.copy(firstTodo = null)
        }
        TileParts.refreshIfStale(this, paired, snapshot)
        return TileParts.done(TileParts.tile(layout(this, paired, snapshot)))
    }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> = TileParts.done(TileParts.resources())

    private companion object {
        const val TICK_OFF = "tick-off"
        const val MAX_COMPACT_ROWS = 3

        fun layout(context: Context, paired: Boolean, snapshot: Snapshot?): LayoutElementBuilders.LayoutElement {
            val column = TileParts.column()
            when {
                !paired -> column.addContent(text(context.getString(R.string.tile_not_paired), 14f, WHITE, maxLines = 3))
                snapshot == null -> column.addContent(text(context.getString(R.string.loading), 14f, GREY))
                else -> {
                    snapshot.nextEvent?.let { event ->
                        column.addContent(text(GlanceFormat.eventWhen(context, event), 13f, AMBER))
                        column.addContent(text(event.summary, 15f, WHITE, maxLines = 2, bold = true))
                        column.addContent(spacer())
                    }
                    snapshot.compact.filter { it.module in GlanceFetcher.DAY_MODULES }.take(MAX_COMPACT_ROWS).forEach { glance ->
                        column.addContent(text(GlanceFormat.compactTitle(context, glance), 13f, TileParts.colorOf(glance.level)))
                    }
                    snapshot.firstTodo?.let { todo ->
                        column.addContent(tickOff(text(context.getString(R.string.tile_tick_off, todo.title), 13f, AMBER)))
                    }
                    snapshot.presence?.let { column.addContent(text(GlanceFormat.presence(context, it), 13f, WHITE)) }
                    column.addContent(spacer())
                    column.addContent(text(GlanceFormat.updated(context, snapshot.fetchedAt), 11f, GREY))
                }
            }
            return TileParts.frame(context, column.build())
        }

        /** Makes [content] tick off the first to-do: the tile reloads with [TICK_OFF]. */
        fun tickOff(content: LayoutElementBuilders.LayoutElement): LayoutElementBuilders.LayoutElement =
            LayoutElementBuilders.Box.Builder()
                .setModifiers(
                    ModifiersBuilders.Modifiers.Builder()
                        .setClickable(
                            ModifiersBuilders.Clickable.Builder()
                                .setId(TICK_OFF)
                                .setOnClick(ActionBuilders.LoadAction.Builder().build())
                                .build(),
                        )
                        // A comfortable touch target on a small screen.
                        .setPadding(ModifiersBuilders.Padding.Builder().setTop(dp(4f)).setBottom(dp(4f)).build())
                        .build(),
                )
                .addContent(content)
                .build()
    }
}
