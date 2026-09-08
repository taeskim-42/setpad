package com.taeskim.setpad

import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.TextPart
import com.google.mlkit.genai.prompt.generateContentRequest
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout

class LocalAiBridge(messenger: BinaryMessenger) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val model by lazy { Generation.getClient() }
    private val channel = MethodChannel(messenger, "setpad/local_ai")
    private var generation: Job? = null

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "cancel" -> { generation?.cancel(); result.success(null) }
                "status" -> scope.launch {
                    try { result.success(withTimeout(7000) { status() }) }
                    catch (_: Exception) { result.success("unavailable") }
                }
                "prepare" -> scope.launch {
                    try {
                        model.download().collect {
                            if (it is DownloadStatus.DownloadFailed) throw it.e
                        }
                        result.success(null)
                    } catch (_: Exception) { result.error("downloadFailed", null, null) }
                }
                "interpret" -> {
                    if (generation?.isActive == true) {
                        result.error("busy", null, null)
                    } else {
                        val prompt = call.argument<String>("prompt")
                        val instructions = call.argument<String>("instructions")
                        if (prompt == null || instructions == null || prompt.length > 12000) {
                            result.error("invalidInput", null, null)
                        } else generation = scope.launch {
                            try {
                                check(status() == "available")
                                val response = withTimeout(29000) {
                                    model.generateContent(generateContentRequest(
                                        TextPart("$instructions\nInput data:\n$prompt")
                                    ) { temperature = 0.0f; maxOutputTokens = 600 })
                                }
                                ensureActive()
                                result.success(response.candidates.firstOrNull()?.text)
                            } catch (_: Exception) { result.error("generationFailed", null, null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private suspend fun status(): String = when (model.checkStatus()) {
        FeatureStatus.AVAILABLE -> "available"
        FeatureStatus.DOWNLOADABLE -> "downloadable"
        FeatureStatus.DOWNLOADING -> "downloading"
        // UNAVAILABLE can also mean that AICore has not finished initialization.
        else -> "unavailable"
    }

    fun close() {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }
}
