package app.waylight.waylight_mobile.watch

import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * Seals the server address and pairing code for a Wear OS watch (#239,
 * ADR 0015). The watch's QR code carries a fresh 256-bit key; only the
 * holder of that key can read the handover. The format matches
 * `HandoverKey.open` in `wear/`: a 12-byte random nonce followed by the
 * AES-256-GCM ciphertext and its 128-bit tag, with [AAD] as additional data.
 */
internal object WatchHandover {
    /** Binds the ciphertext to this purpose and format version. */
    val AAD = "waylight-watch-pair-v1".toByteArray(Charsets.US_ASCII)

    const val KEY_BYTES = 32
    const val NONCE_BYTES = 12
    private const val TAG_BITS = 128

    private val random = SecureRandom()

    /**
     * Encrypts [plaintext] with [key]. [nonce] is only set by tests; a nonce
     * must never repeat under one key, which a fresh random one per call
     * guarantees for the single handover a key is used for.
     */
    fun seal(
        key: ByteArray,
        plaintext: ByteArray,
        nonce: ByteArray = ByteArray(NONCE_BYTES).also(random::nextBytes),
    ): ByteArray {
        require(key.size == KEY_BYTES) { "key must be $KEY_BYTES bytes" }
        require(nonce.size == NONCE_BYTES) { "nonce must be $NONCE_BYTES bytes" }
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, SecretKeySpec(key, "AES"), GCMParameterSpec(TAG_BITS, nonce))
        cipher.updateAAD(AAD)
        return nonce + cipher.doFinal(plaintext)
    }
}
