package com.taeskim.setpad

import android.app.Activity
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.ToneGenerator
import android.speech.tts.TextToSpeech
import android.view.WindowManager
import java.util.Locale
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.sin

class TimingBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "setpad/timing")
    private var track: AudioTrack? = null
    private var tempo: Int? = null
    private var tone: ToneGenerator? = null
    private var speech: TextToSpeech? = null
    private var speechReady = false

    /// 세는 말. 앞의 말이 아직 나오는 중이면 그 박자는 건너뛴다 — 빠른 박자에서는
    /// 말이 박자 간격보다 길어서 겹치면 뭉개진다.
    private fun speak(text: String, locale: String) {
        if (text.isEmpty()) return
        val engine = speech ?: TextToSpeech(activity) { status ->
            speechReady = status == TextToSpeech.SUCCESS
        }.also { speech = it }
        if (!speechReady || engine.isSpeaking) return
        runCatching { engine.language = Locale.forLanguageTag(locale) }
        engine.setSpeechRate(1.15f)
        engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, "count")
    }

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method == "speak") {
                runCatching {
                    speak(call.argument<String>("text") ?: "", call.argument<String>("locale") ?: "en")
                }
                result.success(null)
            }
            else if (call.method != "configure") { result.notImplemented() }
            else try {
                val active = call.argument<Boolean>("active") == true
                val bpm = if (active) call.argument<Int>("bpm")?.takeIf { it in 20..300 } else null
                if (active) activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                else activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                if (bpm != tempo) {
                    stopBeat()
                    if (bpm != null) {
                        val rate = 22050
                        val samples = ShortArray((60.0 / bpm * rate).toInt()) { i ->
                            val duration = (rate * 0.035).toInt()
                            val envelope = if (i < duration) minOf(1.0, i / 40.0) * (1.0 - i.toDouble() / duration) else 0.0
                            (sin(i * 1100.0 * 2 * PI / rate) * envelope * 10000).toInt().toShort()
                        }
                        val player = AudioTrack.Builder()
                            .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
                            .setAudioFormat(AudioFormat.Builder().setSampleRate(rate).setEncoding(AudioFormat.ENCODING_PCM_16BIT).setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
                            .setTransferMode(AudioTrack.MODE_STATIC).setBufferSizeInBytes(samples.size * 2).build()
                        track = player
                        check(player.write(samples, 0, samples.size) == samples.size)
                        check(player.setLoopPoints(0, samples.size, -1) == AudioTrack.SUCCESS)
                        player.play(); tempo = bpm
                    }
                }
                val cue = call.argument<String>("cue")
                if (cue != null) {
                    val generator = tone ?: ToneGenerator(AudioManager.STREAM_MUSIC, 55).also { tone = it }
                    generator.startTone(if (cue == "rest") ToneGenerator.TONE_PROP_NACK else ToneGenerator.TONE_PROP_BEEP, if (cue == "complete") 400 else 100)
                } else if (!active) { tone?.release(); tone = null }
                result.success(null)
            } catch (_: Exception) { stop(); result.error("audioUnavailable", null, null) }
        }
    }
    private fun stopBeat() { track?.let { runCatching { it.stop() }; it.release() }; track = null; tempo = null }
    private fun stop() { stopBeat(); runCatching { speech?.stop() }; tone?.release(); tone = null; activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON) }
    fun interrupt() { stop(); channel.invokeMethod("interrupted", null) }
    fun close() { stop(); speech?.shutdown(); speech = null; speechReady = false; channel.setMethodCallHandler(null) }
}
