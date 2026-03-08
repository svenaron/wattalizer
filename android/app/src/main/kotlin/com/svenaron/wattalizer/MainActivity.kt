package com.svenaron.wattalizer

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "wattalizer/file_intents"
    private var channel: MethodChannel? = null
    private var pendingFilePath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        )
        channel!!.setMethodCallHandler { call, result ->
            if (call.method == "getPendingFile") {
                result.success(pendingFilePath)
                pendingFilePath = null
            } else {
                result.notImplemented()
            }
        }
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val uri = intent.data ?: return
        if (intent.action != Intent.ACTION_VIEW) return
        val path = resolveFilePath(uri) ?: return
        channel?.invokeMethod("openFile", path)
    }

    private fun handleIntent(intent: Intent?) {
        val uri = intent?.data ?: return
        if (intent.action != Intent.ACTION_VIEW) return
        pendingFilePath = resolveFilePath(uri)
    }

    private fun resolveFilePath(uri: Uri): String? = when (uri.scheme) {
        "file" -> uri.path
        "content" -> copyContentUri(uri)
        else -> null
    }

    private fun copyContentUri(uri: Uri): String? {
        val fileName = queryDisplayName(uri) ?: uri.lastPathSegment ?: return null
        val dest = File(cacheDir, fileName)
        return try {
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(dest).use { output ->
                    input.copyTo(output)
                }
            }
            dest.absolutePath
        } catch (e: Exception) {
            null
        }
    }

    private fun queryDisplayName(uri: Uri): String? = try {
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val col = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (cursor.moveToFirst() && col >= 0) cursor.getString(col) else null
        }
    } catch (e: Exception) {
        null
    }
}
