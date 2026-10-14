package org.opensmarthome.open_smart_home

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

// FlutterFragmentActivity: required by local_auth (biometric prompt).
class MainActivity : FlutterFragmentActivity() {
    private var nsd: NsdDiscoveryHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val handler = NsdDiscoveryHandler(applicationContext)
        nsd = handler
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "org.opensmarthome/nsd")
            .setStreamHandler(handler)
    }

    // Dart may not get to cancel the stream when the activity goes away.
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        nsd?.stop()
        nsd = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
