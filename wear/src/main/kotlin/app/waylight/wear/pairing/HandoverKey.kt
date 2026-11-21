package app.waylight.wear.pairing

import java.security.GeneralSecurityException
import java.security.SecureRandom
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec
import org.json.JSONException
import org.json.JSONObject

/** What the phone app hands to the watch: the server and a pairing code. */
data class Handover(val server: String, val code: String) {
    // The code is a credential for a few minutes; keep it out of logs.
    override fun toString(): String = "Handover(server=$server)"
}

/**
 * The one-time key of a handover from the phone (ADR 0015). The watch shows
 * it in the QR code [link]; the phone encrypts its [Handover] with it:
 *
 * - body of `POST http://<addr>/pair`: base64url (no padding) of a 12-byte
 *   nonce followed by the AES-256-GCM ciphertext and its 16-byte tag,
 * - additional data: [AAD],
 * - plaintext: `{"server": "<server address>", "code": "<pairing code>"}`.
 *
 * Nobody else in the network can read the code or forge a handover, because
 * the key only travels through the camera.
 */
class HandoverKey(private val key: ByteArray) {
    init {
        require(key.size == KEY_BYTES) { "the key has $KEY_BYTES bytes" }
    }

    /** The content of the QR code for the listener at [address] (`ip:port`). */
    fun link(address: String): String =
        "waylight://watch?addr=$address&key=${Base64.getUrlEncoder().withoutPadding().encodeToString(key)}"

    /** Decrypts [body]; `null` when it was not sealed with this key or is malformed. */
    fun open(body: String): Handover? {
        val raw = try {
            Base64.getUrlDecoder().decode(body.trim())
        } catch (e: IllegalArgumentException) {
            return null
        }
        if (raw.size < NONCE_BYTES + TAG_BYTES) return null
        val plain = try {
            val cipher = Cipher.getInstance(TRANSFORMATION)
            cipher.init(Cipher.DECRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(TAG_BYTES * 8, raw, 0, NONCE_BYTES))
            cipher.updateAAD(AAD)
            cipher.doFinal(raw, NONCE_BYTES, raw.size - NONCE_BYTES)
        } catch (e: GeneralSecurityException) {
            return null
        }
        return try {
            val json = JSONObject(String(plain, Charsets.UTF_8))
            val server = json.optString("server")
            val code = json.optString("code")
            if (server.isEmpty() || code.isEmpty()) null else Handover(server, code)
        } catch (e: JSONException) {
            null
        }
    }

    companion object {
        /** Binds a ciphertext to this protocol and version. */
        val AAD: ByteArray = "waylight-watch-pair-v1".toByteArray(Charsets.UTF_8)
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val KEY_BYTES = 32
        const val NONCE_BYTES = 12
        const val TAG_BYTES = 16

        /** A fresh random key. */
        fun generate(random: SecureRandom = SecureRandom()): HandoverKey =
            HandoverKey(ByteArray(KEY_BYTES).also(random::nextBytes))
    }
}
