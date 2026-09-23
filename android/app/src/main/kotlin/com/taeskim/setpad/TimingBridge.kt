package com.taeskim.setpad

import android.app.Activity
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.speech.tts.TextToSpeech
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.WindowManager
import java.util.Locale
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.sin

class TimingBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "setpad/timing")
    private var track: AudioTrack? = null
    private var tempo: Int? = null
    private var cueTrack: AudioTrack? = null
    // Built once and replayed. Building an AudioTrack per cue put tens of
    // milliseconds between the moment a phase ends and the sound.
    private val beats = mutableMapOf<Int, AudioTrack>()
    private val cues = mutableMapOf<String, AudioTrack>()
    private var speech: TextToSpeech? = null
    private var speechReady = false
    private val handler = Handler(Looper.getMainLooper())
    private var pendingSpeech: Runnable? = null
    private var cueEndsAt = 0L
    private var spokenLocale: String? = null

    private fun prepareSpeech() {
        if (speech == null) speech = TextToSpeech(activity) { status ->
            speechReady = status == TextToSpeech.SUCCESS
        }
    }

    // Match Tempo: read half a beat after the click, capped at one second.
    // The count comes from Dart's clock and the click from this track, which
    // started a little later — near the end of the loop the click this count
    // belongs to has not sounded yet, so wait for it. A newer count replaces one
    // still waiting; if the previous word is still sounding, wait briefly for it
    // instead of dropping this count or cutting that one off.
    private fun speak(text: String, locale: String, rate: Float) {
        val engine = speech ?: return
        if (text.isEmpty() || !speechReady) return
        pendingSpeech?.let { handler.removeCallbacks(it) }; pendingSpeech = null
        val player = track
        val bpm = tempo
        var patience = 150L
        // A Tabata with no BPM still announces its rounds, so there may be no beat to wait for.
        val countRemaining = if (player != null && bpm != null) {
            val frames = (60.0 / bpm * 22050).toInt()
            val period = 60000L / bpm
            val half = minOf(30000L / bpm, 1000L)
            val at = ((player.playbackHeadPosition.toLong() and 0xffffffffL) % frames) * 1000 / 22050
            // No later than a quarter beat after the planned moment: a late word
            // never lands on the next click and lateness cannot pile up.
            patience = period / 4
            if (at > period * 3 / 4) period - at + half else maxOf(0L, half - at)
        } else 0L
        val delay = maxOf(countRemaining, cueEndsAt - SystemClock.elapsedRealtime(), 0L)
        val giveUpAt = SystemClock.elapsedRealtime() + delay + patience
        lateinit var task: Runnable
        task = Runnable {
            if (engine.isSpeaking && SystemClock.elapsedRealtime() < giveUpAt) {
                handler.postDelayed(task, 20); return@Runnable
            }
            pendingSpeech = null
            if (!engine.isSpeaking) {
                // Setting the language is a binder call; only when it changes.
                if (locale != spokenLocale) {
                    runCatching { engine.language = Locale.forLanguageTag(locale) }
                    spokenLocale = locale
                }
                engine.setSpeechRate(rate)
                engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, "count")
            }
        }
        pendingSpeech = task
        handler.postDelayed(task, if (delay > 0) delay + 5 else 0)
    }

    private fun cancelSpeech() {
        pendingSpeech?.let { handler.removeCallbacks(it) }; pendingSpeech = null
        runCatching { speech?.stop() }
    }

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method == "speak") {
                runCatching {
                    speak(call.argument<String>("text") ?: "", call.argument<String>("locale") ?: "en",
                        (call.argument<Double>("rate") ?: 1.15).toFloat())
                }
                result.success(null)
            }
            else if (call.method != "configure") { result.notImplemented() }
            else try {
                val active = call.argument<Boolean>("active") == true
                // The app allows 10 BPM; anything slower than this range is a typo.
                val bpm = if (active) call.argument<Int>("bpm")?.takeIf { it in 10..300 } else null
                if (active) prepareSpeech()
                if (!active) cancelSpeech()
                if (active) activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                else activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                if (bpm != tempo) {
                    // Stopping cuts the voice. A tempo change while running (Tabata
                    // work to rest) only drops a count still waiting: the round's
                    // last number is allowed to finish.
                    if (active) dropPending() else cancelSpeech()
                    stopClick()
                    if (bpm != null) {
                        val player = beats.getOrPut(bpm) {
                            val samples = samples(click, 60.0 / bpm)
                            staticTrack(samples).also {
                                check(it.setLoopPoints(0, samples.size, -1) == AudioTrack.SUCCESS)
                            }
                        }
                        track = player
                        player.reloadStaticData()
                        // Start where the timer is inside its beat, not at a fresh
                        // click: after a pause or a re-sync the clicks stay on the grid.
                        val frames = (60.0 / bpm * 22050).toInt()
                        val at = ((call.argument<Double>("phase") ?: 0.0) * 22050).toInt()
                        if (at in 1 until frames) runCatching { player.playbackHeadPosition = at }
                        player.play(); tempo = bpm
                    }
                }
                val cue = call.argument<String>("cue")
                if (cue != null) {
                    val tone = cueTone(cue)
                    val player = cues.getOrPut(cue) { staticTrack(samples(tone)) }
                    if (cueTrack !== player) runCatching { cueTrack?.stop() }
                    cueTrack = player
                    runCatching { player.stop() }
                    player.reloadStaticData(); player.play()
                    cueEndsAt = SystemClock.elapsedRealtime() + (tone.seconds * 1000).toLong()
                    // Build the rest while this one is already sounding.
                    for (name in listOf("ready", "work", "rest", "complete")) {
                        cues.getOrPut(name) { staticTrack(samples(cueTone(name))) }
                    }
                } else if (!active) { cueTrack = null }
                result.success(null)
            } catch (_: Exception) { stop(); result.error("audioUnavailable", null, null) }
        }
    }
    // Pitch, partials, length and loudness measured from Tempo's cue recordings
    // (bpm.mp3, prebpm.mp3, end_3s.mp3), so the two apps sound like one.
    private class Tone(val partials: List<Pair<Double, Double>>, val seconds: Double, val decay: Boolean, val gain: Double)
    private val click = Tone(listOf(655.0 to 1.0, 1965.0 to 0.1), 0.12, true, 0.45)
    private val ding = listOf(1787.0 to 1.0, 2664.0 to 0.38, 1010.0 to 0.29)
    private fun cueTone(name: String) = when (name) {
        "ready" -> Tone(listOf(523.0 to 1.0, 1568.0 to 0.25), 0.08, false, 0.5)
        "work" -> Tone(listOf(1046.0 to 1.0, 3138.0 to 0.18), 0.22, false, 0.5)
        "complete" -> Tone(ding, 0.7, false, 0.3)
        else -> Tone(ding, 0.35, false, 0.25)
    }
    private fun samples(tone: Tone, length: Double = tone.seconds): ShortArray {
        val rate = 22050
        val sounding = (tone.seconds * rate).toInt()
        val scale = tone.partials.sumOf { it.second }
        return ShortArray((length * rate).toInt()) { i ->
            val t = i.toDouble() / rate
            val envelope = if (i >= sounding) 0.0 else if (tone.decay) exp(-t / (tone.seconds / 4)) else minOf(1.0, t / 0.004, (tone.seconds - t) / 0.004)
            val sample = tone.partials.sumOf { sin(t * it.first * 2 * PI) * it.second } / scale
            (sample * envelope * tone.gain * 32000).toInt().toShort()
        }
    }
    private fun staticTrack(samples: ShortArray): AudioTrack {
        val player = AudioTrack.Builder()
            .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
            .setAudioFormat(AudioFormat.Builder().setSampleRate(22050).setEncoding(AudioFormat.ENCODING_PCM_16BIT).setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
            .setTransferMode(AudioTrack.MODE_STATIC).setBufferSizeInBytes(samples.size * 2).build()
        check(player.write(samples, 0, samples.size) == samples.size)
        return player
    }
    private fun dropPending() { pendingSpeech?.let { handler.removeCallbacks(it) }; pendingSpeech = null }
    private fun stopClick() { track?.let { runCatching { it.stop() } }; track = null; tempo = null }
    private fun stopBeat() { cancelSpeech(); stopClick() }
    private fun stop() { stopBeat(); runCatching { speech?.stop() }; runCatching { cueTrack?.stop() }; cueTrack = null; activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON) }
    fun interrupt() { stop(); channel.invokeMethod("interrupted", null) }
    fun close() {
        stop(); speech?.shutdown(); speech = null; speechReady = false
        (beats.values + cues.values).forEach { runCatching { it.release() } }
        beats.clear(); cues.clear()
        channel.setMethodCallHandler(null)
    }
}
