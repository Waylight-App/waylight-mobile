package app.waylight.wear.data

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.GeneralSecurityException
import java.security.KeyStore
import java.util.Base64
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Keeps the session across restarts. The bearer token is encrypted with an
 * AES key in the Android Keystore, which never leaves the watch's secure
 * hardware; the preferences only hold the ciphertext (ADR 0015).
 */
class SessionStore(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** The stored session, or `null` when there is none or it cannot be read. */
    fun load(): Session? {
        val server = prefs.getString(KEY_SERVER, null)
            ?.let { ServerAddress.parse(it) as? ServerAddress.Parsed.Valid }
            ?.address
            ?: return null
        val sealed = prefs.getString(KEY_TOKEN, null) ?: return null
        val token = try {
            open(sealed)
        } catch (e: GeneralSecurityException) {
            // A key lost with a reset of the keystore cannot be recovered;
            // the watch has to be paired again.
            clear()
            return null
        } catch (e: IllegalArgumentException) {
            clear()
            return null
        }
        return Session(server, token)
    }

    /** Whether a session is stored, without decrypting it (for the tile). */
    fun hasSession(): Boolean = prefs.contains(KEY_TOKEN)

    /** Stores [session], replacing an earlier one. */
    fun save(session: Session) {
        prefs.edit()
            .putString(KEY_SERVER, session.server.url)
            .putString(KEY_TOKEN, seal(session.token))
            .commit()
    }

    /** Deletes the session and its key. */
    fun clear() {
        prefs.edit().clear().commit()
        keyStore().deleteEntry(KEY_ALIAS)
    }

    private fun seal(token: String): String {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val encrypted = cipher.doFinal(token.toByteArray(Charsets.UTF_8))
        val b64 = Base64.getEncoder()
        return b64.encodeToString(cipher.iv) + "." + b64.encodeToString(encrypted)
    }

    private fun open(sealed: String): String {
        val parts = sealed.split('.')
        require(parts.size == 2) { "malformed token" }
        val b64 = Base64.getDecoder()
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(TAG_BITS, b64.decode(parts[0])))
        return String(cipher.doFinal(b64.decode(parts[1])), Charsets.UTF_8)
    }

    private fun keyStore(): KeyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }

    private fun key(): SecretKey {
        (keyStore().getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
        generator.init(
            KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    private companion object {
        const val PREFS = "session"
        const val KEY_SERVER = "server"
        const val KEY_TOKEN = "token"
        const val KEYSTORE = "AndroidKeyStore"
        const val KEY_ALIAS = "waylight-session"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val TAG_BITS = 128
    }
}
