package com.melodia.melodia

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.IntentSenderRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.melodia.app/media_store"
    private var currentResult: MethodChannel.Result? = null
    private lateinit var deleteRequestLauncher: ActivityResultLauncher<IntentSenderRequest>

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "deleteMediaStoreFile") {
                val uriString = call.argument<String>("uri")
                if (uriString != null) {
                    currentResult = result // Store the result for launcher callback
                    deleteMediaStoreFile(uriString)
                } else {
                    result.error("INVALID_ARGUMENT", "URI argument is null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        deleteRequestLauncher = registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { result ->
            if (result.resultCode == Activity.RESULT_OK) {
                currentResult?.success(true)
            } else {
                currentResult?.success(false)
            }
            currentResult = null // Clear the stored result
        }
    }

    private fun deleteMediaStoreFile(uriString: String) {
        val uri = Uri.parse(uriString)
        val deleteRequest: PendingIntent = MediaStore.createDeleteRequest(contentResolver, listOf(uri))
        
        val intentSenderRequest = IntentSenderRequest.Builder(deleteRequest).build()
        deleteRequestLauncher.launch(intentSenderRequest)
    }
}
