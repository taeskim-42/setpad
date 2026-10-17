package com.taeskim.setpad

import android.app.Activity
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.media.MediaMetadataRetriever
import android.media.SoundPool
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.WindowManager
import io.flutter.FlutterInjector
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
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
    private val handler = Handler(Looper.getMainLooper())
    private var cueEndsAt = 0L

    // Recorded words (Flutter assets, lib/workout_timing.dart countVoice and
    // phraseVoice), decoded once by SoundPool. Media usage like the cue tracks,
    // so they share the media volume and silent mode does not mute only the
    // words; no audio focus is taken, music goes on underneath.
    private val pool = SoundPool.Builder().setMaxStreams(2).setAudioAttributes(
        AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
    ).build()
    private val loaded = mutableSetOf<Int>()
    private val lengths = mutableMapOf<String, Long>()
    // The latest 40 assets stay loaded: asset → sound id.
    private val sounds = object : LinkedHashMap<String, Int>(16, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Int>) =
            (size > 40).also { if (it) { pool.unload(eldest.value); loaded.remove(eldest.value) } }
    }
    private var voiceStream = 0
    private var voiceEndsAt = 0L
    private var pendingCount: Runnable? = null
    private var pendingPhrase: Runnable? = null
    private val measuring = Executors.newSingleThreadExecutor()

    private fun sound(asset: String): Int? = sounds[asset] ?: runCatching {
        val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
        // Its length, for "still sounding": measured once, off the main thread.
        if (asset !in lengths) measuring.execute {
            runCatching {
                activity.assets.openFd(key).use { fd ->
                    MediaMetadataRetriever().run {
                        try {
                            setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
                            extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLong()
                        } finally { release() }
                    }
                }
            }.getOrNull()?.let { ms -> handler.post { lengths[asset] = ms } }
        }
        activity.assets.openFd(key).use { pool.load(it, 1) }
    }.getOrNull()?.also { sounds[asset] = it }

    // A count (onBeat) matches Tempo: half a beat after the click, capped at
    // one second. The count comes from Dart's clock and the click from this
    // track, which started a little later — near the end of the loop the click
    // this count belongs to has not sounded yet, so wait for it. A newer count
    // replaces one still waiting; if the previous word is still sounding, wait
    // briefly for it instead of cutting it off, then give up. A phrase waits for
    // the cue and for the word sounding or about to; a count arriving meanwhile
    // is dropped.
    private fun playVoice(asset: String, onBeat: Boolean) {
        if (onBeat && pendingPhrase != null) return
        val id = sound(asset) ?: return
        var patience = 3000L
        var countRemaining = 0L
        if (onBeat) {
            dropPending()
            patience = 150L
            val player = track
            val bpm = tempo
            if (player != null && bpm != null) {
                val frames = (60.0 / bpm * 22050).toInt()
                val period = 60000L / bpm
                val half = minOf(30000L / bpm, 1000L)
                val at = ((player.playbackHeadPosition.toLong() and 0xffffffffL) % frames) * 1000 / 22050
                // No later than a quarter beat after the planned moment: a late word
                // never lands on the next click and lateness cannot pile up.
                patience = period / 4
                countRemaining = if (at > period * 3 / 4) period - at + half else maxOf(0L, half - at)
            }
        } else { pendingPhrase?.let { handler.removeCallbacks(it) }; pendingPhrase = null }
        val delay = maxOf(countRemaining, cueEndsAt - SystemClock.elapsedRealtime(), 0L)
        val giveUpAt = SystemClock.elapsedRealtime() + delay + patience
        lateinit var task: Runnable
        task = Runnable {
            val now = SystemClock.elapsedRealtime()
            val busy = now < voiceEndsAt || id !in loaded || (!onBeat && pendingCount != null)
            if (busy && now < giveUpAt) { handler.postDelayed(task, 20); return@Runnable }
            if (onBeat) pendingCount = null else pendingPhrase = null
            if (id !in loaded || (onBeat && now < voiceEndsAt)) return@Runnable
            pool.stop(voiceStream)
            voiceStream = pool.play(id, 1f, 1f, 1, 0, 1f)
            // Not measured yet (only right after loading): a long count.
            voiceEndsAt = if (voiceStream != 0) now + (lengths[asset] ?: 1200L) else 0L
        }
        if (onBeat) pendingCount = task else pendingPhrase = task
        handler.postDelayed(task, if (delay > 0) delay + 5 else 0)
    }

    private fun cancelVoice() {
        dropPending()
        pendingPhrase?.let { handler.removeCallbacks(it) }; pendingPhrase = null
        pool.stop(voiceStream); voiceStream = 0; voiceEndsAt = 0L
    }

    init {
        pool.setOnLoadCompleteListener { _, id, status -> if (status == 0) loaded.add(id) }
        channel.setMethodCallHandler { call, result ->
            if (call.method == "warmUp") {
                // Build the cue tracks and load the first words (both voices)
                // ahead of the first cue, so "one, two" are not lost. No sound.
                runCatching {
                    for (name in listOf("ready", "work", "rest", "complete")) {
                        cues.getOrPut(name) { staticTrack(samples(cueTone(name))) }
                    }
                    for (sex in listOf("m", "w")) {
                        for (n in 1..10) sound("assets/voice/count/en/$sex/$n.m4a")
                        for (key in listOf("start", "rest")) sound("assets/voice/en/$sex/$key.m4a")
                    }
                }
                result.success(null)
            }
            else if (call.method == "voice") {
                runCatching {
                    playVoice(call.argument<String>("asset") ?: "", call.argument<Boolean>("onBeat") == true)
                }
                result.success(null)
            }
            else if (call.method == "keepAlive") {
                // Where iOS starts and stops its keep-alive loop, minus the set
                // stage alone (lib/timing_audio_mux.dart). A finishing cue (0.7 s
                // ding, then done.m4a 2.5 s or "Go!") keeps it 6 s more.
                if (call.argument<Boolean>("on") == true) TimingService.start(activity.applicationContext)
                else TimingService.stop(if (call.argument<Boolean>("linger") == true) 6000L else 0L)
                result.success(null)
            }
            else if (call.method != "configure") { result.notImplemented() }
            else try {
                val active = call.argument<Boolean>("active") == true
                // The app allows 10 BPM; anything slower than this range is a typo.
                val bpm = if (active) call.argument<Int>("bpm")?.takeIf { it in 10..300 } else null
                val cue = call.argument<String>("cue")
                // Pausing or stopping cuts the voice; finishing (the complete
                // cue) lets the last number finish.
                if (!active && cue == null) cancelVoice()
                if (active) activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                else activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                if (bpm != tempo) {
                    // A tempo change while running (Tabata work to rest) only
                    // drops a count still waiting: the round's last number is
                    // allowed to finish.
                    if (active) dropPending() else if (cue == null) cancelVoice()
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
    private fun dropPending() { pendingCount?.let { handler.removeCallbacks(it) }; pendingCount = null }
    private fun stopClick() { track?.let { runCatching { it.stop() } }; track = null; tempo = null }
    private fun stop() { cancelVoice(); stopClick(); runCatching { cueTrack?.stop() }; cueTrack = null; activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON); TimingService.stop() }
    /// The app is in front again: a service refused in the background starts now.
    fun resumed() = TimingService.retry(activity.applicationContext)
    fun close() {
        stop(); pool.release(); measuring.shutdown()
        (beats.values + cues.values).forEach { runCatching { it.release() } }
        beats.clear(); cues.clear()
        channel.setMethodCallHandler(null)
    }
}
