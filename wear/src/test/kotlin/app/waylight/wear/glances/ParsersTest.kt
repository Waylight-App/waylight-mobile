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
        assertEquals(CompactGlance("todos", "3 open", "1 overdue", Level.ATTENTION, 3), Parsers.compact("todos", json))
        assertEquals(
            CompactGlance("focus", "Idle", null, Level.NONE, null),
            Parsers.compact("focus", """{"title":{"key":"k","text":"Idle"},"level":"none","updatedAt":"x"}"""),
        )
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
