package app.waylight.waylight_mobile.push

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.MessageDigest
import java.security.PrivateKey
import java.security.Signature
import java.security.spec.ECGenParameterSpec

/**
 * The device's P-256 key for the relay's stream (server ADR 0027). It is
 * created in the Android Keystore and never leaves it; the relay knows the
 * device by the SHA-256 of its public key.
 */
class StreamKey {
    private val store = KeyStore.getInstance(KEYSTORE).apply { load(null) }

    /** The public key in SubjectPublicKeyInfo form, creating the pair on first use. */
    fun publicKey(): ByteArray {
        if (!store.containsAlias(ALIAS)) create()
        return store.getCertificate(ALIAS).publicKey.encoded
    }

    /** The device token instances send to: base64url SHA-256 of the public key. */
    fun deviceId(): String = encode(MessageDigest.getInstance("SHA-256").digest(publicKey()))

    /** The Authorization header for a stream request at [nowSeconds]. */
    fun authorization(nowSeconds: Long): String {
        val spki = publicKey()
        val signature = Signature.getInstance("SHA256withECDSA").apply {
            initSign(store.getKey(ALIAS, null) as PrivateKey)
            update(signedText(nowSeconds))
        }.sign()
        return "Waylight-Device key=${encode(spki)}, ts=$nowSeconds, sig=${encode(signature)}"
    }

    /** Deletes the key pair; the device gets a new ID when push is turned on again. */
    fun forget() {
        if (store.containsAlias(ALIAS)) store.deleteEntry(ALIAS)
    }

    private fun create() {
        KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, KEYSTORE).apply {
            initialize(
                KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_SIGN)
                    .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
                    .setDigests(KeyProperties.DIGEST_SHA256)
                    .build(),
            )
        }.generateKeyPair()
    }

    companion object {
        private const val KEYSTORE = "AndroidKeyStore"
        private const val ALIAS = "waylight_stream"

        /** The text the relay expects to be signed. */
        fun signedText(nowSeconds: Long): ByteArray = "waylight-stream-v1\n$nowSeconds".toByteArray()

        fun encode(bytes: ByteArray): String = Base64.encodeToString(bytes, Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP)
    }
}
