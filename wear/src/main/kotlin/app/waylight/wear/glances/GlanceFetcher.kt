package app.waylight.wear.glances

import app.waylight.wear.data.ApiException
import app.waylight.wear.data.WaylightApi
import java.time.Instant
import java.time.ZoneId
import org.json.JSONException

/**
 * Fetches a [Snapshot] from the server. Throws [ApiException] with 401 when
 * the session has ended and an `IOException` when the server cannot be
 * reached; a module that is off, missing or broken is only left out.
 */
class GlanceFetcher(private val api: WaylightApi) {
    fun fetch(now: Instant, zone: ZoneId): Snapshot {
        val modules = optional { Parsers.modules(api.get("/api/modules")) }
        // Without the list (older servers), every module is tried.
        fun enabled(module: String) = modules == null || module in modules

        val nextEvent = if (enabled("calendar")) {
            optional { Parsers.nextEvent(api.get("/api/calendar/events?days=7"), now, zone) }
        } else {
            null
        }
        val presence = optional { Parsers.presence(api.get("/api/presence")) }
        // The list gives the to-do to tick off (#245) and the count for
        // servers without the compact state.
        val todos = if (enabled("todos")) optional { api.get("/api/todos") } else null
        val compact = COMPACT_MODULES.filter(::enabled).mapNotNull { module ->
            optional { Parsers.compact(module, api.get("/api/$module/compact")) }
                ?: if (module == "todos" && todos != null) optional { todosFallback(todos) } else null
        }
        val firstTodo = todos?.let { optional { Parsers.firstOpenTodo(it) } }
        val devices = if (enabled("smarthome")) {
            optional { Parsers.devices(api.get("/api/smarthome/entities")) }.orEmpty()
        } else {
            emptyList()
        }
        return Snapshot(now.toEpochMilli(), nextEvent, presence, compact, firstTodo, devices)
    }

    // Servers from before the compact states (server #597) still list the
    // to-dos; the title is then left to the watch's own translation.
    private fun todosFallback(todos: String): CompactGlance {
        val open = Parsers.openTodos(todos)
        return CompactGlance("todos", title = GlanceText(""), detail = null, level = Level.NONE, count = open)
    }

    /** [block]'s result, or `null` when the server refuses it or answers garbage. */
    private fun <T> optional(block: () -> T): T? = try {
        block()
    } catch (e: ApiException) {
        if (e.status == 401) throw e
        null
    } catch (e: JSONException) {
        null
    }

    companion object {
        /**
         * Modules with a compact state (server #597), in display order. The
         * server does not list them yet, so new ones are added here.
         */
        val COMPACT_MODULES = listOf("todos", "habits", "focus")
    }
}
