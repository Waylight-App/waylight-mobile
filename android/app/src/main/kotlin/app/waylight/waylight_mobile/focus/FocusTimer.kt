package app.waylight.waylight_mobile.focus

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import app.waylight.waylight_mobile.MainActivity
import app.waylight.waylight_mobile.R
import org.json.JSONArray
import org.json.JSONObject

/**
 * The running focus timer (#191). It lives here, not in Flutter, so a phase
 * ends on time with the app closed: an alarm fires at the end, an ongoing
 * notification counts down and offers Pause and Stop. Finished focus
 * phases are kept until the app records them on the server.
 */
object FocusTimer {
    const val FOCUS = "focus"
    const val REST = "rest"
    private const val FOCUS_MS = 25 * 60_000L
    private const val REST_MS = 5 * 60_000L

    private const val PREFS = "waylight_focus"
    private const val KEY_STATE = "state"
    private const val KEY_DONE = "finished"
    private const val CHANNEL_RUNNING = "waylight_focus_running"
    private const val CHANNEL_END = "waylight_focus_end"
    private const val NOTIFICATION_ID = 7301

    data class State(val phase: String, val lengthMs: Long, val endsAt: Long?, val remainingMs: Long?) {
        val paused get() = remainingMs != null

        fun toJson(): JSONObject = JSONObject().put("phase", phase).put("lengthMs", lengthMs)
            .put("endsAt", endsAt ?: JSONObject.NULL).put("remainingMs", remainingMs ?: JSONObject.NULL)
    }

    fun lengthOf(phase: String) = if (phase == REST) REST_MS else FOCUS_MS

    fun state(context: Context): State? {
        val raw = prefs(context).getString(KEY_STATE, null) ?: return null
        return try {
            val o = JSONObject(raw)
            State(
                phase = o.getString("phase"),
                lengthMs = o.getLong("lengthMs"),
                endsAt = if (o.isNull("endsAt")) null else o.getLong("endsAt"),
                remainingMs = if (o.isNull("remainingMs")) null else o.getLong("remainingMs"),
            )
        } catch (e: org.json.JSONException) {
            null
        }
    }

    fun start(context: Context, phase: String, lengthMs: Long = lengthOf(phase)) {
        val state = State(phase, lengthMs, System.currentTimeMillis() + lengthMs, null)
        save(context, state)
        schedule(context, state.endsAt!!)
        showRunning(context, state)
    }

    fun pause(context: Context) {
        val s = state(context) ?: return
        if (s.paused) return
        val left = ((s.endsAt ?: 0) - System.currentTimeMillis()).coerceAtLeast(0)
        val paused = s.copy(endsAt = null, remainingMs = left)
        save(context, paused)
        cancelAlarm(context)
        showRunning(context, paused)
    }

    fun resume(context: Context) {
        val s = state(context) ?: return
        val left = s.remainingMs ?: return
        val running = s.copy(endsAt = System.currentTimeMillis() + left, remainingMs = null)
        save(context, running)
        schedule(context, running.endsAt!!)
        showRunning(context, running)
    }

