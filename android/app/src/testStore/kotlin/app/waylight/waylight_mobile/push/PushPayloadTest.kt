package app.waylight.waylight_mobile.push

import java.util.Base64
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** The payload below was sealed by the server's pushproto.Seal for the key. */
class PushPayloadTest {
    private val privateKey = Base64.getDecoder().decode("AQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHyA=")
    private val sealed = Base64.getDecoder().decode(
        "AYtcRHUuPrVHMtVw30E/M3Ak7E2NnESU2aA2JbeGpURFLcbdxObFuR5k0y5gIPRyoh3OhTvg" +
            "07Hr8DN0/CCsJeqqdxgb37dMNwf1KmCC4oxMY76QCGQxtgpiVZ+pCYjPVh+dII/TZf4VCFEr" +
            "h6CHTjIYEM/dVn5HN6+T+oW2o127o8Jt",
    )

    @Test
    fun opensAPayloadSealedByTheServer() {
        val content = PushPayload.open(privateKey, sealed)
        assertEquals("Backup failed", content?.title)
        assertEquals("nas: exit 1", content?.body)
        assertEquals("waylight://open", content?.link)
    }

    @Test
    fun rejectsTamperedPayloads() {
        val tampered = sealed.copyOf().also { it[it.size - 1] = (it[it.size - 1].toInt() xor 1).toByte() }
        assertNull(PushPayload.open(privateKey, tampered))
        assertNull(PushPayload.open(privateKey, ByteArray(5)))
    }
}
