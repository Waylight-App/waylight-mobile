package app.waylight.waylight_mobile.push

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import app.waylight.waylight_mobile.focus.FocusTimer
import app.waylight.waylight_mobile.reminders.Reminders

/**
 * After a reboot or an app update: starts the push service again if push
 * is on, schedules the kept reminders again (#190) and the running
 * focus timer's alarm (#191).
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val relevant = intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        if (!relevant) return
        if (PushSettings(context).enabled) PushService.start(context)
        Reminders.restore(context)
        FocusTimer.restore(context)
    }
}