    fun stop(context: Context) {
        prefs(context).edit().remove(KEY_STATE).apply()
        cancelAlarm(context)
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    /** The alarm fired: the phase is over. A finished focus phase is kept. */
    fun end(context: Context) {
        val s = state(context) ?: return
        if (s.paused) return
        prefs(context).edit().remove(KEY_STATE).apply()
        if (s.phase == FOCUS) addFinished(context, (s.lengthMs / 60_000).toInt(), s.endsAt ?: System.currentTimeMillis())
        showEnded(context, s.phase)
    }

    /** Hands the finished focus phases to the app and forgets them. */
    fun takeFinished(context: Context): JSONArray {
        val raw = prefs(context).getString(KEY_DONE, null) ?: return JSONArray()
        prefs(context).edit().remove(KEY_DONE).apply()
        return try { JSONArray(raw) } catch (e: org.json.JSONException) { JSONArray() }
    }

    /** After a reboot: a running phase gets its alarm again, an overdue one ends. */
    fun restore(context: Context) {
        val s = state(context) ?: return
        val endsAt = s.endsAt ?: return showRunning(context, s)
        if (endsAt <= System.currentTimeMillis()) end(context) else {
            schedule(context, endsAt)
            showRunning(context, s)
        }
    }

    private fun addFinished(context: Context, minutes: Int, endedAt: Long) {
        val list = try { JSONArray(prefs(context).getString(KEY_DONE, "[]")) } catch (e: org.json.JSONException) { JSONArray() }
        list.put(JSONObject().put("minutes", minutes).put("endedAt", endedAt))
        prefs(context).edit().putString(KEY_DONE, list.toString()).apply()
    }

    private fun save(context: Context, state: State) =
        prefs(context).edit().putString(KEY_STATE, state.toJson().toString()).apply()

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun schedule(context: Context, at: Long) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val pending = action(context, FocusReceiver.ACTION_END, 0)
        // A timer must end on time; exact alarms are allowed for it
        // (USE_EXACT_ALARM). Should the system refuse, an inexact one is
        // still close.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()) {
            alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
        }
    }

    private fun cancelAlarm(context: Context) {
        context.getSystemService(AlarmManager::class.java)?.cancel(action(context, FocusReceiver.ACTION_END, 0))
    }

    private fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_RUNNING, context.getString(R.string.focus_channel_running), NotificationManager.IMPORTANCE_LOW),
        )
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_END, context.getString(R.string.focus_channel_end), NotificationManager.IMPORTANCE_HIGH),
        )
    }

    private fun showRunning(context: Context, s: State) {
        createChannels(context)
        val title = context.getString(if (s.phase == REST) R.string.focus_rest_running else R.string.focus_running)
        val builder = NotificationCompat.Builder(context, CHANNEL_RUNNING)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setOngoing(true)
            .setSilent(true)
            .setContentIntent(open(context))
            .addAction(0, context.getString(R.string.focus_stop), action(context, FocusReceiver.ACTION_STOP, 3))
        val endsAt = s.endsAt
        if (endsAt != null) {
            // The system counts down by itself; no updates are needed.
            builder.setWhen(endsAt).setShowWhen(true).setUsesChronometer(true).setChronometerCountDown(true)
                .addAction(0, context.getString(R.string.focus_pause), action(context, FocusReceiver.ACTION_PAUSE, 1))
        } else {
            val left = s.remainingMs ?: 0
            builder.setContentText(context.getString(R.string.focus_paused, left / 60_000, (left / 1000) % 60))
                .addAction(0, context.getString(R.string.focus_resume), action(context, FocusReceiver.ACTION_RESUME, 2))
        }
        notify(context, builder)
    }

    private fun showEnded(context: Context, phase: String) {
        createChannels(context)
        val focusDone = phase == FOCUS
        val builder = NotificationCompat.Builder(context, CHANNEL_END)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(context.getString(if (focusDone) R.string.focus_done else R.string.focus_rest_done))
            .setAutoCancel(true)
            .setContentIntent(open(context))
            .addAction(
                0,
                context.getString(if (focusDone) R.string.focus_start_rest else R.string.focus_start_focus),
                action(context, if (focusDone) FocusReceiver.ACTION_START_REST else FocusReceiver.ACTION_START_FOCUS, 4),
            )
        notify(context, builder)
    }

    private fun notify(context: Context, builder: NotificationCompat.Builder) {
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return
        try {
            manager.notify(NOTIFICATION_ID, builder.build())
        } catch (e: SecurityException) {
            // The permission was withdrawn in the system settings.
        }
    }

    private fun action(context: Context, action: String, code: Int): PendingIntent = PendingIntent.getBroadcast(
        context,
        NOTIFICATION_ID + code,
        Intent(context, FocusReceiver::class.java).setAction(action),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun open(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("waylight://")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(context, NOTIFICATION_ID, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
}
