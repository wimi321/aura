package app.aura.story.bridge

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.Content
import com.google.ai.edge.litertlm.Conversation
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.Message
import com.google.ai.edge.litertlm.SamplerConfig
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.runBlocking

class AuraLiteRtBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val controlExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val streamExecutor: ExecutorService = Executors.newCachedThreadPool()
    @Volatile private var textSink: EventChannel.EventSink? = null
    @Volatile private var audioSink: EventChannel.EventSink? = null
    private var runtimeOptions: RuntimeOptions = RuntimeOptions()
    @Volatile private var engine: Engine? = null
    @Volatile private var loadedModelId: String? = null
    @Volatile private var loadedModelPath: String? = null
    @Volatile private var activeBackendLabel: String = "cpu"
    @Volatile private var activeTextConversation: Conversation? = null
    @Volatile private var activeAudioConversation: Conversation? = null
    @Volatile private var activeTextRequestId: String? = null
    @Volatile private var activeAudioRequestId: String? = null
    @Volatile private var activeTextGeneration: Long = 0L
    @Volatile private var activeAudioGeneration: Long = 0L

    init {
        MethodChannel(messenger, "aura/litert").setMethodCallHandler(this)
        EventChannel(messenger, "aura/litert/text_stream").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    textSink = events
                }

                override fun onCancel(arguments: Any?) {
                    textSink = null
                }
            }
        )
        EventChannel(messenger, "aura/litert/audio_stream").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    audioSink = events
                }

                override fun onCancel(arguments: Any?) {
                    audioSink = null
                }
            }
        )
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                runtimeOptions = RuntimeOptions.from(call.arguments as? Map<*, *> ?: emptyMap<Any?, Any?>())
                result.success(null)
            }

            "getRuntimeStatus" -> getRuntimeStatus(result)
            "loadModel" -> loadModel(call, result)
            "unloadModel" -> unloadModel(result)
            "cancelActiveInference" -> cancelActiveInference(result)
            "beginTextInference" -> beginTextInference(call, result)
            "beginAudioInference" -> beginAudioInference(call, result)
            else -> result.notImplemented()
        }
    }

    private fun getRuntimeStatus(result: MethodChannel.Result) {
        result.success(
            mapOf(
                "runtime" to "litert-lm",
                "primaryBackend" to activeBackendLabel,
                "audioInputSupported" to false,
                "loadedModelId" to loadedModelId,
                "loadedModelPath" to loadedModelPath,
            )
        )
    }

    private fun loadModel(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *> ?: emptyMap<Any?, Any?>()
        val modelPath = args["localPath"]?.toString().orEmpty()
        if (modelPath.isBlank()) {
            result.error("MODEL_PATH_MISSING", "Model localPath is required.", null)
            return
        }

        controlExecutor.execute {
            try {
                clearActiveInference(notify = false)
                try {
                    engine?.close()
                } catch (_: Throwable) {
                }
                val initializedEngine = createInitializedEngine(modelPath)
                engine = initializedEngine.engine
                activeBackendLabel = initializedEngine.backendLabel
                loadedModelId = args["id"]?.toString()
                loadedModelPath = modelPath
                mainHandler.post { result.success(null) }
            } catch (throwable: Throwable) {
                mainHandler.post {
                    result.error("ENGINE_LOAD_FAILED", throwable.message, throwable.stackTraceToString())
                }
            }
        }
    }

    private fun unloadModel(result: MethodChannel.Result) {
        controlExecutor.execute {
            try {
                clearActiveInference(notify = false)
                try {
                    engine?.close()
                } catch (_: Throwable) {
                }
                engine = null
                loadedModelId = null
                loadedModelPath = null
                activeBackendLabel = runtimeOptions.primaryBackendLabel()
                mainHandler.post { result.success(null) }
            } catch (throwable: Throwable) {
                mainHandler.post {
                    result.error("ENGINE_UNLOAD_FAILED", throwable.message, throwable.stackTraceToString())
                }
            }
        }
    }

    private fun cancelActiveInference(result: MethodChannel.Result) {
        controlExecutor.execute {
            clearActiveInference(notify = true)
            mainHandler.post { result.success(null) }
        }
    }

    private fun beginTextInference(call: MethodCall, result: MethodChannel.Result) {
        val requestId = call.argument<String>("requestId").orEmpty()
        val prompt = call.argument<Map<String, Any?>>("prompt") ?: emptyMap()
        if (engine == null) {
            emitError(textSink, requestId, "Model is not loaded.")
            result.success(null)
            return
        }

        controlExecutor.execute {
            try {
                Log.i(TAG, "beginTextInference requestId=$requestId backend=$activeBackendLabel sampler=disabled")
                clearActiveInference(notify = false)
                val promptData = PromptData.from(
                    prompt = prompt,
                    disableSampler = true,
                )
                val conversation = createConversationWithRecovery(promptData.conversationConfig)
                val generation = activeTextGeneration + 1L
                activeTextGeneration = generation
                activeTextConversation = conversation
                activeTextRequestId = requestId
                launchConversationStream(
                    requestId = requestId,
                    sink = textSink,
                    conversation = conversation,
                    message = Message.user(promptData.promptText),
                    maxOutputTokens = promptData.maxOutputTokens,
                    stopSequences = promptData.stopSequences,
                    isCurrent = {
                        isCurrentTextConversation(
                            conversation = conversation,
                            requestId = requestId,
                            generation = generation,
                        )
                    },
                    onSettled = {
                        clearTextConversationIfCurrent(
                            conversation = conversation,
                            requestId = requestId,
                            generation = generation,
                        )
                    },
                )
                mainHandler.post { result.success(null) }
            } catch (throwable: Throwable) {
                emitError(textSink, requestId, throwable.message ?: throwable.toString())
                mainHandler.post {
                    result.error("TEXT_INFERENCE_FAILED", throwable.message, throwable.stackTraceToString())
                }
            }
        }
    }

    private fun beginAudioInference(call: MethodCall, result: MethodChannel.Result) {
        val requestId = call.argument<String>("requestId").orEmpty()
        val prompt = call.argument<Map<String, Any?>>("prompt") ?: emptyMap()
        val frames = call.argument<List<List<Int>>>("audioFrames") ?: emptyList()
        if (engine == null) {
            emitError(audioSink, requestId, "Model is not loaded.")
            result.success(null)
            return
        }

        controlExecutor.execute {
            try {
                clearActiveInference(notify = false)
                val promptData = PromptData.from(
                    prompt = prompt,
                    disableSampler = true,
                )
                val conversation = createConversationWithRecovery(promptData.conversationConfig)
                val generation = activeAudioGeneration + 1L
                activeAudioGeneration = generation
                activeAudioConversation = conversation
                activeAudioRequestId = requestId
                val audioBytes = flattenFrames(frames)
                val contents = mutableListOf<Content>(Content.AudioBytes(audioBytes))
                val promptText = promptData.promptText.trim()
                if (promptText.isNotBlank() && promptText != AUDIO_INPUT_PLACEHOLDER) {
                    contents.add(0, Content.Text(promptText))
                }
                launchConversationStream(
                    requestId = requestId,
                    sink = audioSink,
                    conversation = conversation,
                    message = Message.user(com.google.ai.edge.litertlm.Contents.of(contents)),
                    maxOutputTokens = promptData.maxOutputTokens,
                    stopSequences = promptData.stopSequences,
                    isCurrent = {
                        isCurrentAudioConversation(
                            conversation = conversation,
                            requestId = requestId,
                            generation = generation,
                        )
                    },
                    onSettled = {
                        clearAudioConversationIfCurrent(
                            conversation = conversation,
                            requestId = requestId,
                            generation = generation,
                        )
                    },
                )
                mainHandler.post { result.success(null) }
            } catch (throwable: Throwable) {
                emitError(audioSink, requestId, throwable.message ?: throwable.toString())
                mainHandler.post {
                    result.error("AUDIO_INFERENCE_FAILED", throwable.message, throwable.stackTraceToString())
                }
            }
        }
    }

    private fun launchConversationStream(
        requestId: String,
        sink: EventChannel.EventSink?,
        conversation: Conversation,
        message: Message,
        maxOutputTokens: Int,
        stopSequences: List<String>,
        isCurrent: () -> Boolean,
        onSettled: () -> Unit,
    ) {
        streamExecutor.execute {
            streamTextConversation(
                requestId = requestId,
                sink = sink,
                conversation = conversation,
                message = message,
                maxOutputTokens = maxOutputTokens,
                stopSequences = stopSequences,
                isCurrent = isCurrent,
                onSettled = onSettled,
            )
        }
    }

    private fun streamTextConversation(
        requestId: String,
        sink: EventChannel.EventSink?,
        conversation: Conversation,
        message: Message,
        maxOutputTokens: Int,
        stopSequences: List<String>,
        isCurrent: () -> Boolean,
        onSettled: () -> Unit,
    ) {
        var emittedEffectiveVisible = ""
        val settled = AtomicBoolean(false)
        var idleFinishRunnable: Runnable? = null
        val timeoutRunnable = Runnable {
            if (!isCurrent()) {
                return@Runnable
            }
            Log.w(TAG, "stream timeout requestId=$requestId")
            streamExecutor.execute {
                finishConversationWithError(
                    settled = settled,
                    sink = sink,
                    requestId = requestId,
                    conversation = conversation,
                    error = STREAM_TIMEOUT_ERROR,
                    timeoutRunnable = null,
                    idleFinishRunnable = idleFinishRunnable,
                    isCurrent = isCurrent,
                    onSettled = onSettled,
                )
            }
        }
        mainHandler.postDelayed(timeoutRunnable, STREAM_TIMEOUT_MS)
        try {
            runBlocking {
                conversation.sendMessageAsync(message, emptyMap()).collect { partial ->
                    if (settled.get() || !isCurrent()) {
                        return@collect
                    }
                    val rawCurrent = partial.toString()
                    val boundedRaw = applyStopSequences(rawCurrent, stopSequences)
                    val visibleCurrent = sanitizeVisibleText(boundedRaw)
                    val progress = computeVisibleProgress(
                        previousEffectiveVisible = emittedEffectiveVisible,
                        currentVisible = visibleCurrent,
                    )
                    if (progress.madeProgress) {
                        mainHandler.removeCallbacks(timeoutRunnable)
                        mainHandler.postDelayed(timeoutRunnable, STREAM_TIMEOUT_MS)
                        emittedEffectiveVisible = progress.effectiveVisible
                        if (progress.delta.isNotEmpty()) {
                            emitChunk(sink, requestId, progress.delta)
                        }
                        idleFinishRunnable?.let(mainHandler::removeCallbacks)
                    }
                    if (
                        progress.effectiveVisible.isNotBlank() &&
                        (progress.madeProgress || idleFinishRunnable == null)
                    ) {
                        idleFinishRunnable = Runnable {
                            Log.i(
                                TAG,
                                "idle finish requestId=$requestId visibleChars=${progress.effectiveVisible.length}",
                            )
                            streamExecutor.execute {
                                finishConversationSuccessfully(
                                    settled = settled,
                                    sink = sink,
                                    requestId = requestId,
                                    conversation = conversation,
                                    timeoutRunnable = timeoutRunnable,
                                    idleFinishRunnable = idleFinishRunnable,
                                    isCurrent = isCurrent,
                                    onSettled = onSettled,
                                )
                            }
                        }
                        mainHandler.postDelayed(idleFinishRunnable!!, STREAM_IDLE_FINISH_MS)
                    }
                    if (
                        rawCurrent != boundedRaw ||
                        estimateTokens(progress.effectiveVisible) >= maxOutputTokens
                    ) {
                        Log.i(
                            TAG,
                            "stream reached bound requestId=$requestId visibleChars=${progress.effectiveVisible.length}",
                        )
                        finishConversationSuccessfully(
                            settled = settled,
                            sink = sink,
                            requestId = requestId,
                            conversation = conversation,
                            timeoutRunnable = timeoutRunnable,
                            idleFinishRunnable = idleFinishRunnable,
                            isCurrent = isCurrent,
                            onSettled = onSettled,
                        )
                    }
                }
            }
            Log.i(TAG, "stream flow completed requestId=$requestId")
            finishConversationSuccessfully(
                settled = settled,
                sink = sink,
                requestId = requestId,
                conversation = conversation,
                timeoutRunnable = timeoutRunnable,
                idleFinishRunnable = idleFinishRunnable,
                isCurrent = isCurrent,
                onSettled = onSettled,
            )
        } catch (throwable: Throwable) {
            val error =
                if (throwable is CancellationException) {
                    CANCELLATION_ERROR
                } else {
                    throwable.message ?: throwable.toString()
                }
            Log.e(TAG, "stream error requestId=$requestId", throwable)
            finishConversationWithError(
                settled = settled,
                sink = sink,
                requestId = requestId,
                conversation = conversation,
                error = error,
                timeoutRunnable = timeoutRunnable,
                idleFinishRunnable = idleFinishRunnable,
                isCurrent = isCurrent,
                onSettled = onSettled,
            )
        }
    }

    private fun finishConversationSuccessfully(
        settled: AtomicBoolean,
        sink: EventChannel.EventSink?,
        requestId: String,
        conversation: Conversation,
        timeoutRunnable: Runnable,
        idleFinishRunnable: Runnable? = null,
        isCurrent: () -> Boolean,
        onSettled: () -> Unit,
    ) {
        if (!settled.compareAndSet(false, true)) {
            return
        }
        mainHandler.removeCallbacks(timeoutRunnable)
        idleFinishRunnable?.let(mainHandler::removeCallbacks)
        if (!isCurrent()) {
            return
        }
        Log.i(TAG, "finishConversationSuccessfully requestId=$requestId")
        releaseConversationAsync(
            conversation = conversation,
            requestId = requestId,
            outcome = "success",
        )
        onSettled()
        emitDone(sink, requestId)
    }

    private fun finishConversationWithError(
        settled: AtomicBoolean,
        sink: EventChannel.EventSink?,
        requestId: String,
        conversation: Conversation,
        error: String,
        timeoutRunnable: Runnable? = null,
        idleFinishRunnable: Runnable? = null,
        isCurrent: () -> Boolean,
        onSettled: () -> Unit,
    ) {
        if (!settled.compareAndSet(false, true)) {
            return
        }
        if (timeoutRunnable != null) {
            mainHandler.removeCallbacks(timeoutRunnable)
        }
        idleFinishRunnable?.let(mainHandler::removeCallbacks)
        if (!isCurrent()) {
            return
        }
        Log.w(TAG, "finishConversationWithError requestId=$requestId error=$error")
        releaseConversationAsync(
            conversation = conversation,
            requestId = requestId,
            outcome = "error",
        )
        onSettled()
        emitError(sink, requestId, error)
    }

    private fun clearActiveInference(notify: Boolean) {
        Log.i(TAG, "clearActiveInference notify=$notify")
        cancelActiveTextConversation(notify)
        cancelActiveAudioConversation(notify)
    }

    private fun cancelActiveTextConversation(notify: Boolean) {
        val conversation = activeTextConversation ?: return
        val requestId = activeTextRequestId
        activeTextConversation = null
        activeTextRequestId = null
        activeTextGeneration += 1L
        closeConversation(conversation)
        if (notify && !requestId.isNullOrBlank()) {
            emitError(textSink, requestId, CANCELLATION_ERROR)
        }
    }

    private fun cancelActiveAudioConversation(notify: Boolean) {
        val conversation = activeAudioConversation ?: return
        val requestId = activeAudioRequestId
        activeAudioConversation = null
        activeAudioRequestId = null
        activeAudioGeneration += 1L
        closeConversation(conversation)
        if (notify && !requestId.isNullOrBlank()) {
            emitError(audioSink, requestId, CANCELLATION_ERROR)
        }
    }

    private fun isCurrentTextConversation(
        conversation: Conversation,
        requestId: String,
        generation: Long,
    ): Boolean {
        return activeTextConversation === conversation &&
            activeTextRequestId == requestId &&
            activeTextGeneration == generation
    }

    private fun isCurrentAudioConversation(
        conversation: Conversation,
        requestId: String,
        generation: Long,
    ): Boolean {
        return activeAudioConversation === conversation &&
            activeAudioRequestId == requestId &&
            activeAudioGeneration == generation
    }

    private fun clearTextConversationIfCurrent(
        conversation: Conversation,
        requestId: String,
        generation: Long,
    ) {
        if (!isCurrentTextConversation(conversation, requestId, generation)) {
            return
        }
        activeTextConversation = null
        activeTextRequestId = null
        activeTextGeneration += 1L
    }

    private fun clearAudioConversationIfCurrent(
        conversation: Conversation,
        requestId: String,
        generation: Long,
    ) {
        if (!isCurrentAudioConversation(conversation, requestId, generation)) {
            return
        }
        activeAudioConversation = null
        activeAudioRequestId = null
        activeAudioGeneration += 1L
    }

    private fun closeConversation(conversation: Conversation) {
        try {
            conversation.cancelProcess()
        } catch (_: Throwable) {
        }
        try {
            conversation.close()
        } catch (_: Throwable) {
        }
        waitForConversationRelease(conversation)
    }

    private fun waitForConversationRelease(conversation: Conversation) {
        repeat(CONVERSATION_RELEASE_POLL_ATTEMPTS) {
            val alive = try {
                conversation.isAlive
            } catch (_: Throwable) {
                false
            }
            if (!alive) {
                return
            }
            try {
                Thread.sleep(CONVERSATION_RELEASE_POLL_MS)
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
                return
            }
        }
    }

    private fun releaseConversationAsync(
        conversation: Conversation,
        requestId: String,
        outcome: String,
    ) {
        controlExecutor.execute {
            Log.i(TAG, "releaseConversation requestId=$requestId outcome=$outcome")
            closeConversation(conversation)
        }
    }

    private fun createConversationWithRecovery(config: ConversationConfig): Conversation {
        var activeEngine = engine ?: throw IllegalStateException("Model is not loaded.")
        var lastError: Throwable? = null

        repeat(CONVERSATION_CREATE_MAX_ATTEMPTS) { attempt ->
            try {
                return activeEngine.createConversation(config)
            } catch (throwable: Throwable) {
                lastError = throwable
                if (!isSessionAlreadyExistsError(throwable)) {
                    throw throwable
                }

                when {
                    attempt >= CONVERSATION_CREATE_MAX_ATTEMPTS - 1 -> Unit
                    attempt < CONVERSATION_CREATE_RESET_ATTEMPT -> sleepForRecovery(CONVERSATION_CREATE_RETRY_MS)
                    else -> {
                        activeEngine = rebuildEngineForLoadedModel()
                        sleepForRecovery(CONVERSATION_CREATE_RETRY_MS)
                    }
                }
            }
        }

        throw IllegalStateException(
            "Failed to create conversation after session recovery attempts.",
            lastError,
        )
    }

    private fun rebuildEngineForLoadedModel(): Engine {
        val modelPath = loadedModelPath ?: throw IllegalStateException("No loaded model path available.")
        clearActiveInference(notify = false)
        try {
            engine?.close()
        } catch (_: Throwable) {
        }
        val initializedEngine = createInitializedEngine(modelPath)
        engine = initializedEngine.engine
        activeBackendLabel = initializedEngine.backendLabel
        return initializedEngine.engine
    }

    private fun createInitializedEngine(modelPath: String): InitializedEngine {
        val backendAttempts = runtimeOptions.backendAttempts()
        var nextEngine: Engine? = null
        var lastError: Throwable? = null
        var selectedBackendLabel = runtimeOptions.primaryBackendLabel()

        for (delegate in backendAttempts) {
            var candidateEngine: Engine? = null
            try {
                val config = EngineConfig(
                    modelPath = modelPath,
                    backend = delegate.toBackend(context),
                    audioBackend = runtimeOptions.audioBackend(),
                    maxNumTokens = runtimeOptions.maxContextTokensOverride,
                    cacheDir = context.cacheDir.absolutePath,
                )
                candidateEngine = Engine(config)
                candidateEngine.initialize()
                nextEngine = candidateEngine
                selectedBackendLabel = delegate.label
                break
            } catch (throwable: Throwable) {
                try {
                    candidateEngine?.close()
                } catch (_: Throwable) {
                }
                lastError = throwable
            }
        }

        if (nextEngine == null) {
            throw IllegalStateException(
                buildString {
                    append("Failed to create engine after trying backends: ")
                    append(backendAttempts.joinToString(", ") { it.label })
                    lastError?.message?.let {
                        append(". Last error: ")
                        append(it)
                    }
                },
                lastError,
            )
        }

        return InitializedEngine(
            engine = nextEngine,
            backendLabel = selectedBackendLabel,
        )
    }

    private fun isSessionAlreadyExistsError(throwable: Throwable): Boolean {
        val message = throwable.message?.lowercase().orEmpty()
        return message.contains("session already exists") ||
            message.contains("failed_precondition") ||
            message.contains("only one session is supported")
    }

    private fun sleepForRecovery(durationMs: Long) {
        try {
            Thread.sleep(durationMs)
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
        }
    }

    private fun emitChunk(sink: EventChannel.EventSink?, requestId: String, chunk: String) {
        if (sink == null || chunk.isEmpty()) return
        mainHandler.post {
            sink.success(
                mapOf(
                    "requestId" to requestId,
                    "chunk" to chunk,
                    "done" to false,
                )
            )
        }
    }

    private fun emitDone(sink: EventChannel.EventSink?, requestId: String) {
        if (sink == null) return
        mainHandler.post {
            sink.success(
                mapOf(
                    "requestId" to requestId,
                    "done" to true,
                )
            )
        }
    }

    private fun emitError(sink: EventChannel.EventSink?, requestId: String, error: String) {
        if (sink == null) return
        mainHandler.post {
            sink.success(
                mapOf(
                    "requestId" to requestId,
                    "done" to true,
                    "error" to error,
                )
            )
        }
    }

    private fun flattenFrames(frames: List<List<Int>>): ByteArray {
        val output = ByteArrayOutputStream()
        for (frame in frames) {
            output.write(frame.map { it.toByte() }.toByteArray())
        }
        return output.toByteArray()
    }

    private fun applyStopSequences(text: String, stopSequences: List<String>): String {
        if (stopSequences.isEmpty()) {
            return text
        }
        var cutIndex = text.length
        for (sequence in stopSequences) {
            if (sequence.isBlank()) {
                continue
            }
            val index = text.indexOf(sequence)
            if (index >= 0 && index < cutIndex) {
                cutIndex = index
            }
        }
        return if (cutIndex == text.length) text else text.substring(0, cutIndex)
    }

    private fun sanitizeVisibleText(text: String): String {
        return EMOTION_TAG_REGEX.replace(text, "")
    }

    private fun estimateTokens(text: String): Int {
        return maxOf(1, (text.length + 3) / 4)
    }

    companion object {
        private const val STREAM_TIMEOUT_MS = 75_000L
        private const val STREAM_IDLE_FINISH_MS = 3_000L
        private const val CANCELLATION_ERROR = "AURA_GENERATION_CANCELLED"
        private const val STREAM_TIMEOUT_ERROR = "AURA_GENERATION_TIMEOUT"
        private const val AUDIO_INPUT_PLACEHOLDER = "[audio_input]"
        private const val CONVERSATION_RELEASE_POLL_ATTEMPTS = 20
        private const val CONVERSATION_RELEASE_POLL_MS = 25L
        private const val CONVERSATION_CREATE_MAX_ATTEMPTS = 4
        private const val CONVERSATION_CREATE_RESET_ATTEMPT = 2
        private const val CONVERSATION_CREATE_RETRY_MS = 75L
        private val EMOTION_TAG_REGEX = Regex("""\[[a-zA-Z0-9_-]{2,24}]""")
        private const val TAG = "AuraLiteRtBridge"
    }
}

