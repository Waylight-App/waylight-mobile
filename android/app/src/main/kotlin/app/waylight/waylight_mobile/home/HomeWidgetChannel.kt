package app.waylight.waylight_mobile.home

import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

/**
 * The native side of `app.waylight/home` (#42, #48): stores the cards the
 * app formats, redraws the widgets and schedules the refresh in the
 * background.
 */
object HomeWidgetChannel {
    private const val NAME = "app.waylight/home"
    private const val WORK = "home-widgets-refresh"

    /**
     * Answers the app's calls on [messenger]; [onDone] is called when the
     * background refresh reports `done`.
     */
    fun register(context: Context, messenger: BinaryMessenger, onDone: (() -> Unit)? = null) {
        val app = context.applicationContext
        MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "save" -> {
                    val kind = call.argument<String>("kind")
                    val card = call.argument<String>("card")
                    if (kind == null || card == null) {
                        result.error("bad-args", "kind and card are required", null)
                    } else {
                        HomeWidgetStore.save(app, kind, card)
                        result.success(null)
                    }
                }
                "clear" -> {
                    HomeWidgetStore.clear(app)
                    result.success(null)
                }
                "schedule" -> {
                    schedule(app, call.argument<Boolean>("enabled") == true)
                    result.success(null)
                }
                "done" -> {
                    result.success(null)
                    onDone?.invoke()
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Refreshes every 30 minutes, the shortest sensible interval for a home
     * screen (WorkManager allows 15). Only with network and enough battery.
     */
    private fun schedule(context: Context, enabled: Boolean) {
        val work = WorkManager.getInstance(context)
        if (!enabled) {
            work.cancelUniqueWork(WORK)
            return
        }
        val request = PeriodicWorkRequestBuilder<RefreshWorker>(30, TimeUnit.MINUTES)
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .setRequiresBatteryNotLow(true)
                    .build(),
            )
            .build()
        work.enqueueUniquePeriodicWork(WORK, ExistingPeriodicWorkPolicy.KEEP, request)
    }
}
