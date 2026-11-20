package app.waylight.waylight_mobile.push

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import com.google.crypto.tink.subtle.X25519
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * The device's X25519 key pair for push messages (ADR 0008, server ADR
 * 0025). The private key is stored encrypted with an AES key of the Android
 * Keystore, which never leaves the secure hardware; Dart only gets the
 * public key.
 */
class DeviceKey(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** The public key, creating the key pair on first use. */
    fun publicKey(): ByteArray = X25519.publicFromPrivate(privateKey() ?: create())

    /** The private key, or null before the first [publicKey]. */
    fun privateKey(): ByteArray? {
        val stored = prefs.getString(KEY, null) ?: return null
        val data = Base64.decode(stored, Base64.NO_WRAP)
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, wrappingKey(), GCMParameterSpec(128, data, 0, IV_LENGTH))
        return cipher.doFinal(data, IV_LENGTH, data.size - IV_LENGTH)
    }

    /** Forgets the key pair; a new one is made when push is turned on again. */
    fun forget() {
        prefs.edit().remove(KEY).apply()
    }

    private fun create(): ByteArray {
        val private = X25519.generatePrivateKey()
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, wrappingKey())
        val sealed = cipher.iv + cipher.doFinal(private)
        prefs.edit().putString(KEY, Base64.encodeToString(sealed, Base64.NO_WRAP)).apply()
        return private
    }

    private fun wrappingKey(): SecretKey {
        val store = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        (store.getKey(ALIAS, null) as SecretKey?)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
        generator.init(
            KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    private companion object {
        const val PREFS = "waylight_push"
        const val KEY = "device_key"
        const val ALIAS = "waylight_push_device_key"
        const val KEYSTORE = "AndroidKeyStore"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val IV_LENGTH = 12
    }
}
