package vn.edu.dut.ctsv.mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val sessionWorker = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val store = SecureSessionStore(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vn.edu.dut.ctsv.mobile/session")
            .setMethodCallHandler { call, result ->
                if (call.method !in setOf("read", "write", "delete")) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                sessionWorker.execute {
                    try {
                        val value: String? = when (call.method) {
                            "read" -> store.read()
                            "write" -> {
                                store.write(call.arguments as String)
                                null
                            }
                            else -> {
                                store.delete()
                                null
                            }
                        }
                        runOnUiThread { result.success(value) }
                    } catch (_: Exception) {
                        // Do not include payloads or platform exception text in the channel error.
                        runOnUiThread {
                            result.error("SESSION_STORAGE_ERROR", "Secure session storage failed", null)
                        }
                    }
                }
            }
    }

    override fun onDestroy() {
        sessionWorker.shutdown()
        super.onDestroy()
    }
}
