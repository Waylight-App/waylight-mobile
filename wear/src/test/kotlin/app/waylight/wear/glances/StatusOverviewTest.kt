package app.waylight.wear.glances

import org.junit.Assert.assertEquals
import org.junit.Test

class StatusOverviewTest {
    private fun glance(module: String, level: Level, empty: Boolean = false) =
        CompactGlance(module, GlanceText(module), null, level, null, empty = empty)

    @Test
    fun `problems come first, then attention, in the server's order`() {
        val compact = listOf(
            glance("todos", Level.NONE),
            glance("services", Level.OK),
            glance("backupmonitor", Level.ATTENTION),
            glance("diskhealth", Level.PROBLEM),
            glance("docker", Level.ATTENTION),
        )
        assertEquals(
            listOf("diskhealth", "backupmonitor", "docker"),
            StatusOverview.rows(compact).map { it.module },
        )
        assertEquals(3, StatusOverview.needingLook(compact))
    }

    @Test
    fun `leaves out modules with nothing to show`() {
        val compact = listOf(
            glance("calendar", Level.PROBLEM, empty = true),
            glance("services", Level.OK),
            glance("speedtest", Level.NONE),
        )
        assertEquals(listOf("services", "speedtest"), StatusOverview.rows(compact).map { it.module })
        assertEquals(0, StatusOverview.needingLook(compact))
    }
}