internal data class VisibleProgress(
    val effectiveVisible: String,
    val delta: String,
    val madeProgress: Boolean,
)

internal fun computeVisibleProgress(
    previousEffectiveVisible: String,
    currentVisible: String,
): VisibleProgress {
    val effectiveVisible = currentVisible.trimEnd()
    val delta =
        if (effectiveVisible.startsWith(previousEffectiveVisible)) {
            effectiveVisible.removePrefix(previousEffectiveVisible)
        } else {
            effectiveVisible
        }
    return VisibleProgress(
        effectiveVisible = effectiveVisible,
        delta = delta,
        madeProgress = effectiveVisible != previousEffectiveVisible,
    )
}

private data class InitializedEngine(
    val engine: Engine,
    val backendLabel: String,
)

private data class RuntimeOptions(
    val primaryDelegate: String = "cpu",
    val fallbackDelegates: List<String> = listOf("cpu"),
    val maxContextTokensOverride: Int? = null,
    val enableAudioUnderstanding: Boolean = true,
) {
    fun backendAttempts(): List<DelegateChoice> {
        val ordered = buildList {
            add(primaryDelegate)
            addAll(fallbackDelegates)
            if (none { it.equals("cpu", ignoreCase = true) }) {
                add("cpu")
            }
        }

        val seen = linkedSetOf<String>()
        return ordered.mapNotNull { raw ->
            val choice = DelegateChoice.from(raw) ?: return@mapNotNull null
            if (!seen.add(choice.label)) {
                return@mapNotNull null
            }
            choice
        }
    }

    fun primaryBackendLabel(): String {
        return DelegateChoice.from(primaryDelegate)?.label ?: "cpu"
    }

    fun audioBackend(): Backend? {
        if (!enableAudioUnderstanding) {
            return null
        }
        return Backend.CPU()
    }

    companion object {
        fun from(args: Map<*, *>): RuntimeOptions {
            return RuntimeOptions(
                primaryDelegate = args["primaryDelegate"]?.toString() ?: "cpu",
                fallbackDelegates = (args["fallbackDelegates"] as? List<*>)
                    ?.mapNotNull { it?.toString() }
                    ?.filter { it.isNotBlank() }
                    ?: listOf("cpu"),
                maxContextTokensOverride = (args["maxContextTokensOverride"] as? Number)?.toInt(),
                enableAudioUnderstanding = args["enableAudioUnderstanding"] as? Boolean ?: true,
            )
        }
    }
}

