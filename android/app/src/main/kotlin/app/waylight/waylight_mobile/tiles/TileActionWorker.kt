package app.waylight.waylight_mobile.tiles

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Runs a tile's action while the app may be closed (#192): `quickTileAction`
 * of lib/main.dart in a headless engine, with the app's repositories and
 * session, until it reports `finished`.
 */
class TileActionWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val tile = inputData.getString(KEY_TILE) ?: return Result.failure()
        val main = Handler(Looper.getMainLooper())
        val finished = CountDownLatch(1)
        var engine: FlutterEngine? = null
        main.post {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)
            val e = FlutterEngine(applicationContext)
            engine = e
            TilesChannel.register(applicationContext, e.dartExecutor.binaryMessenger) { finished.countDown() }
            e.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "quickTileAction"),
                listOf(tile),
            )
        }
        val done = finished.await(TIMEOUT_SECONDS, TimeUnit.SECONDS)
        main.post { engine?.destroy() }
        QuickTiles.redraw(applicationContext, tile)
        return if (done) Result.success() else Result.failure()
    }

    companion object {
        private const val KEY_TILE = "tile"
        private const val TIMEOUT_SECONDS = 30L

        /** Runs the action of [tile]; a second tap while it runs is ignored. */
        fun start(context: Context, tile: String) {
            val request = OneTimeWorkRequestBuilder<TileActionWorker>()
                .setInputData(workDataOf(KEY_TILE to tile))
                .build()
            WorkManager.getInstance(context).enqueueUniqueWork("tile-$tile", ExistingWorkPolicy.KEEP, request)
        }
    }
}
