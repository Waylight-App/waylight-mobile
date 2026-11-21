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
        val info = optional { api.get("/api/modules") }
        val modules = info?.let { optional { Parsers.modules(it) } }
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
        // The server names its modules with a compact state (#247); older
        // servers get the modules the watch knew before that list.
        val endpoints = info?.let { optional { Parsers.compactEndpoints(it) } }
            ?: DAY_MODULES.filter(::enabled).map { CompactEndpoint(it, "/api/$it/compact") }
        val compact = endpoints.filter { it.params.isEmpty() && it.module !in SHOWN_ELSEWHERE }.mapNotNull { endpoint ->
            optional { Parsers.compact(endpoint.module, api.get(endpoint.path)) }
                ?: if (endpoint.module == "todos" && todos != null) optional { todosFallback(todos) } else null
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
         * The modules of the glances tile, in display order. On servers
         * without the list of compact states (before server #634) these are
         * the only ones the watch fetches.
         */
        val DAY_MODULES = listOf("todos", "habits", "focus")

        /** Modules whose compact state repeats a row of their own (the next event). */
        val SHOWN_ELSEWHERE = setOf("calendar")
    }
}