private data class DelegateChoice(
    val label: String,
) {
    fun toBackend(context: Context): Backend {
        return when (label) {
            "nnapi" -> Backend.NPU(context.applicationInfo.nativeLibraryDir)
            "gpu" -> Backend.GPU()
            else -> Backend.CPU()
        }
    }

    companion object {
        fun from(raw: String?): DelegateChoice? {
            return when (raw?.lowercase()) {
                "nnapi" -> DelegateChoice("nnapi")
                "gpu" -> DelegateChoice("gpu")
                "cpu" -> DelegateChoice("cpu")
                else -> null
            }
        }
    }
}

private data class PromptData(
    val conversationConfig: ConversationConfig,
    val promptText: String,
    val maxOutputTokens: Int,
    val stopSequences: List<String>,
) {
    companion object {
        fun from(
            prompt: Map<String, Any?>,
            disableSampler: Boolean = false,
        ): PromptData {
            val systemInstruction = prompt["systemInstruction"]?.toString()?.takeIf { it.isNotBlank() }
            val postHistoryInstructions =
                prompt["postHistoryInstructions"]?.toString()?.takeIf { it.isNotBlank() }
            val assistantLabel = prompt["assistantLabel"]?.toString()?.trim().takeUnless { it.isNullOrBlank() }
                ?: "Character"
            val userLabel = prompt["userLabel"]?.toString()?.trim().takeUnless { it.isNullOrBlank() }
                ?: "You"
            val generation = prompt["generationConfig"] as? Map<*, *> ?: emptyMap<Any?, Any?>()
            val sampler = if (disableSampler) {
                null
            } else {
                SamplerConfig(
                    topK = (generation["top_k"] as? Number)?.toInt() ?: 40,
                    topP = (generation["top_p"] as? Number)?.toDouble() ?: 0.9,
                    temperature = (generation["temperature"] as? Number)?.toDouble() ?: 0.85,
                )
            }
            val normalizedMessages = ((prompt["messages"] as? List<*>) ?: emptyList<Any>())
                .mapNotNull { item ->
                    (item as? Map<*, *>)?.let { mapToSeed(it) }
                }
                .dropLeadingDuplicateSystem(systemInstruction)
            val promptText = buildPromptText(
                messages = normalizedMessages,
                postHistoryInstructions = postHistoryInstructions,
                assistantLabel = assistantLabel,
                userLabel = userLabel,
            )
            return PromptData(
                conversationConfig = ConversationConfig(
                    systemInstruction = systemInstruction?.let { com.google.ai.edge.litertlm.Contents.of(it) },
                    samplerConfig = sampler,
                ),
                promptText = promptText,
                maxOutputTokens = (generation["max_output_tokens"] as? Number)?.toInt() ?: 512,
                stopSequences = (generation["stop_sequences"] as? List<*>)
                    ?.mapNotNull { it?.toString() }
                    ?.filter { it.isNotBlank() }
                    ?: emptyList(),
            )
        }

        private fun mapToSeed(map: Map<*, *>): PromptSeed? {
            val role = map["role"]?.toString() ?: return null
            val content = map["content"]?.toString() ?: ""
            return PromptSeed(role = role, content = content)
        }

        private fun List<PromptSeed>.dropLeadingDuplicateSystem(
            systemInstruction: String?,
        ): List<PromptSeed> {
            val first = firstOrNull() ?: return this
            val normalizedSystem = systemInstruction?.trim()
            return if (first.role == "system" && first.content.trim() == normalizedSystem) {
                drop(1)
            } else {
                this
            }
        }

        private fun buildPromptText(
            messages: List<PromptSeed>,
            postHistoryInstructions: String?,
            assistantLabel: String,
            userLabel: String,
        ): String {
            if (messages.isEmpty()) {
                return ""
            }
            val lastMessage = messages.last()
            val history = messages.dropLast(1)
            val builder = StringBuilder()

            if (history.isNotEmpty()) {
                builder.append("Roleplay transcript so far:\n")
                for (message in history) {
                    val content = message.content.trim()
                    if (content.isEmpty()) {
                        continue
                    }
                    builder
                        .append(message.displayRole(assistantLabel, userLabel))
                        .append(": ")
                        .append(content)
                        .append("\n\n")
                }
            }

            val normalizedPostHistory = postHistoryInstructions?.trim()
            if (!normalizedPostHistory.isNullOrEmpty()) {
                builder.append("Scene guidance for the next reply:\n")
                    .append(normalizedPostHistory)
                    .append("\n\n")
            }

            when {
                lastMessage.role == "user" &&
                    lastMessage.content.trim() == "[audio_input]" -> {
                    builder.append("Latest ")
                        .append(userLabel)
                        .append(" input arrived as attached audio.\n\n")
                        .append("Write only ")
                        .append(assistantLabel)
                        .append("'s next in-character reply to that audio while staying consistent with the scene above. ")
                        .append("Do not write ")
                        .append(userLabel)
                        .append("'s dialogue, decisions, thoughts, or actions.")
                }
                lastMessage.role == "user" -> {
                    builder.append("Latest ")
                        .append(userLabel)
                        .append(" input:\n")
                        .append(lastMessage.content.trim())
                        .append("\n\n")
                        .append("Write only ")
                        .append(assistantLabel)
                        .append("'s next in-character reply. Continue the same scene, stay inside the role, and do not write ")
                        .append(userLabel)
                        .append("'s dialogue, thoughts, choices, or actions.")
                }
                else -> {
                    builder.append("Write only ")
                        .append(assistantLabel)
                        .append("'s next in-character reply and continue the current scene from the latest context above.")
                }
            }

            return builder.toString().trim()
        }

        private fun PromptSeed.displayRole(
            assistantLabel: String,
            userLabel: String,
        ): String {
            return when (role) {
                "assistant" -> assistantLabel
                "system" -> "Context"
                "tool" -> "Tool"
                else -> userLabel
            }
        }
    }
}

private data class PromptSeed(
    val role: String,
    val content: String,
)
