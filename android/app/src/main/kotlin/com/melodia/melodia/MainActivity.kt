package com.melodia.melodia

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.melodia.app/media_store"
    private var pendingResult: MethodChannel.Result? = null
    private lateinit var deleteRequestLauncher: ActivityResultLauncher<IntentSenderRequest>

    // Share the Flutter engine with the AudioService background service.
    // Without this the Activity and the service use separate engines and the
    // service never receives play commands, so it never calls startForeground()
    // and no media notification appears.
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    override fun getCachedEngineId(): String? {
        AudioServicePlugin.getFlutterEngine(this)
        return AudioServicePlugin.getFlutterEngineId()
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // Must be called before super.onCreate() so the engine is cached
        // before FlutterFragmentActivity tries to look it up.
        AudioServicePlugin.getFlutterEngine(this)
        super.onCreate(savedInstanceState)

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
