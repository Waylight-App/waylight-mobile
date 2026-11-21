package app.waylight.wear.glances

import android.content.Context
import android.text.format.DateFormat
import app.waylight.wear.R
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/** Texts of the glances, shared by the app's screen and the tile. */
object GlanceFormat {
    /** "14:30", "Tomorrow 9:00", "Fri 18:00"; all-day events show only the day. */
    fun eventWhen(context: Context, event: NextEvent, now: Instant = Instant.now()): String {
        val zone = ZoneId.systemDefault()
        val locale = Locale.getDefault()
        val start = Instant.ofEpochMilli(event.startMillis).atZone(zone)
        val startDay = start.toLocalDate()
        val today = now.atZone(zone).toLocalDate()
        val tomorrow = today.plusDays(1)
        val weekday = DateTimeFormatter.ofPattern("EEE", locale).format(start)
        if (event.allDay) {
            // An all-day event that began earlier is still running today.
            return when {
                !startDay.isAfter(today) -> context.getString(R.string.today)
                startDay == tomorrow -> context.getString(R.string.tomorrow)
                else -> weekday
            }
        }
        val time = DateTimeFormatter.ofPattern(timePattern(context), locale).format(start)
        return when (startDay) {
            today -> time
            tomorrow -> "${context.getString(R.string.tomorrow)} $time"
            else -> "$weekday $time"
        }
    }

    /** "Updated 14:05", or with the day when the data is older than today. */
    fun updated(context: Context, fetchedAt: Long, now: Instant = Instant.now()): String {
        val zone = ZoneId.systemDefault()
        val at = Instant.ofEpochMilli(fetchedAt).atZone(zone)
        val pattern = timePattern(context)
        val sameDay = at.toLocalDate() == now.atZone(zone).toLocalDate()
        val text = DateTimeFormatter.ofPattern(if (sameDay) pattern else "EEE $pattern", Locale.getDefault()).format(at)
        return context.getString(R.string.updated_at, text)
    }

    private fun timePattern(context: Context): String =
        if (DateFormat.is24HourFormat(context)) "H:mm" else "h:mm a"

    /** The status in words. */
    fun presence(context: Context, presence: Presence): String = context.getString(
        when (presence) {
            Presence.OFFICE -> R.string.presence_office
            Presence.HOME -> R.string.presence_home
            Presence.AWAY -> R.string.presence_away
            Presence.NONE -> R.string.presence_none
        },
    )

    /** The title of a compact state; the watch's own words when the server sent none. */
    fun compactTitle(context: Context, glance: CompactGlance): String = when {
        glance.title.text.isNotEmpty() -> ServerTexts.resolve(context, glance.title)
        glance.module == "todos" -> context.resources.getQuantityString(R.plurals.todos_open, glance.count ?: 0, glance.count ?: 0)
        else -> glance.module
    }

    /** The name of [module] for a label; the module's id when the watch does not know it. */
    fun moduleName(context: Context, module: String): String {
        val id = MODULE_NAMES[module] ?: return module.replaceFirstChar { it.titlecase(Locale.getDefault()) }
        return context.getString(id)
    }

    private val MODULE_NAMES = mapOf(
        "todos" to R.string.module_todos,
        "habits" to R.string.module_habits,
        "focus" to R.string.module_focus,
        "services" to R.string.module_services,
        "backupmonitor" to R.string.module_backupmonitor,
        "diskhealth" to R.string.module_diskhealth,
        "docker" to R.string.module_docker,
        "parcels" to R.string.module_parcels,
        "speedtest" to R.string.module_speedtest,
        "proxmox" to R.string.module_proxmox,
        "wireguard" to R.string.module_wireguard,
    )

    /** The second line of a compact state, if any. */
    fun compactDetail(context: Context, glance: CompactGlance): String? =
        glance.detail?.let { ServerTexts.resolve(context, it) }
}
