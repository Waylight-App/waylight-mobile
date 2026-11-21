package app.waylight.wear.glances

import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.wear.tiles.TileService
import app.waylight.wear.complications.Complications
import app.waylight.wear.data.ApiException
import app.waylight.wear.data.SessionStore
import app.waylight.wear.data.WaylightApi
import app.waylight.wear.tile.GlanceTileService
import java.io.IOException
import java.time.Instant
import java.time.ZoneId
import java.util.concurrent.TimeUnit

/** The outcome of a refresh. */
enum class RefreshResult { UPDATED, OFFLINE, SIGNED_OUT }

/** Fetches, stores and redraws; shared by the app and the background job. */
object Refresh {
    /** Blocks; call it off the main thread. */
    fun run(context: Context): RefreshResult {
        val sessions = SessionStore(context)
        val session = sessions.load() ?: return RefreshResult.SIGNED_OUT
        val result = try {
            val snapshot = GlanceFetcher(WaylightApi(session.server, session.token)).fetch(Instant.now(), ZoneId.systemDefault())
            GlanceStore(context).save(snapshot)
            RefreshResult.UPDATED
        } catch (e: ApiException) {
            if (e.status == 401) {
                // The session was revoked or ran out on the server; the
                // watch has to be paired again.
                signOutLocally(context)
                RefreshResult.SIGNED_OUT
            } else {
                RefreshResult.OFFLINE
            }
        } catch (e: IOException) {
            RefreshResult.OFFLINE
        }
        TileService.getUpdater(context).requestUpdate(GlanceTileService::class.java)
        Complications.requestUpdate(context)
        return result
    }

    /** Forgets the session, the glances and the background job. */
    fun signOutLocally(context: Context) {
        SessionStore(context).clear()
        GlanceStore(context).clear()
        val work = WorkManager.getInstance(context)
        work.cancelUniqueWork(PERIODIC)
        work.cancelUniqueWork(NOW)
        TileService.getUpdater(context).requestUpdate(GlanceTileService::class.java)
        Complications.requestUpdate(context)
    }

    /**
     * Refreshes every 30 minutes while a network is there, also when the app
     * is closed; WorkManager keeps the job across restarts.
     */
    fun schedule(context: Context) {
        val request = PeriodicWorkRequestBuilder<RefreshWorker>(INTERVAL_MINUTES, TimeUnit.MINUTES)
            .setConstraints(online)
            .build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(PERIODIC, ExistingPeriodicWorkPolicy.KEEP, request)
    }

    /** One refresh as soon as a network is there; repeated calls collapse. */
    fun soon(context: Context) {
        val request = OneTimeWorkRequestBuilder<RefreshWorker>().setConstraints(online).build()
        WorkManager.getInstance(context).enqueueUniqueWork(NOW, ExistingWorkPolicy.KEEP, request)
    }

    private val online = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

    private const val PERIODIC = "glances"
    private const val NOW = "glances-now"
    private const val INTERVAL_MINUTES = 30L

    /** Data older than this is refreshed when the tile or the app is shown. */
    const val STALE_AFTER_MS = 15 * 60_000L
}

/** The background refresh. */
class RefreshWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result = when (Refresh.run(applicationContext)) {
        RefreshResult.OFFLINE -> Result.retry()
        RefreshResult.UPDATED, RefreshResult.SIGNED_OUT -> Result.success()
    }
}
