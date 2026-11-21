package app.waylight.waylight_mobile.reminders

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import app.waylight.waylight_mobile.R
import org.json.JSONArray
import org.json.JSONObject

/** One reminder as the Dart side plans it (#190). */
data class Reminder(
    val id: Int,
    val at: Long,
    val kind: String,
    val title: String,
    val body: String,
    val link: String,
) {
    fun toJson(): JSONObject = JSONObject()
        .put("id", id).put("at", at).put("kind", kind)
        .put("title", title).put("body", body).put("link", link)

    companion object {
        fun fromJson(o: JSONObject) = Reminder(
            id = o.getInt("id"),
            at = o.getLong("at"),
            kind = o.optString("kind", KIND_TODO),
            title = o.optString("title"),
            body = o.optString("body"),
            link = o.optString("link", "waylight://"),
        )
    }
}

const val KIND_TODO = "todo"
const val KIND_EVENT = "event"
const val KIND_BIRTHDAY = "birthday"

/**
 * Schedules reminders with inexact alarms (#190): `setAndAllowWhileIdle`
 * fires close to the time, also in Doze, and needs no exact-alarm
 * permission. The planned list is kept, so a reboot can schedule it again
 * without the app or the network.
 */
object Reminders {
    private const val PREFS = "waylight_reminders"
    private const val KEY = "planned"

    /** Replaces every scheduled reminder with [reminders]. */
    fun replaceAll(context: Context, reminders: List<Reminder>) {
        cancel(context, load(context))
        store(context, reminders)
        schedule(context, reminders)
    }

    /** Cancels everything, e.g. on sign-out. */
    fun cancelAll(context: Context) = replaceAll(context, emptyList())

    /** Schedules the kept list again, after a reboot or an app update. */
    fun restore(context: Context) = schedule(context, load(context))

    /** The kept reminder with [id], to show when its alarm fires. */
    fun find(context: Context, id: Int): Reminder? = load(context).firstOrNull { it.id == id }

    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        // One channel per kind, so people can tune each in the system settings.
        for ((kind, name) in listOf(
            KIND_TODO to R.string.reminders_channel_todos,
            KIND_EVENT to R.string.reminders_channel_events,
            KIND_BIRTHDAY to R.string.reminders_channel_birthdays,
        )) {
            manager.createNotificationChannel(
                NotificationChannel(channelOf(kind), context.getString(name), NotificationManager.IMPORTANCE_DEFAULT),
            )
        }
    }

    fun channelOf(kind: String) = "waylight_reminders_$kind"

    private fun schedule(context: Context, reminders: List<Reminder>) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val now = System.currentTimeMillis()
        for (r in reminders) {
            if (r.at <= now) continue
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, r.at, pending(context, r.id))
        }
    }

    private fun cancel(context: Context, reminders: List<Reminder>) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        for (r in reminders) alarms.cancel(pending(context, r.id))
    }

    private fun pending(context: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(
        context,
        id,
        Intent(context, ReminderReceiver::class.java).putExtra(ReminderReceiver.EXTRA_ID, id),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun load(context: Context): List<Reminder> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { Reminder.fromJson(array.getJSONObject(it)) }
        } catch (e: org.json.JSONException) {
            emptyList()
        }
    }

    private fun store(context: Context, reminders: List<Reminder>) {
        val array = JSONArray().apply { reminders.forEach { put(it.toJson()) } }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, array.toString()).apply()
    }
}
