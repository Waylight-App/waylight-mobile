package app.waylight.waylight_mobile.tiles

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import app.waylight.waylight_mobile.MainActivity
import app.waylight.waylight_mobile.R

/** What the three tiles share: drawing the stored state and opening links. */
abstract class WaylightTileService : TileService() {
    abstract val kind: String
    abstract val defaultLabel: Int

    override fun onStartListening() {
        super.onStartListening()
        draw()
    }

    protected fun draw(busy: Boolean = false) {
        val tile = qsTile ?: return
        val state = QuickTiles.state(this, kind)
        tile.label = state?.label?.ifEmpty { null } ?: getString(defaultLabel)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = if (busy) "…" else state?.subtitle
        }
        tile.state = when {
            state == null && kind != QuickTiles.CAPTURE -> Tile.STATE_INACTIVE
            state?.active == true -> Tile.STATE_ACTIVE
            else -> Tile.STATE_INACTIVE
        }
        tile.updateTile()
    }

    /** Opens [link] in the app and closes the Quick Settings panel. */
    @SuppressLint("StartActivityAndCollapseDeprecated")
    protected fun open(link: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse(link)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE))
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    /** Runs the tile's action in the background, or opens the app first. */
    protected fun runAction() {
        if (isLocked) {
            // Switching things from the lock screen needs the device unlocked.
            unlockAndRun { runAction() }
            return
        }
        draw(busy = true)
        TileActionWorker.start(this, kind)
    }
}

/** Opens the quick capture of a to-do (#21). */
class CaptureTileService : WaylightTileService() {
    override val kind = QuickTiles.CAPTURE
    override val defaultLabel = R.string.quick_tile_capture

    override fun onClick() = open("waylight://search?q=t%20")
}

/** Switches the smart home entity the user chose in the app's settings. */
class SmartHomeTileService : WaylightTileService() {
    override val kind = QuickTiles.SMART_HOME
    override val defaultLabel = R.string.quick_tile_smart_home

    override fun onClick() {
        if (QuickTiles.choice(this) == null) open("waylight://settings") else runAction()
    }
}

/** Cycles the account's presence status: office, home, away. */
class StatusTileService : WaylightTileService() {
    override val kind = QuickTiles.STATUS
    override val defaultLabel = R.string.quick_tile_status

    override fun onClick() = runAction()
}
