package org.opensmarthome.open_smart_home.wear

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import org.json.JSONArray

/**
 * The buttons chosen in the phone app (Settings → Appearance → Android Auto
 * and watch) as a list. A tap goes to the phone, which sends it to Home
 * Assistant; the watch knows only labels and on/off.
 */
class MainActivity : Activity(), DataClient.OnDataChangedListener {
    private lateinit var list: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Room for round screens: a generous inset on every side.
        val inset = (resources.displayMetrics.widthPixels * 0.12).toInt()
        list = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(inset, inset, inset, inset)
        }
        setContentView(ScrollView(this).apply { addView(list) })
        render(null)
    }

    override fun onResume() {
        super.onResume()
        Wearable.getDataClient(this).addListener(this)
        load()
        // Ask the phone for fresh states (it may have been asleep).
        send(REFRESH, ByteArray(0))
    }

    override fun onPause() {
        Wearable.getDataClient(this).removeListener(this)
        super.onPause()
    }

    override fun onDataChanged(events: DataEventBuffer) = load()

    private fun load() {
        Wearable.getDataClient(this).dataItems.addOnSuccessListener { items ->
            val json = items.firstOrNull { it.uri.path == BUTTONS }
                ?.let { DataMapItem.fromDataItem(it).dataMap.getString("json") }
            items.release()
            render(json)
        }
    }

    private fun render(json: String?) {
        list.removeAllViews()
        val buttons = runCatching { JSONArray(json ?: "[]") }.getOrDefault(JSONArray())
        var shown = 0
        for (i in 0 until buttons.length()) {
            val item = buttons.optJSONObject(i) ?: continue
            val label = item.optString("label").takeIf { it.isNotEmpty() } ?: continue
            val active = if (item.isNull("active")) null else item.optBoolean("active")
            list.addView(
                Button(this).apply {
                    text = when (active) {
                        true -> getString(R.string.button_on, label)
                        false -> getString(R.string.button_off, label)
                        null -> label
                    }
                    isAllCaps = false
                    setOnClickListener { tap(i, label) }
                },
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ).apply { bottomMargin = 8 },
            )
            shown++
        }
        if (shown == 0) {
            list.addView(
                TextView(this).apply {
                    text = getString(if (json == null) R.string.waiting else R.string.empty)
                    gravity = Gravity.CENTER
                    setTextColor(Color.WHITE)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
                },
            )
        }
        list.visibility = View.VISIBLE
    }

    private fun tap(index: Int, label: String) {
        send(TAP, byteArrayOf(index.toByte())) { ok ->
            Toast.makeText(
                this,
                getString(if (ok) R.string.sent else R.string.no_phone, label),
                Toast.LENGTH_SHORT,
            ).show()
        }
    }

    /** To every connected phone (normally one). */
    private fun send(path: String, data: ByteArray, done: ((Boolean) -> Unit)? = null) {
        Wearable.getNodeClient(this).connectedNodes
            .addOnSuccessListener { nodes ->
                if (nodes.isEmpty()) done?.invoke(false)
                for (node in nodes) {
                    Wearable.getMessageClient(this).sendMessage(node.id, path, data)
                        .addOnSuccessListener { done?.invoke(true) }
                        .addOnFailureListener { done?.invoke(false) }
                }
            }
            .addOnFailureListener { done?.invoke(false) }
    }

    companion object {
        const val BUTTONS = "/osh/buttons"
        const val TAP = "/osh/tap"
        const val REFRESH = "/osh/refresh"
    }
}
