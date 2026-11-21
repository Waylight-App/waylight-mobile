package app.waylight.wear.pairing

import java.io.ByteArrayInputStream
import org.junit.Assert.assertEquals
import org.junit.Test

class HandoverServerTest {
    private fun read(request: String) =
        HandoverServer.readRequest(ByteArrayInputStream(request.toByteArray(Charsets.ISO_8859_1)))

    @Test
    fun `reads the body of POST pair`() {
        val request = read("POST /pair HTTP/1.1\r\nHost: x\r\nContent-Length: 5\r\n\r\nhello")
        assertEquals(HandoverRequest.Pair("hello"), request)
    }

    @Test
    fun `accepts bare line feeds and any header case`() {
        assertEquals(HandoverRequest.Pair("ab"), read("POST /pair HTTP/1.0\ncontent-length: 2\n\nab"))
    }

    @Test
    fun `other paths and methods are not found`() {
        assertEquals(HandoverRequest.NotFound, read("GET /pair HTTP/1.1\r\n\r\n"))
        assertEquals(HandoverRequest.NotFound, read("POST /other HTTP/1.1\r\nContent-Length: 1\r\n\r\nx"))
    }

    @Test
    fun `refuses broken, empty and oversized requests`() {
        assertEquals(HandoverRequest.Bad, read("hello"))
        assertEquals(HandoverRequest.Bad, read("POST /pair HTTP/1.1\r\n\r\n"))
        assertEquals(HandoverRequest.Bad, read("POST /pair HTTP/1.1\r\nContent-Length: 10\r\n\r\nshort"))
        assertEquals(HandoverRequest.Bad, read("POST /pair HTTP/1.1\r\nContent-Length: 999999\r\n\r\n"))
        assertEquals(HandoverRequest.Bad, read("POST /pair HTTP/1.1\r\n" + "X: " + "a".repeat(9000) + "\r\n\r\n"))
    }
}
