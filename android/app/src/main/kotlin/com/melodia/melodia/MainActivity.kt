package com.melodia.melodia

import android.app.Activity
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.IntentSender
import android.net.Uri
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.melodia.app/media_store"
    private val DELETE_REQUEST_CODE = 123
    private var currentResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "deleteMediaStoreFile") {
                val uriString = call.argument<String>("uri")
                if (uriString != null) {
                    currentResult = result // Store the result for onActivityResult
                    deleteMediaStoreFile(uriString)
                } else {
                    result.error("INVALID_ARGUMENT", "URI argument is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun deleteMediaStoreFile(uriString: String) {
        val uri = Uri.parse(uriString)
        val deleteRequest: IntentSender = MediaStore.createDeleteRequest(contentResolver, listOf(uri))

        startIntentSenderForResult(deleteRequest, DELETE_REQUEST_CODE, null, 0, 0, 0, null)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == DELETE_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                currentResult?.success(true)
            } else {
                currentResult?.success(false)
            }
            currentResult = null // Clear the stored result
        }
    }
}

