package app.waylight.wear.tile

import android.content.Context
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import app.waylight.wear.R
import app.waylight.wear.data.SessionStore
import app.waylight.wear.glances.GlanceFormat
import app.waylight.wear.glances.GlanceStore
import app.waylight.wear.glances.Snapshot
import app.waylight.wear.glances.StatusOverview
import app.waylight.wear.tile.TileParts.AMBER
import app.waylight.wear.tile.TileParts.GREY
import app.waylight.wear.tile.TileParts.WHITE
import app.waylight.wear.tile.TileParts.spacer
import app.waylight.wear.tile.TileParts.text
import com.google.common.util.concurrent.ListenableFuture

/**
 * The status tile (#247): the compact states of every module the server
 * lists, problems and things that need a look first, each with its module's
 * name. It draws the same stored snapshot as the glances tile and refreshes
 * the same way; a tap opens the app, which lists all states with details.
 */
class StatusTileService : TileService() {
    override fun onTileRequest(requestParams: RequestBuilders.TileRequest): ListenableFuture<TileBuilders.Tile> {
        val paired = SessionStore(this).hasSession()
        val snapshot = if (paired) GlanceStore(this).load() else null
        TileParts.refreshIfStale(this, paired, snapshot)
        return TileParts.done(TileParts.tile(layout(this, paired, snapshot)))
    }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> = TileParts.done(TileParts.resources())

    private companion object {
        fun layout(context: Context, paired: Boolean, snapshot: Snapshot?): LayoutElementBuilders.LayoutElement {
            val column = TileParts.column()
            when {
                !paired -> column.addContent(text(context.getString(R.string.tile_not_paired), 14f, WHITE, maxLines = 3))
                snapshot == null -> column.addContent(text(context.getString(R.string.loading), 14f, GREY))
                else -> {
                    val rows = StatusOverview.rows(snapshot.compact)
                    val needingLook = StatusOverview.needingLook(snapshot.compact)
                    val summary = when {
                        rows.isEmpty() -> context.getString(R.string.status_nothing)
                        needingLook == 0 -> context.getString(R.string.status_all_good)
                        else -> context.resources.getQuantityString(R.plurals.status_need_look, needingLook, needingLook)
                    }
                    column.addContent(text(summary, 14f, if (needingLook == 0) AMBER else TileParts.PROBLEM, bold = true))
                    column.addContent(spacer())
                    rows.forEach { glance ->
                        column.addContent(text(GlanceFormat.moduleName(context, glance.module), 11f, GREY))
                        column.addContent(text(GlanceFormat.compactTitle(context, glance), 13f, TileParts.colorOf(glance.level)))
                    }
                    column.addContent(spacer())
                    column.addContent(text(GlanceFormat.updated(context, snapshot.fetchedAt), 11f, GREY))
                }
            }
            return TileParts.frame(context, column.build())
        }
    }
}
