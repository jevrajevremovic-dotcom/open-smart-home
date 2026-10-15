package org.opensmarthome.open_smart_home

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import kotlin.math.abs
import kotlin.math.max

/**
 * Microphone loudness for clap detection: sends one number per 20 ms frame
 * (the loudest sample, 0…1). Audio itself is never stored or sent anywhere;
 * the samples are discarded right after the peak is taken.
 */
class AudioLevelHandler(private val context: Context) : EventChannel.StreamHandler {
    private val main = Handler(Looper.getMainLooper())

    @Volatile
    private var running = false
    private var thread: Thread? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            events.error("permission", "microphone permission missing", null)
            return
        }
        stop()
        running = true
        thread = Thread({ capture(events) }, "audio-level").apply {
            isDaemon = true
            start()
        }
    }

    override fun onCancel(arguments: Any?) = stop()

    fun stop() {
        running = false
        thread?.join(500)
        thread = null
    }

    private fun capture(events: EventChannel.EventSink) {
        val rate = 16000
        val frame = rate / 50 // 20 ms
        val record = try {
            AudioRecord(
                // No automatic gain control: claps keep their sharp peak.
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                rate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                max(
                    AudioRecord.getMinBufferSize(
                        rate,
                        AudioFormat.CHANNEL_IN_MONO,
                        AudioFormat.ENCODING_PCM_16BIT,
                    ),
                    frame * 2 * 4,
                ),
            )
        } catch (e: SecurityException) {
            main.post { events.error("permission", "microphone not allowed", null) }
            return
        }
        if (record.state != AudioRecord.STATE_INITIALIZED) {
            record.release()
            main.post { events.error("unavailable", "microphone unavailable", null) }
            return
        }
        val buffer = ShortArray(frame)
        try {
            record.startRecording()
            while (running) {
                val n = record.read(buffer, 0, frame)
                if (n <= 0) continue
                var peak = 0
                for (i in 0 until n) peak = max(peak, abs(buffer[i].toInt()))
                val level = peak / 32768.0
                main.post { if (running) events.success(level) }
            }
        } finally {
            try {
                record.stop()
            } catch (_: IllegalStateException) {
            }
            record.release()
        }
    }
}
