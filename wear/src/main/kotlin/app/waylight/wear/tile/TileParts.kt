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
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import app.waylight.wear.MainActivity
import app.waylight.wear.glances.Level
import app.waylight.wear.glances.Refresh
import app.waylight.wear.glances.Snapshot
import com.google.common.util.concurrent.ListenableFuture

/** The building blocks both tiles share: colours, text, the frame that opens the app. */
internal object TileParts {
    const val RESOURCES_VERSION = "1"

    // The tiles' colours: Wear OS tiles are always dark.
    const val WHITE = 0xFFFFFFFF.toInt()
    const val GREY = 0xFFB0B0B0.toInt()
    const val AMBER = 0xFFF2B441.toInt()
    const val ATTENTION = 0xFFFFBA3B.toInt()
    const val PROBLEM = 0xFFFFB4AB.toInt()

    /** The colour of a compact state: only attention and problem stand out. */
    fun colorOf(level: Level): Int = when (level) {
        Level.ATTENTION -> ATTENTION
        Level.PROBLEM -> PROBLEM
        else -> WHITE
    }

    /** Asks for a refresh when the stored data is missing or stale; the tile never waits for it. */
    fun refreshIfStale(context: Context, paired: Boolean, snapshot: Snapshot?) {
        if (paired && (snapshot == null || System.currentTimeMillis() - snapshot.fetchedAt > Refresh.STALE_AFTER_MS)) {
            Refresh.soon(context)
        }
    }

    /** A tile with [content]; the system asks again once the data is stale. */
    fun tile(content: LayoutElementBuilders.LayoutElement): TileBuilders.Tile =
        TileBuilders.Tile.Builder()
            .setResourcesVersion(RESOURCES_VERSION)
            // The system asks again after this time, so the age stays honest
            // even when no refresh comes through.
            .setFreshnessIntervalMillis(Refresh.STALE_AFTER_MS)
            .setTileTimeline(TimelineBuilders.Timeline.fromLayoutElement(content))
            .build()

    fun resources(): ResourceBuilders.Resources =
        ResourceBuilders.Resources.Builder().setVersion(RESOURCES_VERSION).build()

    fun <T : Any> done(value: T): ListenableFuture<T> =
        CallbackToFutureAdapter.getFuture { completer ->
            completer.set(value)
            "tile"
        }

    /** A centred, padded box around [column]; a tap anywhere opens the app. */
    fun frame(context: Context, column: LayoutElementBuilders.LayoutElement): LayoutElementBuilders.LayoutElement {
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
            .addContent(column)
            .build()
    }

    /** An empty centred column for a tile's rows. */
    fun column(): LayoutElementBuilders.Column.Builder =
        LayoutElementBuilders.Column.Builder()
            .setWidth(expand())
            .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)

    fun text(value: String, size: Float, color: Int, maxLines: Int = 1, bold: Boolean = false): LayoutElementBuilders.Text {
        val style = LayoutElementBuilders.FontStyle.Builder()
            .setSize(sp(size))
            .setColor(argb(color))
        if (bold) style.setWeight(LayoutElementBuilders.FONT_WEIGHT_BOLD)
        return LayoutElementBuilders.Text.Builder()
            .setText(value)
            .setMaxLines(maxLines)
            .setOverflow(LayoutElementBuilders.TEXT_OVERFLOW_ELLIPSIZE)
            .setFontStyle(style.build())
            .build()
    }

    fun spacer(): LayoutElementBuilders.Spacer =
        LayoutElementBuilders.Spacer.Builder().setHeight(dp(4f)).build()

    /** Asks the system to draw both tiles again, after a refresh or a sign-out. */
    fun requestUpdate(context: Context) {
        val updater = TileService.getUpdater(context)
        updater.requestUpdate(GlanceTileService::class.java)
        updater.requestUpdate(StatusTileService::class.java)
    }
}
