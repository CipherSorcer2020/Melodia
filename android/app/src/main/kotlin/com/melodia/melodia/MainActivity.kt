package com.melodia.melodia

import android.app.Activity
import android.app.PendingIntent
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.melodia.app/media_store"
    private var pendingResult: MethodChannel.Result? = null
    private lateinit var deleteRequestLauncher: ActivityResultLauncher<IntentSenderRequest>

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Must be registered in onCreate, before onStart
        deleteRequestLauncher = registerForActivityResult(
            ActivityResultContracts.StartIntentSenderForResult()
        ) { activityResult ->
            if (activityResult.resultCode == Activity.RESULT_OK) {
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "deleteMediaStoreFile") {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        pendingResult = result
                        deleteMediaStoreFile(uriString)
                    } else {
                        result.error("INVALID_ARGUMENT", "URI is null", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun deleteMediaStoreFile(uriString: String) {
        val uri = Uri.parse(uriString)
        val deleteRequest: PendingIntent =
            MediaStore.createDeleteRequest(contentResolver, listOf(uri))
        val intentSenderRequest = IntentSenderRequest.Builder(deleteRequest).build()
        deleteRequestLauncher.launch(intentSenderRequest)
    }
}
