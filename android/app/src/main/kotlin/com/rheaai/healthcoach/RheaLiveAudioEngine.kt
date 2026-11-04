package com.rheaai.healthcoach

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.*
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

/**
 * Native Android PCM audio engine for RheaAI Gemini Live.
 *
 * Microphone:
 * - 16,000 Hz
 * - Mono
 * - PCM signed 16-bit
 *
 * Speaker:
 * - 24,000 Hz
 * - Mono
 * - PCM signed 16-bit
 */
class RheaLiveAudioEngine(
    private val context: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        private const val METHOD_CHANNEL =
            "com.rheaai.healthcoach/live_audio"

        private const val MICROPHONE_CHANNEL =
            "com.rheaai.healthcoach/live_audio/microphone"

        private const val INPUT_SAMPLE_RATE = 16000
        private const val OUTPUT_SAMPLE_RATE = 24000

        // 100 ms of mono PCM16 input.
        private const val INPUT_CHUNK_BYTES = 3200

        // Maximum queued output chunks.
        private const val MAX_PLAYBACK_CHUNKS = 48
    }

    private val methods = MethodChannel(
        messenger,
        METHOD_CHANNEL
    )

    private val microphoneEvents = EventChannel(
        messenger,
        MICROPHONE_CHANNEL
    )

    private val mainHandler = Handler(Looper.getMainLooper())

    private val audioManager =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private val lock = Any()

    private var sink: EventChannel.EventSink? = null

    private var recorder: AudioRecord? = null
    private var player: AudioTrack? = null

    private var captureThread: Thread? = null
    private var playbackThread: Thread? = null

    private val recording = AtomicBoolean(false)
    private val playing = AtomicBoolean(false)

    private val playbackQueue =
        ArrayBlockingQueue<ByteArray>(MAX_PLAYBACK_CHUNKS)

    private var generation = 0

    private var initialized = false
    private var disposed = false

    private var focusRequest: AudioFocusRequest? = null
    private var legacyFocusGranted = false

    private var priorMode: Int? = null
    private var priorSpeakerphone: Boolean? = null

    init {
        methods.setMethodCallHandler(this)
        microphoneEvents.setStreamHandler(this)
    }

    // ============================================================
    // MICROPHONE EVENT CHANNEL
    // ============================================================

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?
    ) {
        synchronized(lock) {
            sink = events
        }
    }

    override fun onCancel(arguments: Any?) {
        synchronized(lock) {
            sink = null
        }
    }

    // ============================================================
    // FLUTTER METHOD CHANNEL
    // ============================================================

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        try {
            when (call.method) {

                "initialize" -> {
                    initialize()
                    result.success(null)
                }

                "startMicrophone" -> {
                    startMicrophone()
                    result.success(null)
                }

                "stopMicrophone" -> {
                    stopMicrophone()
                    result.success(null)
                }

                "playAudioChunk" -> {
                    val bytes =
                        call.argument<ByteArray>("audio")
                            ?: throw AudioFailure(
                                "AUDIO_PLAYBACK_FAILED",
                                "Missing PCM audio data"
                            )

                    val requestedGeneration =
                        call.argument<Int>("generation") ?: -1

                    enqueueAudio(
                        bytes,
                        requestedGeneration
                    )

                    result.success(null)
                }

                "interruptPlayback",
                "stopPlayback" -> {
                    val requestedGeneration =
                        call.argument<Int>("generation") ?: -1

                    clearPlayback(requestedGeneration)
                    result.success(null)
                }

                "dispose" -> {
                    dispose()
                    result.success(null)
                }

                else -> result.notImplemented()
            }

        } catch (e: AudioFailure) {
            result.error(
                e.code,
                e.message,
                null
            )

        } catch (e: SecurityException) {
            result.error(
                "MIC_PERMISSION_DENIED",
                "Microphone permission denied",
                null
            )

        } catch (e: Exception) {
            result.error(
                "AUDIO_INIT_FAILED",
                "Native audio operation failed",
                null
            )
        }
    }

    // ============================================================
    // INITIALIZE AUDIO ENGINE
    // ============================================================

    private fun initialize() {
        synchronized(lock) {
            if (disposed) {
                disposed = false
            }

            if (initialized) return

            if (
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.RECORD_AUDIO
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                throw AudioFailure(
                    "MIC_PERMISSION_DENIED",
                    "Microphone permission required"
                )
            }

            priorMode = audioManager.mode
            priorSpeakerphone = audioManager.isSpeakerphoneOn

            val attributes = AudioAttributes.Builder()
                .setUsage(
                    AudioAttributes.USAGE_VOICE_COMMUNICATION
                )
                .setContentType(
                    AudioAttributes.CONTENT_TYPE_SPEECH
                )
                .build()

            val focusResult =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

                    val request = AudioFocusRequest.Builder(
                        AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
                    )
                        .setAudioAttributes(attributes)
                        .setOnAudioFocusChangeListener { change ->
                            if (
                                change == AudioManager.AUDIOFOCUS_LOSS ||
                                change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT
                            ) {
                                synchronized(lock) {
                                    playbackQueue.clear()

                                    try {
                                        player?.pause()
                                        player?.flush()
                                    } catch (_: Exception) {
                                    }
                                }
                            }
                        }
                        .build()

                    focusRequest = request

                    audioManager.requestAudioFocus(request)

                } else {
                    @Suppress("DEPRECATION")
                    audioManager.requestAudioFocus(
                        null,
                        AudioManager.STREAM_VOICE_CALL,
                        AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
                    )
                }

            if (
                focusResult !=
                AudioManager.AUDIOFOCUS_REQUEST_GRANTED
            ) {
                throw AudioFailure(
                    "AUDIO_INIT_FAILED",
                    "Audio focus unavailable"
                )
            }

            legacyFocusGranted =
                Build.VERSION.SDK_INT < Build.VERSION_CODES.O

            audioManager.mode =
                AudioManager.MODE_IN_COMMUNICATION

            val minOutputBuffer = AudioTrack.getMinBufferSize(
                OUTPUT_SAMPLE_RATE,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )

            if (minOutputBuffer <= 0) {
                throw AudioFailure(
                    "AUDIO_INIT_FAILED",
                    "Unsupported output audio format"
                )
            }

            player = AudioTrack.Builder()
                .setAudioAttributes(attributes)
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(
                            AudioFormat.ENCODING_PCM_16BIT
                        )
                        .setSampleRate(OUTPUT_SAMPLE_RATE)
                        .setChannelMask(
                            AudioFormat.CHANNEL_OUT_MONO
                        )
                        .build()
                )
                .setBufferSizeInBytes(
                    maxOf(minOutputBuffer * 2, 9600)
                )
                .setTransferMode(AudioTrack.MODE_STREAM)
                .build()

            if (
                player?.state !=
                AudioTrack.STATE_INITIALIZED
            ) {
                throw AudioFailure(
                    "AUDIO_INIT_FAILED",
                    "Speaker initialization failed"
                )
            }

            player?.play()

            playing.set(true)

            playbackThread = thread(
                name = "rhea-pcm-output",
                isDaemon = true
            ) {
                playbackLoop()
            }

            initialized = true
        }
    }

    // ============================================================
    // START MICROPHONE
    // ============================================================

    private fun startMicrophone() {
        synchronized(lock) {
            if (!initialized || disposed) {
                throw AudioFailure(
                    "AUDIO_RECORD_FAILED",
                    "Audio engine not initialized"
                )
            }

            if (recording.get()) return

            if (
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.RECORD_AUDIO
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                throw AudioFailure(
                    "MIC_PERMISSION_DENIED",
                    "Microphone permission required"
                )
            }

            val minInputBuffer =
                AudioRecord.getMinBufferSize(
                    INPUT_SAMPLE_RATE,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT
                )

            if (minInputBuffer <= 0) {
                throw AudioFailure(
                    "MIC_UNAVAILABLE",
                    "Unsupported microphone format"
                )
            }

            val bufferBytes =
                maxOf(minInputBuffer * 2, INPUT_CHUNK_BYTES)

            recorder = AudioRecord(
                MediaRecorder.AudioSource.VOICE_COMMUNICATION,
                INPUT_SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                bufferBytes
            )

            if (
                recorder?.state !=
                AudioRecord.STATE_INITIALIZED
            ) {
                recorder?.release()
                recorder = null

                throw AudioFailure(
                    "MIC_UNAVAILABLE",
                    "Microphone initialization failed"
                )
            }

            recorder?.startRecording()

            if (
                recorder?.recordingState !=
                AudioRecord.RECORDSTATE_RECORDING
            ) {
                throw AudioFailure(
                    "AUDIO_RECORD_FAILED",
                    "Microphone could not start"
                )
            }

            recording.set(true)

            captureThread = thread(
                name = "rhea-pcm-input",
                isDaemon = true
            ) {
                captureLoop()
            }
        }
    }

    // ============================================================
    // STREAM MICROPHONE AUDIO TO FLUTTER
    // ============================================================

    private fun captureLoop() {
        val buffer = ByteArray(INPUT_CHUNK_BYTES)

        while (recording.get()) {
            val source = synchronized(lock) {
                recorder
            } ?: break

            val bytesRead = try {
                source.read(
                    buffer,
                    0,
                    buffer.size
                )
            } catch (_: Exception) {
                break
            }

            if (bytesRead > 0 && recording.get()) {
                val evenLength =
                    bytesRead - (bytesRead % 2)

                val bytes = buffer.copyOf(evenLength)

                if (bytes.isNotEmpty()) {
                    mainHandler.post {
                        if (recording.get()) {
                            synchronized(lock) {
                                sink
                            }?.success(bytes)
                        }
                    }
                }

            } else if (bytesRead < 0) {
                break
            }
        }
    }

    // ============================================================
    // STOP MICROPHONE
    // ============================================================

    private fun stopMicrophone() {
        recording.set(false)

        val source = synchronized(lock) {
            val current = recorder
            recorder = null
            current
        }

        try {
            source?.stop()
        } catch (_: Exception) {
        }

        try {
            source?.release()
        } catch (_: Exception) {
        }

        captureThread?.interrupt()
        captureThread = null
    }

    // ============================================================
    // QUEUE RHEA AUDIO
    // ============================================================

    private fun enqueueAudio(
        bytes: ByteArray,
        requestedGeneration: Int
    ) {
        synchronized(lock) {
            if (!initialized || disposed) {
                throw AudioFailure(
                    "AUDIO_PLAYBACK_FAILED",
                    "Audio engine not initialized"
                )
            }

            // Discard audio from a previous playback generation.
            if (requestedGeneration < generation) {
                return
            }

            if (requestedGeneration > generation) {
                generation = requestedGeneration

                playbackQueue.clear()

                try {
                    player?.pause()
                    player?.flush()
                    player?.play()
                } catch (_: Exception) {
                }
            }

            if (
                bytes.isEmpty() ||
                bytes.size % 2 != 0
            ) {
                throw AudioFailure(
                    "AUDIO_PLAYBACK_FAILED",
                    "Invalid PCM audio chunk"
                )
            }

            if (!playbackQueue.offer(bytes.copyOf())) {
                throw AudioFailure(
                    "AUDIO_PLAYBACK_FAILED",
                    "Playback queue is full"
                )
            }
        }
    }

    // ============================================================
    // PLAY PCM AUDIO
    // ============================================================

    private fun playbackLoop() {
        while (playing.get()) {
            val chunk = try {
                playbackQueue.take()
            } catch (_: InterruptedException) {
                break
            }

            val track = synchronized(lock) {
                player
            } ?: break

            var offset = 0

            val chunkGeneration = synchronized(lock) {
                generation
            }

            while (
                offset < chunk.size &&
                playing.get()
            ) {
                if (
                    synchronized(lock) {
                        chunkGeneration != generation
                    }
                ) {
                    break
                }

                val bytesWritten = try {
                    track.write(
                        chunk,
                        offset,
                        minOf(
                            1920,
                            chunk.size - offset
                        ),
                        AudioTrack.WRITE_BLOCKING
                    )
                } catch (_: Exception) {
                    break
                }

                if (bytesWritten <= 0) {
                    break
                }

                offset += bytesWritten
            }
        }
    }

    // ============================================================
    // INTERRUPT / CLEAR PLAYBACK
    // ============================================================

    private fun clearPlayback(
        requestedGeneration: Int
    ) {
        synchronized(lock) {
            // Match the generation supplied by Flutter.
            generation = maxOf(
                generation,
                requestedGeneration
            )

            playbackQueue.clear()

            try {
                player?.pause()
                player?.flush()
                player?.play()
            } catch (_: Exception) {
            }
        }
    }

    // ============================================================
    // DISPOSE AUDIO RESOURCES
    // ============================================================

    fun dispose() {
        if (disposed) return

        disposed = true

        stopMicrophone()

        playing.set(false)

        playbackThread?.interrupt()
        playbackThread = null

        synchronized(lock) {
            playbackQueue.clear()

            try {
                player?.pause()
                player?.flush()
                player?.release()
            } catch (_: Exception) {
            }

            player = null
            initialized = false
            sink = null

            try {
                if (
                    Build.VERSION.SDK_INT >=
                    Build.VERSION_CODES.O
                ) {
                    focusRequest?.let {
                        audioManager.abandonAudioFocusRequest(it)
                    }
                } else if (legacyFocusGranted) {
                    @Suppress("DEPRECATION")
                    audioManager.abandonAudioFocus(null)
                }

                priorMode?.let {
                    audioManager.mode = it
                }

                priorSpeakerphone?.let {
                    audioManager.isSpeakerphoneOn = it
                }

            } catch (_: Exception) {
            }
        }

        focusRequest = null
        legacyFocusGranted = false
    }

    // ============================================================
    // DETACH PLATFORM CHANNELS
    // ============================================================

    fun detach() {
        dispose()

        methods.setMethodCallHandler(null)
        microphoneEvents.setStreamHandler(null)
    }

    // ============================================================
    // INTERNAL EXCEPTION
    // ============================================================

    private class AudioFailure(
        val code: String,
        override val message: String
    ) : RuntimeException(message)
}