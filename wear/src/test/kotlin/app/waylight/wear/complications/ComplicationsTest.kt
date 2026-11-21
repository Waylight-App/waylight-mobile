package app.waylight.wear.complications

import app.waylight.wear.glances.CompactGlance
import app.waylight.wear.glances.GlanceText
import app.waylight.wear.glances.Level
import app.waylight.wear.glances.Snapshot
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ComplicationsTest {
    @Test
    fun `counts open to-dos from the compact state`() {
        val todos = CompactGlance("todos", GlanceText("3 open"), null, Level.OK, 3)
        val habits = CompactGlance("habits", GlanceText("1 of 2 today"), null, Level.NONE, 1)
        assertEquals(3, Complications.openTodos(Snapshot(0, null, null, listOf(habits, todos))))
        assertNull(Complications.openTodos(Snapshot(0, null, null, listOf(habits))))
        assertNull(Complications.openTodos(null))
    }

    @Test
    fun `shortens titles for small slots`() {
        assertEquals("Standup", Complications.shorten("Standup", 7))
        assertEquals("Weekly…", Complications.shorten("Weekly review", 7))
        assertEquals("Big…", Complications.shorten("Big  meeting", 5))
    }
}
