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
                CompactGlance("todos", "3 open", "1 overdue", Level.ATTENTION, 3),
                CompactGlance("focus", "Idle", null, Level.NONE, null),
            ),
        )
        assertEquals(snapshot, Snapshot.fromJson(snapshot.toJson()))
        val empty = Snapshot(5, null, null, emptyList())
        assertEquals(empty, Snapshot.fromJson(empty.toJson()))
    }

    @Test
    fun `anything else is no snapshot`() {
        assertNull(Snapshot.fromJson("{}"))
        assertNull(Snapshot.fromJson("garbage"))
    }
}
