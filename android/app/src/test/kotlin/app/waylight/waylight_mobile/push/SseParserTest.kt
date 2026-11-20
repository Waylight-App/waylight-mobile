package app.waylight.waylight_mobile.push

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class SseParserTest {
    private fun parse(vararg lines: String): List<SseEvent> {
        val parser = SseParser()
        return lines.mapNotNull { parser.feed(it) }
    }

    @Test
    fun readsEventsWithIdAndData() {
        val events = parse("retry: 5000", "", "id: 7", "data: abc", "", ": ping", "", "id: 8", "data:x", "data: y", "")
        assertEquals(listOf(SseEvent("7", "abc"), SseEvent("8", "x\ny")), events)
    }

    @Test
    fun remembersTheLastIdEvenWithoutData() {
        val parser = SseParser()
        parser.feed("id: 3")
        assertNull(parser.feed(""))
        assertEquals("3", parser.lastId)
    }

    @Test
    fun ignoresUnknownFieldsAndComments() {
        assertEquals(emptyList<SseEvent>(), parse(": hello", "event: other", ""))
    }
}
