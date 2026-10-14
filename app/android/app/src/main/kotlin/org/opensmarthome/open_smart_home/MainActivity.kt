package org.opensmarthome.open_smart_home

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: required by local_auth (biometric prompt).
class MainActivity : FlutterFragmentActivity() {
    private var nsd: NsdDiscoveryHandler? = null
    private var widget: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val handler = NsdDiscoveryHandler(applicationContext)
        nsd = handler
        EventChannel(messenger, "org.opensmarthome/nsd").setStreamHandler(handler)

        widget = MethodChannel(messenger, "org.opensmarthome/widget").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "setScenes" -> {
                        ScenesWidgetProvider.save(
                            applicationContext,
                            call.argument<String>("scenes") ?: "[]",
                            call.argument<String>("emptyText") ?: "",
                        )
                        result.success(null)
                    }
                    // The widget link that started the app, read once.
                    "initialLink" -> {
                        result.success(widgetLink(intent))
                        intent?.data = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        widgetLink(intent)?.let { widget?.invokeMethod("link", it) }
    }

    // Dart may not get to cancel the stream when the activity goes away.
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        nsd?.stop()
        nsd = null
        widget?.setMethodCallHandler(null)
        widget = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun widgetLink(intent: Intent?): String? =
        intent?.data?.takeIf { it.scheme == "opensmarthome" }?.toString()
}
