package app.waylight.waylight_mobile.controls

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.controls.Control
import android.service.controls.ControlsProviderService
import android.service.controls.actions.BooleanAction
import android.service.controls.actions.CommandAction
import android.service.controls.actions.ControlAction
import androidx.annotation.RequiresApi
import java.util.concurrent.Flow
import java.util.function.Consumer

/**
 * The smart home of Waylight in Android's device controls (#194, Android
 * 11+). Every read and every action runs in [ControlsWorker] through the
 * server's smart home endpoints, so the server's allow-list applies; this
 * service only draws what Flutter saved in [DeviceControls].
 */
@RequiresApi(Build.VERSION_CODES.R)
class WaylightControlsService : ControlsProviderService() {
    /** The system's picker: every entity, once the states are read. */
    override fun createPublisherForAllAvailable(): Flow.Publisher<Control> =
        ControlsPublisher(applicationContext, ids = null)

    /** The chosen controls with their states, updated while they are on screen. */
    override fun createPublisherFor(controlIds: List<String>): Flow.Publisher<Control> =
        ControlsPublisher(applicationContext, ids = controlIds)

    override fun performControlAction(controlId: String, action: ControlAction, consumer: Consumer<Int>) {
        val snapshot = DeviceControls.snapshot(applicationContext)
        val entry = snapshot.entries.firstOrNull { it.id == controlId }
        val allowed = when (entry?.type) {
            "toggle" -> action is BooleanAction
            "button" -> action is CommandAction || action is BooleanAction
            else -> false
        }
        if (!snapshot.available || !allowed) {
            consumer.accept(ControlAction.RESPONSE_FAIL)
            return
        }
        consumer.accept(ControlAction.RESPONSE_OK)
        ControlsWorker.act(applicationContext, controlId)
    }
}

/**
 * Emits controls from [DeviceControls] and starts a refresh. With [ids]
 * it stays open and emits the controls again whenever a run saves new
 * states, until the system cancels; without, it emits every known entity
 * as soon as the refresh has ended (or after a timeout) and completes.
 */
@RequiresApi(Build.VERSION_CODES.R)
private class ControlsPublisher(
    private val context: Context,
    private val ids: List<String>?,
) : Flow.Publisher<Control> {
    override fun subscribe(subscriber: Flow.Subscriber<in Control>) {
        val subscription = ControlsSubscription(context, ids, subscriber)
        subscriber.onSubscribe(subscription)
        subscription.start()
    }
}

@RequiresApi(Build.VERSION_CODES.R)
private class ControlsSubscription(
    private val context: Context,
    private val ids: List<String>?,
    private val subscriber: Flow.Subscriber<in Control>,
) : Flow.Subscription, SharedPreferences.OnSharedPreferenceChangeListener {
    private val main = Handler(Looper.getMainLooper())
    private val pending = ArrayDeque<Control>()
    private var demand = 0L
    private var done = false
    private var completing = false
    private val timeout = Runnable { finishPicker() }

    fun start() = main.post {
        DeviceControls.listen(context, this)
        if (ids != null) emitStates()
        ControlsWorker.refresh(context)
        if (ids == null) main.postDelayed(timeout, PICKER_TIMEOUT_MS)
    }

    override fun request(n: Long) {
        main.post {
            if (n <= 0) {
                fail(IllegalArgumentException("request($n)"))
                return@post
            }
            demand = if (Long.MAX_VALUE - demand < n) Long.MAX_VALUE else demand + n
            drain()
        }
    }

    override fun cancel() {
        main.post { stop() }
    }

    override fun onSharedPreferenceChanged(prefs: SharedPreferences?, key: String?) {
        if (done || completing) return
        if (ids == null) finishPicker() else emitStates()
    }

    private fun emitStates() {
        val snapshot = DeviceControls.snapshot(context)
        ids?.forEach { id -> pending.addLast(DeviceControls.stateful(context, id, snapshot)) }
        drain()
    }

    private fun finishPicker() {
        if (done || completing) return
        completing = true
        main.removeCallbacks(timeout)
        DeviceControls.snapshot(context).entries.forEach { pending.addLast(DeviceControls.stateless(context, it)) }
        drain()
    }

    private fun drain() {
        if (done) return
        while (demand > 0 && pending.isNotEmpty()) {
            subscriber.onNext(pending.removeFirst())
            if (demand != Long.MAX_VALUE) demand--
        }
        // The picker's list ends once every control went out.
        if (completing && pending.isEmpty()) {
            stop()
            subscriber.onComplete()
        }
    }

    private fun fail(error: Throwable) {
        stop()
        subscriber.onError(error)
    }

    private fun stop() {
        if (done) return
        done = true
        main.removeCallbacks(timeout)
        DeviceControls.unlisten(context, this)
    }

    companion object {
        private const val PICKER_TIMEOUT_MS = 15_000L
    }
}
