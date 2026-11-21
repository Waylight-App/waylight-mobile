package app.waylight.waylight_mobile.focus

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** The focus timer's alarm and notification buttons (#191). */
class FocusReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_END -> FocusTimer.end(context)
            ACTION_PAUSE -> FocusTimer.pause(context)
            ACTION_RESUME -> FocusTimer.resume(context)
            ACTION_STOP -> FocusTimer.stop(context)
            ACTION_START_REST -> FocusTimer.start(context, FocusTimer.REST)
            ACTION_START_FOCUS -> FocusTimer.start(context, FocusTimer.FOCUS)
        }
    }

    companion object {
        const val ACTION_END = "app.waylight.focus.END"
        const val ACTION_PAUSE = "app.waylight.focus.PAUSE"
        const val ACTION_RESUME = "app.waylight.focus.RESUME"
        const val ACTION_STOP = "app.waylight.focus.STOP"
        const val ACTION_START_REST = "app.waylight.focus.START_REST"
        const val ACTION_START_FOCUS = "app.waylight.focus.START_FOCUS"
    }
}
