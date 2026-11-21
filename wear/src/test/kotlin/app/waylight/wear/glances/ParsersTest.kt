package app.waylight.wear.glances

import java.time.Instant
import java.time.ZoneId
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ParsersTest {
    private val zone = ZoneId.of("Europe/Berlin")
    private val now = Instant.parse("2026-11-21T10:00:00Z") // 11:00 in Berlin

    @Test
    fun `reads a compact state`() {
        val json = """{"title":{"key":"todos.open","text":"3 open","params":{"n":"3"}},"detail":{"key":"x","text":"1 overdue"},"level":"attention","count":3,"updatedAt":"2026-11-21T10:00:00Z"}"""
        assertEquals(
            CompactGlance("todos", GlanceText("3 open", "todos.open", mapOf("n" to "3")), GlanceText("1 overdue", "x"), Level.ATTENTION, 3),
            Parsers.compact("todos", json),
        )
        assertEquals(
            CompactGlance("focus", GlanceText("Idle", "k"), null, Level.NONE, null),
            Parsers.compact("focus", """{"title":{"key":"k","text":"Idle"},"level":"none","updatedAt":"x"}"""),
        )
    }

    @Test
    fun `finds the first open to-do`() {
        val json = """[{"id":"1","title":"Done","done":true},{"id":"2","title":"Milk","due":"2026-11-22","done":false,"version":3}]"""
        assertEquals(OpenTodo("2", "Milk", "2026-11-22", 3), Parsers.firstOpenTodo(json))
        assertNull(Parsers.firstOpenTodo("""[{"id":"1","done":true}]"""))
    }

    @Test
    fun `keeps only switchable devices`() {
        val json = """[
            {"id":"sensor.t","name":"Temperature","state":"21","action":""},
            {"id":"switch.coffee","name":"Coffee","state":"off","action":"toggle"},
            {"id":"button.door","name":"","state":"","action":"press"}
        ]"""
        assertEquals(
            listOf(
                Device("switch.coffee", "Coffee", "off", DeviceAction.TOGGLE),
                Device("button.door", "button.door", "", DeviceAction.PRESS),
            ),
            Parsers.devices(json),
        )
        assertEquals(1, Parsers.devices(json, limit = 1).size)
    }

    @Test
    fun `counts open to-dos`() {
        assertEquals(2, Parsers.openTodos("""[{"done":false},{"done":true},{"done":false}]"""))
    }

    @Test
    fun `reads my presence`() {
        assertEquals(Presence.HOME, Parsers.presence("""{"people":[],"counts":{},"mine":{"accountId":"a","name":"A","status":"home"}}"""))
        assertEquals(Presence.NONE, Parsers.presence("""{"people":[],"counts":{},"mine":{"accountId":"a","name":"A","status":""}}"""))
        assertNull(Parsers.presence("""{"people":[],"counts":{}}"""))
    }

    @Test
    fun `reads the enabled modules`() {
        assertEquals(setOf("todos", "calendar"), Parsers.modules("""{"modules":["todos","calendar"],"widgetKinds":[]}"""))
    }

    @Test
    fun `reads the modules with a compact state`() {
        val json = """{"modules":["services","smarthome"],"compact":[
            {"module":"services","path":"/api/services/compact","params":[]},
            {"module":"smarthome","path":"/api/smarthome/compact","params":["entity"]},
            {"module":"evil","path":"https://example.com/x","params":[]},
            {"module":"","path":"/api/x/compact"}
        ]}"""
        assertEquals(
            listOf(
                CompactEndpoint("services", "/api/services/compact"),
                CompactEndpoint("smarthome", "/api/smarthome/compact", listOf("entity")),
            ),
            Parsers.compactEndpoints(json),
        )
        // Servers from before the list (server #634).
        assertNull(Parsers.compactEndpoints("""{"modules":["todos"]}"""))
    }

    @Test
    fun `reads an empty compact state`() {
        val glance = Parsers.compact("calendar", """{"title":{"key":"k","text":"No calendar set up"},"level":"none","empty":true}""")
        assertEquals(true, glance.empty)
    }

    @Test
    fun `the next event is the earliest timed one that has not ended`() {
        val json = """{"events":[
            {"summary":"Holiday","start":"2026-11-21","end":"2026-11-22","allDay":true},
            {"summary":"Later","start":"2026-11-21T15:00:00+01:00","end":"2026-11-21T16:00:00+01:00"},
            {"summary":"Over","start":"2026-11-21T08:00:00+01:00","end":"2026-11-21T09:00:00+01:00"},
            {"summary":"Running","start":"2026-11-21T10:30:00+01:00","end":"2026-11-21T11:30:00+01:00"}
        ]}"""
        val event = Parsers.nextEvent(json, now, zone)
        assertEquals("Running", event?.summary)
        assertEquals(Instant.parse("2026-11-21T09:30:00Z").toEpochMilli(), event?.startMillis)
    }

    @Test
    fun `all-day events count when nothing timed is left`() {
        val json = """{"events":[{"summary":"Holiday","start":"2026-11-21","end":"2026-11-22","allDay":true}]}"""
        val event = Parsers.nextEvent(json, now, zone)
        assertEquals(NextEvent("Holiday", Instant.parse("2026-11-20T23:00:00Z").toEpochMilli(), true), event)
        assertNull(Parsers.nextEvent("""{"events":[]}""", now, zone))
        assertNull(Parsers.nextEvent("""{"error":"x"}""", now, zone))
    }
}
