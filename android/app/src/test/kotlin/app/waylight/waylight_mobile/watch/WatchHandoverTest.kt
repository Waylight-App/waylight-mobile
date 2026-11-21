package app.waylight.waylight_mobile.watch

import java.util.Base64
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

class WatchHandoverTest {
    private val key = ByteArray(32) { it.toByte() }
    private val plaintext = """{"server":"http://192.168.178.115:8090","code":"test-code"}""".toByteArray()

    /** The vector of `wear/src/test/.../pairing/HandoverKeyTest.kt`. */
    @Test
    fun `matches the watch's test vector`() {
        val vector = "AAECAwQFBgcICQoLPCClfreTp2mve7XjxZ0IV6z5tg3CVW5KAEnUsiVHMYM0KpbMlvEwtFbHEIntpRIamjwT-Xe1zL5atVd95MV931MrFX4uVcgb4dIf"
        val sealed = WatchHandover.seal(key, plaintext, nonce = ByteArray(12) { it.toByte() })
        assertArrayEquals(Base64.getUrlDecoder().decode(vector), sealed)
    }

    @Test
    fun `uses a fresh nonce each time`() {
        val a = WatchHandover.seal(key, plaintext)
        val b = WatchHandover.seal(key, plaintext)
        assertNotEquals(a.copyOf(12).toList(), b.copyOf(12).toList())
        assertEquals(12 + plaintext.size + 16, a.size)
    }

    @Test(expected = AEADBadTagException::class)
    fun `binds the ciphertext to the additional data`() {
        val sealed = WatchHandover.seal(key, plaintext)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(128, sealed, 0, 12))
        cipher.updateAAD("other".toByteArray())
        cipher.doFinal(sealed, 12, sealed.size - 12)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `refuses a short key`() {
        WatchHandover.seal(ByteArray(16), plaintext)
    }
}
