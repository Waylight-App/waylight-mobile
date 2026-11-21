package app.waylight.wear.glances

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class SnapshotTest {
    @Test
    fun `survives the round trip through the store`() {
        val snapshot = Snapshot(
            fetchedAt = 1_763_719_200_000,
            nextEvent = NextEvent("Standup", 1_763_720_000_000, allDay = false),
            presence = Presence.OFFICE,
            compact = listOf(
                CompactGlance(
                    "todos",
                    GlanceText("3 open", "srv_fe19a87a4c31a1ac", mapOf("count" to "3")),
                    GlanceText("1 overdue"),
                    Level.ATTENTION,
                    3,
                ),
                CompactGlance(
                    "focus",
                    GlanceText("Idle"),
                    null,
                    Level.NONE,
                    null,
                    GlanceAction("focus.start", GlanceText("Start"), "POST", "/api/focus/start", """{"minutes":25}""", emptyList()),
                ),
                CompactGlance("calendar", GlanceText("No calendar set up"), null, Level.NONE, null, empty = true),
            ),
            firstTodo = OpenTodo("2", "Milk", "", 3),
            devices = listOf(Device("switch.coffee", "Coffee", "off", DeviceAction.TOGGLE)),
        )
        assertEquals(snapshot, Snapshot.fromJson(snapshot.toJson()))
        val empty = Snapshot(5, null, null, emptyList())
        assertEquals(empty, Snapshot.fromJson(empty.toJson()))
    }

    @Test
    fun `reads snapshots stored with English text only`() {
        val old = """{"fetchedAt":5,"compact":[{"module":"habits","title":"1 of 2 today","detail":"x","level":"OK"}]}"""
        val glance = Snapshot.fromJson(old)!!.compact.single()
        assertEquals(GlanceText("1 of 2 today"), glance.title)
        assertEquals(GlanceText("x"), glance.detail)
    }

    @Test
    fun `anything else is no snapshot`() {
        assertNull(Snapshot.fromJson("{}"))
        assertNull(Snapshot.fromJson("garbage"))
    }
}
