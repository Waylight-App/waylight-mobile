package app.waylight.wear.glances

import org.junit.Assert.assertEquals
import org.junit.Test

class ServerTextsTest {
    /** The server's `kernel.MessageKey`: `srv_` and the FNV-1a 64 hash of the template. */
    private fun messageKey(template: String): String {
        var hash = -0x340d631b7bdddcdbL // 0xcbf29ce484222325, the FNV offset basis
        for (b in template.toByteArray(Charsets.UTF_8)) {
            hash = hash xor (b.toLong() and 0xff)
            hash *= 0x100000001b3L
        }
        return "srv_%016x".format(hash)
    }

    @Test
    fun `knows the keys of the server's compact templates`() {
        // The English templates of the compact states the watch translates;
        // a new one needs a string resource here.
        val templates = listOf(
            "{count} open",
            "Nothing to do",
            "{count} overdue",
            "No habits yet",
            "{done} of {total} today",
            "{minutes} min focus today",
            "{count} sessions",
            "No backups yet",
            "{count} of {total} failed",
            "{name} failed",
            "{count} of {total} overdue",
            "{name} is overdue",
            "Waiting for the first run",
            "{total} backups OK",
            "Backup OK",
            "Last success {time}",
            "No services yet",
            "{online} of {total} running",
            "{name} is down",
            "{count} services down",
            "No drive reports yet",
            "{count} of {total} drives failing",
            "{device} is failing",
            "{count} of {total} drives need a look",
            "{device} has warnings",
            "{total} drives healthy",
            "{healthy} of {total} drives healthy",
            "Some reports are out of date",
            "{running} of {total} running",
            "Docker is not reachable",
            "{count} unhealthy",
            "{count} stopped",
            "No parcels on the way",
            "{count} on the way",
            "{count} with a problem",
            "{count} arriving today",
            "No results yet",
            "Speedtest Tracker is not reachable",
            "{running} of {total} guests running",
            "Proxmox VE is not reachable",
            "{offline} of {total} nodes offline",
            "{online} of {total} peers connected",
            "No peers",
            "The export is out of date",
        )
        assertEquals(templates.map(::messageKey).toSet(), ServerTexts.templates.keys)
    }

    @Test
    fun `fills in the parameters`() {
        assertEquals("2 von 5 heute", ServerTexts.fill("{done} von {total} heute", mapOf("done" to "2", "total" to "5")))
        assertEquals("Nichts zu tun", ServerTexts.fill("Nichts zu tun", emptyMap()))
        assertEquals("{count} offen", ServerTexts.fill("{count} offen", mapOf("other" to "1")))
    }

    @Test
    fun `reads a CompactText`() {
        val json = org.json.JSONObject("""{"key":"k","text":"3 open","params":{"count":"3"}}""")
        val text = GlanceText.fromJson(json)!!
        assertEquals(GlanceText("3 open", "k", mapOf("count" to "3")), text)
        assertEquals(text, GlanceText.fromJson(text.toJson()))
    }
}
