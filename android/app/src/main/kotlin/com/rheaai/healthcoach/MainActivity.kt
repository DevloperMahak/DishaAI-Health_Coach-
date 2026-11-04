package com.rheaai.healthcoach

import android.os.Build
import android.os.Bundle
import android.view.WindowManager

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    // ============================================================
    // RHEA AI GEMINI LIVE AUDIO ENGINE
    // ============================================================

    private var liveAudioEngine: RheaLiveAudioEngine? = null

    // ============================================================
    // EXISTING ACTIVITY CONFIGURATION
    // ============================================================

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Preserve existing lock-screen functionality.
        // This currently applies whenever MainActivity launches.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
    }

    // ============================================================
    // REGISTER NATIVE AUDIO PLATFORM CHANNELS
    // ============================================================

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register native Android PCM audio engine.
        //
        // MethodChannel:
        // com.rheaai.healthcoach/live_audio
        //
        // EventChannel:
        // com.rheaai.healthcoach/live_audio/microphone

        liveAudioEngine = RheaLiveAudioEngine(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger
        )
    }

    // ============================================================
    // CLEAN UP AUDIO ENGINE
    // ============================================================

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {

        // Release microphone, speaker, audio focus,
        // playback queue and platform channels.
        liveAudioEngine?.detach()

        liveAudioEngine = null

        super.cleanUpFlutterEngine(flutterEngine)
    }
}