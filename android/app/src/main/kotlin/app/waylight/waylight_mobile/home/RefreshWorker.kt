package app.waylight.waylight_mobile.home

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Refreshes the home screen widgets while the app is closed (#48). It runs
 * `backgroundRefresh` of lib/main.dart in a headless Flutter engine, so the
 * data comes through the app's own repositories, and waits until it
 * reports `done`.
 */
class RefreshWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val main = Handler(Looper.getMainLooper())
        val finished = CountDownLatch(1)
        var engine: FlutterEngine? = null
        main.post {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)
            val e = FlutterEngine(applicationContext)
            engine = e
            HomeWidgetChannel.register(applicationContext, e.dartExecutor.binaryMessenger) {
                finished.countDown()
            }
            e.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "backgroundRefresh"),
            )
        }
        val done = finished.await(TIMEOUT_SECONDS, TimeUnit.SECONDS)
        main.post { engine?.destroy() }
        return if (done) Result.success() else Result.retry()
    }

    private companion object {
        const val TIMEOUT_SECONDS = 60L
    }
}
