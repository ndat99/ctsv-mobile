package vn.edu.dut.ctsv.mobile

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import android.util.Base64
import java.io.File
import java.io.FileNotFoundException
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import org.json.JSONObject

/** Only the refresh-session payload is persisted, never passwords or access tokens. */
internal class SecureSessionStore(context: Context) {
    private val file = AtomicFile(File(context.noBackupFilesDir, "auth_session_v1"))
    private val alias = "${context.packageName}.refresh_session.v1"

    fun read(): String? {
        val bytes = try {
            file.openRead().use { it.readBytes() }
        } catch (_: FileNotFoundException) {
            return null
        }
        val envelope = JSONObject(String(bytes, Charsets.UTF_8))
        check(envelope.getInt("version") == 1)
        val iv = Base64.decode(envelope.getString("iv"), Base64.NO_WRAP)
        val encrypted = Base64.decode(envelope.getString("data"), Base64.NO_WRAP)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(create = false), GCMParameterSpec(128, iv))
        return String(cipher.doFinal(encrypted), Charsets.UTF_8)
    }

    fun write(value: String) {
        require(value.toByteArray(Charsets.UTF_8).size <= 16384)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        // Android Keystore generates a new random IV for every encryption.
        cipher.init(Cipher.ENCRYPT_MODE, key(create = true))
        val encrypted = cipher.doFinal(value.toByteArray(Charsets.UTF_8))
        val envelope = JSONObject()
            .put("version", 1)
            .put("iv", Base64.encodeToString(cipher.iv, Base64.NO_WRAP))
            .put("data", Base64.encodeToString(encrypted, Base64.NO_WRAP))
            .toString().toByteArray(Charsets.UTF_8)
        val output = file.startWrite()
        try {
            output.write(envelope)
            file.finishWrite(output)
        } catch (error: Exception) {
            file.failWrite(output)
            throw error
        }
    }

    fun delete() {
        file.delete()
        check(!file.baseFile.exists()) { "Session deletion failed" }
        check(!File(file.baseFile.path + ".bak").exists()) { "Session backup deletion failed" }
        check(!File(file.baseFile.path + ".new").exists()) { "Session temporary deletion failed" }
    }

    private fun key(create: Boolean): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        check(create) { "Session key unavailable" }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
            .apply {
                init(
                    KeyGenParameterSpec.Builder(
                        alias,
                        KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
                    )
                        .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                        .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                        .setKeySize(256)
                        .setRandomizedEncryptionRequired(true)
                        .build(),
                )
            }.generateKey()
    }
}
