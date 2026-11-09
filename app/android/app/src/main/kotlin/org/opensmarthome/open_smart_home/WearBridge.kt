package org.opensmarthome.open_smart_home

import android.content.Context
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService

/**
 * The watch (Wear OS companion) shows the car buttons. Google Play services
 * passes data only between apps with this id signed with the same key.
 * Only labels and on/off go to the watch; never the server or a token.
 */
object WearBridge {
    const val BUTTONS = "/osh/buttons"
    const val TAP = "/osh/tap"
    const val REFRESH = "/osh/refresh"

    /** The car buttons changed (labels or states): tell the watch. */
    fun publish(context: Context, json: String?) {
        runCatching {
            val request = PutDataMapRequest.create(BUTTONS).apply {
                dataMap.putString("json", json ?: "[]")
            }.asPutDataRequest().setUrgent()
            Wearable.getDataClient(context.applicationContext).putDataItem(request)
        }
    }
}

/** Taps from the watch, handled like a car button. */
class WearListener : WearableListenerService() {
    override fun onMessageReceived(event: MessageEvent) {
        when (event.path) {
            WearBridge.TAP -> {
                val index = event.data.firstOrNull()?.toInt() ?: return
                if (index !in 0 until QuickTiles.CAR_COUNT) return
                QuickTiles.click(this, QuickTiles.CAR_BASE + index)
            }
            // Opening on the watch: start the app so the states are fresh.
            WearBridge.REFRESH -> Engines.ensure(this)
        }
    }
}
