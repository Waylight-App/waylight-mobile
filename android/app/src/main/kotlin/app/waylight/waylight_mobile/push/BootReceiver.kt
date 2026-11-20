package app.waylight.waylight_mobile.push

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Starts the push service again after a reboot or an app update, if push is on. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val relevant = intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        if (relevant && PushSettings(context).enabled) PushService.start(context)
    }
}
