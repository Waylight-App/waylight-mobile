package app.waylight.waylight_mobile.push

import com.google.crypto.tink.subtle.X25519
import org.json.JSONObject
import javax.crypto.Cipher
import javax.crypto.Mac
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/** What a push notification shows, after decryption. */
data class PushContent(val title: String, val body: String, val link: String?)

/**
 * Opens a payload sealed by the server's pushproto package (server ADR
 * 0025): X25519 with the device key, HKDF-SHA256 (empty salt, info
 * "waylight-push-v1") to an AES-256 key, AES-GCM. The payload is
 * version (1) ‖ ephemeral public key (32) ‖ nonce (12) ‖ ciphertext and tag.
 */
object PushPayload {
    private const val VERSION: Byte = 0x01
    private const val INFO = "waylight-push-v1"

    /** The content, or null when the payload is not for this key or damaged. */
    fun open(privateKey: ByteArray, sealed: ByteArray): PushContent? {
        val head = 1 + 32
        if (sealed.size < head + 12 + 16 || sealed[0] != VERSION) return null
        return try {
            val shared = X25519.computeSharedSecret(privateKey, sealed.copyOfRange(1, head))
            val key = hkdfSha256(shared, INFO.toByteArray(), 32)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(128, sealed, head, 12))
            val plain = cipher.doFinal(sealed, head + 12, sealed.size - head - 12)
            val json = JSONObject(String(plain, Charsets.UTF_8))
            PushContent(
                title = json.optString("title"),
                body = json.optString("body"),
                link = json.optString("link").ifEmpty { null },
            )
        } catch (e: Exception) {
            // Wrong key, tampered or malformed: never show it.
            null
        }
    }

    /** HKDF (RFC 5869) with an empty salt, as Go's crypto/hkdf with nil salt. */
    internal fun hkdfSha256(ikm: ByteArray, info: ByteArray, length: Int): ByteArray {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(ByteArray(32), "HmacSHA256"))
        val prk = mac.doFinal(ikm)
        mac.init(SecretKeySpec(prk, "HmacSHA256"))
        val out = ByteArray(length)
        var previous = ByteArray(0)
        var offset = 0
        var counter = 1
        while (offset < length) {
            mac.update(previous)
            mac.update(info)
            mac.update(counter.toByte())
            previous = mac.doFinal()
            val n = minOf(previous.size, length - offset)
            System.arraycopy(previous, 0, out, offset, n)
            offset += n
            counter++
        }
        return out
    }
}
