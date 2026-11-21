package app.waylight.wear.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ServerAddressTest {
    private fun valid(input: String): String =
        (ServerAddress.parse(input) as ServerAddress.Parsed.Valid).address.url

    @Test
    fun `normalises scheme, host and trailing slashes`() {
        assertEquals("https://home.example.org/waylight", valid(" HTTPS://Home.Example.org/waylight// "))
        assertEquals("http://192.168.178.115:8090", valid("http://192.168.178.115:8090/"))
    }

    @Test
    fun `without a scheme private addresses get http and others https`() {
        assertEquals("http://192.168.178.115:8090", valid("192.168.178.115:8090"))
        assertEquals("http://nas.local", valid("nas.local"))
        assertEquals("https://home.example.org", valid("home.example.org"))
    }

    @Test
    fun `plain http outside the home network is insecure`() {
        assertEquals(ServerAddress.Parsed.Insecure, ServerAddress.parse("http://home.example.org"))
        assertEquals(ServerAddress.Parsed.Insecure, ServerAddress.parse("http://8.8.8.8"))
    }

    @Test
    fun `rejects other schemes and extra parts`() {
        for (input in listOf("", "ftp://nas.local", "https://user:pw@home.example.org", "https://h.example?x=1", "https://h.example#f", "https://")) {
            assertEquals(input, ServerAddress.Parsed.Malformed, ServerAddress.parse(input))
        }
    }

    @Test
    fun `knows the private ranges`() {
        for (host in listOf("localhost", "127.0.0.1", "10.1.2.3", "172.16.0.1", "172.31.255.255", "192.168.0.1", "169.254.1.1", "[fd00::1]", "fe80::1", "::1", "box.home.arpa")) {
            assertTrue(host, ServerAddress.isPrivateHost(host))
        }
        for (host in listOf("172.32.0.1", "192.169.0.1", "8.8.8.8", "300.1.1.1", "example.org", "2001:db8::1")) {
            assertFalse(host, ServerAddress.isPrivateHost(host))
        }
    }

    @Test
    fun `resolves paths below the base`() {
        val server = (ServerAddress.parse("https://h.example/w") as ServerAddress.Parsed.Valid).address
        assertEquals("https://h.example/w/api/todos/compact", server.resolve("/api/todos/compact"))
        assertEquals("h.example", server.host)
    }
}
