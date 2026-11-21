package app.waylight.wear.pairing

import java.security.SecureRandom
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class HandoverKeyTest {
    // Bytes 0..31; the test vector's nonce is bytes 0..11.
    private val keyBytes = ByteArray(32) { it.toByte() }
    private val key = HandoverKey(keyBytes)

    /** What the phone app does (ADR 0015). */
    private fun seal(plain: String, with: ByteArray = keyBytes, aad: ByteArray = HandoverKey.AAD): String {
        val nonce = ByteArray(12).also(SecureRandom()::nextBytes)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, SecretKeySpec(with, "AES"), GCMParameterSpec(128, nonce))
        cipher.updateAAD(aad)
        return Base64.getUrlEncoder().withoutPadding().encodeToString(nonce + cipher.doFinal(plain.toByteArray()))
    }

    @Test
    fun `opens what was sealed with its key`() {
        val handover = key.open(seal("""{"server":"http://192.168.178.115:8090","code":"abc"}"""))
        assertEquals(Handover("http://192.168.178.115:8090", "abc"), handover)
    }

    /** A fixed vector for the phone app's implementation (#239). */
    @Test
    fun `opens the shared test vector`() {
        val body = "AAECAwQFBgcICQoLPCClfreTp2mve7XjxZ0IV6z5tg3CVW5KAEnUsiVHMYM0KpbMlvEwtFbHEIntpRIamjwT-Xe1zL5atVd95MV931MrFX4uVcgb4dIf"
        assertEquals(Handover("http://192.168.178.115:8090", "test-code"), key.open(body))
    }

    @Test
    fun `refuses other keys, other data and tampering`() {
        val body = """{"server":"https://h.example","code":"abc"}"""
        assertNull(key.open(seal(body, with = ByteArray(32))))
        assertNull(key.open(seal(body, aad = "other".toByteArray())))
        val sealed = Base64.getUrlDecoder().decode(seal(body))
        sealed[sealed.size - 1] = (sealed[sealed.size - 1].toInt() xor 1).toByte()
        assertNull(key.open(Base64.getUrlEncoder().withoutPadding().encodeToString(sealed)))
    }

    @Test
    fun `refuses malformed bodies`() {
        assertNull(key.open("not base64 !"))
        assertNull(key.open("AAAA"))
        assertNull(key.open(seal("""{"server":"https://h.example"}""")))
        assertNull(key.open(seal("no json")))
    }

    @Test
    fun `the link carries the address and the key`() {
        val link = key.link("192.168.1.23:41234")
        assertTrue(link.startsWith("waylight://watch?addr=192.168.1.23:41234&key="))
        val encoded = link.substringAfter("key=")
        assertEquals(keyBytes.toList(), Base64.getUrlDecoder().decode(encoded).toList())
    }

    @Test
    fun `the key and the handover stay out of strings`() {
        assertEquals("Handover(server=s)", Handover("s", "secret").toString())
    }
}
