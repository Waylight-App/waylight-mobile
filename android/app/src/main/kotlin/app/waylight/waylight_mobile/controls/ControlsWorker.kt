package app.waylight.waylight_mobile.controls

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
 * Reads or changes the device controls while the app may be closed
 * (#194): `deviceControlsAction` of lib/main.dart in a headless engine,
 * with the app's repositories and session, until it reports `finished`.
 */
class ControlsWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val args = inputData.getStringArray(KEY_ARGS)?.toList() ?: return Result.failure()
        val main = Handler(Looper.getMainLooper())
        val finished = CountDownLatch(1)
        var engine: FlutterEngine? = null
        main.post {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)
            val e = FlutterEngine(applicationContext)
            engine = e
            ControlsChannel.register(applicationContext, e.dartExecutor.binaryMessenger) { finished.countDown() }
            e.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "deviceControlsAction"),
                args,
            )
        }
        val done = finished.await(TIMEOUT_SECONDS, TimeUnit.SECONDS)
        main.post { engine?.destroy() }
        return if (done) Result.success() else Result.failure()
    }

    companion object {
        private const val KEY_ARGS = "args"
        private const val TIMEOUT_SECONDS = 30L

        /** Reads every state again; a second request while one runs is ignored. */
        fun refresh(context: Context) = enqueue(context, "controls-refresh", arrayOf("refresh"), ExistingWorkPolicy.KEEP)

        /**
         * Switches or presses [id]. Actions queue behind each other, so
         * two quick taps reach the server in order.
         */
        fun act(context: Context, id: String) =
            enqueue(context, "controls-act", arrayOf("act", id), ExistingWorkPolicy.APPEND_OR_REPLACE)

        private fun enqueue(context: Context, name: String, args: Array<String>, policy: ExistingWorkPolicy) {
            val request = OneTimeWorkRequestBuilder<ControlsWorker>()
                .setInputData(workDataOf(KEY_ARGS to args))
                .build()
            WorkManager.getInstance(context).enqueueUniqueWork(name, policy, request)
        }
    }
}
