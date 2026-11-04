import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/models/gemini_live_event_model.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/gemini_live_service.dart';
import '../../data/services/live_audio_service.dart';
import '../../data/services/voice_transcript_service.dart';

enum RheaLiveCallStatus {
  idle,
  connecting,
  connected,
  reconnecting,
  ending,
  ended,
  failed,
}

/// Owns one Gemini Live call at a time. Does not alter the legacy AiController.
class RheaLiveCallController extends GetxController
    with WidgetsBindingObserver {
  RheaLiveCallController({AiService? api}) : _api = api ?? AiService();

  final AiService _api;

  final status = RheaLiveCallStatus.idle.obs;
  final errorMessage = ''.obs;
  final sessionId = ''.obs;
  final isMuted = false.obs;
  final isRheaSpeaking = false.obs;
  final lastUserTranscript = ''.obs;
  final lastRheaTranscript = ''.obs;
  final elapsedSeconds = 0.obs;
  final hasUnsavedTranscripts = false.obs;

  GeminiLiveService? _socket;
  LiveAudioService? _audio;
  VoiceTranscriptService? _transcripts;
  StreamSubscription<GeminiLiveEventModel>? _eventsSubscription;
  StreamSubscription<Uint8List>? _microphoneSubscription;
  StreamSubscription<GeminiLiveConnectionState>? _connectionSubscription;
  Timer? _durationTimer;

  // Each call attempt has its own generation. Late async callbacks are ignored.
  int _generation = 0;
  bool _ending = false;
  bool _disposed = false;
  bool _recoveryRunning = false;
  bool _receivedAudioThisTurn = false;
  String _pendingUser = '';
  String _pendingAi = '';
  Future<void>? _endFuture;

  bool get isActive =>
      status.value == RheaLiveCallStatus.connected ||
      status.value == RheaLiveCallStatus.connecting ||
      status.value == RheaLiveCallStatus.reconnecting;

  String get formattedDuration {
    final minutes = elapsedSeconds.value ~/ 60;
    final seconds = elapsedSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The native recorder is foreground-only. Never leave it running after
    // the app moves to the background. A new call needs a new token.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (isActive) unawaited(endCall());
    }
  }

  /// Returns false when microphone permission is unavailable.
  Future<bool> _ensureMicrophonePermission() async {
    var permission = await Permission.microphone.status;
    if (permission.isGranted) return true;
    permission = await Permission.microphone.request();
    if (permission.isGranted) return true;
    errorMessage.value = permission.isPermanentlyDenied
        ? 'Microphone access is disabled. Enable it in app settings to call Rhea.'
        : 'Microphone permission is required to speak with Rhea.';
    return false;
  }

  /// Starts a new call. If the previous call failed, call endCall first.
  Future<bool> startCall() async {
    if (_disposed || _ending || isActive) return false;

    // Clear any previous failed/ended call and its resources.
    await endCall();
    if (_disposed) return false;

    errorMessage.value = '';
    hasUnsavedTranscripts.value = false;
    lastUserTranscript.value = '';
    lastRheaTranscript.value = '';
    elapsedSeconds.value = 0;
    isMuted.value = false;
    _pendingUser = '';
    _pendingAi = '';
    _receivedAudioThisTurn = false;

    if (!await _ensureMicrophonePermission()) {
      status.value = RheaLiveCallStatus.failed;
      return false;
    }

    status.value = RheaLiveCallStatus.connecting;
    final generation = ++_generation;

    try {
      await _connectFreshSession(generation);
      if (generation != _generation || _ending) return false;
      status.value = RheaLiveCallStatus.connected;
      _startTimer();
      return true;
    } catch (error) {
      if (generation == _generation && !_ending) {
        errorMessage.value = _friendlyError(error);
        status.value = RheaLiveCallStatus.failed;
        await _releaseCurrentResources(endBackendSession: true);
      }
      return false;
    }
  }

  Future<void> _connectFreshSession(int generation) async {
    // A failed token is never reused. This call obtains a new token/session.
    final session = await _api.startGeminiLiveSession();
    if (generation != _generation || _ending || _disposed) {
      // If an in-flight HTTP response arrives after hang-up, close it.
      unawaited(_endBackendSafely(session.sessionId));
      return;
    }

    sessionId.value = session.sessionId;
    _transcripts = VoiceTranscriptService()..initialize(session.sessionId);

    final socket = GeminiLiveService();
    final audio = LiveAudioService();
    _socket = socket;
    _audio = audio;

    _eventsSubscription = socket.events.listen((event) {
      if (generation == _generation && !_ending && !_disposed) {
        _handleEvent(event, generation);
      }
    });

    _connectionSubscription = socket.connectionStates.listen((state) {
      if (generation != _generation || _ending || _disposed) {
        return;
      }

      if (state == GeminiLiveConnectionState.failed &&
          status.value == RheaLiveCallStatus.connected) {
        _scheduleRecovery(generation);
      }
    });

    // Connect and wait for setupComplete before streaming any audio.
    await socket.connect(session);
    if (generation != _generation || _ending || _disposed) return;

    await audio.initialize();
    if (generation != _generation || _ending || _disposed) return;

    _microphoneSubscription = audio.microphoneStream.listen((pcm) {
      if (generation == _generation &&
          !_ending &&
          socket.isReady &&
          !isMuted.value) {
        try {
          socket.sendAudioChunk(pcm);
        } catch (_) {
          _scheduleRecovery(generation);
        }
      }
    });

    await audio.startMicrophone();
  }

  void _handleEvent(GeminiLiveEventModel event, int generation) {
    switch (event.type) {
      case GeminiLiveEventType.audio:
        final pcm = event.audioData;
        if (pcm != null && pcm.isNotEmpty) {
          _receivedAudioThisTurn = true;
          isRheaSpeaking.value = true;
          final audio = _audio;
          if (audio != null) {
            unawaited(
              audio.playAudioChunk(pcm).catchError((Object _) {
                if (generation == _generation && !_ending) {
                  errorMessage.value = 'Rhea audio playback was interrupted.';
                }
              }),
            );
          }
        }
        break;

      case GeminiLiveEventType.inputTranscription:
        _pendingUser = _appendTranscript(_pendingUser, event.transcript);
        break;

      case GeminiLiveEventType.outputTranscription:
        _pendingAi = _appendTranscript(_pendingAi, event.transcript);
        break;

      case GeminiLiveEventType.turnComplete:
        _commitPendingTurns();
        isRheaSpeaking.value = false;
        _receivedAudioThisTurn = false;
        break;

      case GeminiLiveEventType.interrupted:
        // Do not save unfinished AI text as a completed response.
        _commitUserTurn();
        _pendingAi = '';
        isRheaSpeaking.value = false;
        _receivedAudioThisTurn = false;
        final audio = _audio;
        if (audio != null) unawaited(audio.interruptPlayback());
        break;

      case GeminiLiveEventType.goAway:
        _scheduleRecovery(generation);
        break;

      case GeminiLiveEventType.error:
        _scheduleRecovery(generation);
        break;

      default:
        break;
    }
  }

  // Gemini can send transcription segments. We append segments and only
  // persist at a completed turn boundary, not on each partial event.
  String _appendTranscript(String previous, String? segment) {
    final text = segment?.trim() ?? '';
    if (text.isEmpty) return previous;
    if (previous.isEmpty) return text;
    if (text == previous) return previous;
    // Some servers resend the entire growing transcript.
    if (text.startsWith(previous)) return text;
    if (previous.endsWith(text)) return previous;
    return '$previous $text';
  }

  void _commitUserTurn() {
    final text = _pendingUser.trim();
    _pendingUser = '';
    if (text.isEmpty) return;
    lastUserTranscript.value = text;
    final accepted =
        _transcripts?.enqueue(
          sender: VoiceTranscriptSender.user,
          transcript: text,
        ) ??
        false;
    if (!accepted) hasUnsavedTranscripts.value = true;
  }

  void _commitPendingTurns() {
    _commitUserTurn();
    final text = _pendingAi.trim();
    _pendingAi = '';
    if (text.isEmpty) return;
    lastRheaTranscript.value = text;
    final accepted =
        _transcripts?.enqueue(
          sender: VoiceTranscriptSender.ai,
          transcript: text,
        ) ??
        false;
    if (!accepted) hasUnsavedTranscripts.value = true;
  }

  Future<void> toggleMute() async {
    if (!isActive || _ending) return;
    final next = !isMuted.value;
    await _audio?.setMuted(next);
    isMuted.value = next;
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_ending && status.value == RheaLiveCallStatus.connected) {
        elapsedSeconds.value++;
      }
    });
  }

  /// Bounded recovery: at most two new backend sessions.
  /// Old sockets and tokens are discarded before each retry.
  void _scheduleRecovery(int failedGeneration) {
    if (_recoveryRunning ||
        _ending ||
        _disposed ||
        failedGeneration != _generation)
      return;
    _recoveryRunning = true;
    unawaited(_recover(failedGeneration));
  }

  Future<void> _recover(int failedGeneration) async {
    status.value = RheaLiveCallStatus.reconnecting;
    var generation = failedGeneration;
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        if (_ending || _disposed || generation != _generation) return;
        // Flush final text, end previous backend session and release audio.
        _commitPendingTurns();
        await _releaseCurrentResources(endBackendSession: true);
        if (_ending || _disposed || generation != _generation) return;
        await Future<void>.delayed(Duration(seconds: attempt + 1));
        if (_ending || _disposed || generation != _generation) return;
        generation = ++_generation;
        try {
          await _connectFreshSession(generation);
          if (_ending || _disposed || generation != _generation) return;
          status.value = RheaLiveCallStatus.connected;
          return;
        } catch (_) {
          // Retry only with a newly issued backend session.
        }
      }
      if (!_ending && !_disposed) {
        status.value = RheaLiveCallStatus.failed;
        errorMessage.value = 'Rhea disconnected. Please start a new call.';
        await _releaseCurrentResources(endBackendSession: true);
      }
    } finally {
      _recoveryRunning = false;
    }
  }

  Future<void> endCall() {
    if (_endFuture != null) return _endFuture!;
    final future = _endCallInternal();
    _endFuture = future;
    return future.whenComplete(() => _endFuture = null);
  }

  Future<void> _endCallInternal() async {
    _ending = true;
    ++_generation; // Invalidate all outstanding async callbacks.
    status.value = RheaLiveCallStatus.ending;
    _durationTimer?.cancel();
    _durationTimer = null;

    try {
      _commitPendingTurns();
      // Stop microphone first, before closing the socket.
      try {
        await _audio?.stopMicrophone();
      } catch (_) {}
      try {
        _socket?.sendAudioStreamEnd();
      } catch (_) {}
      await _releaseCurrentResources(endBackendSession: true);
    } finally {
      isRheaSpeaking.value = false;
      isMuted.value = false;
      sessionId.value = '';
      status.value = RheaLiveCallStatus.ended;
      _ending = false;
    }
  }

  Future<void> _releaseCurrentResources({
    required bool endBackendSession,
  }) async {
    final mic = _microphoneSubscription;
    final events = _eventsSubscription;
    final connection = _connectionSubscription;
    final audio = _audio;
    final socket = _socket;
    final transcripts = _transcripts;
    final oldSessionId = sessionId.value;

    _microphoneSubscription = null;
    _eventsSubscription = null;
    _connectionSubscription = null;
    _audio = null;
    _socket = null;
    _transcripts = null;
    sessionId.value = '';

    try {
      await mic?.cancel();
    } catch (_) {}
    try {
      await events?.cancel();
    } catch (_) {}
    try {
      await connection?.cancel();
    } catch (_) {}
    try {
      await audio?.dispose();
    } catch (_) {}
    try {
      await socket?.dispose();
    } catch (_) {}

    if (transcripts != null) {
      try {
        final saved = await transcripts.close(
          timeout: const Duration(seconds: 8),
        );
        if (!saved) hasUnsavedTranscripts.value = true;
      } catch (_) {
        hasUnsavedTranscripts.value = true;
      }
    }
    if (endBackendSession && oldSessionId.isNotEmpty) {
      await _endBackendSafely(oldSessionId);
    }
  }

  Future<void> _endBackendSafely(String id) async {
    try {
      await _api.endGeminiLiveSession(sessionId: id);
    } catch (_) {
      // Local microphone and socket cleanup must never depend on the API.
    }
  }

  String _friendlyError(Object error) {
    if (error is GeminiLiveApiException) return error.message;
    if (error is GeminiLiveSocketException) return error.message;
    if (error is LiveAudioException) return error.message;
    return 'Unable to start the Rhea voice call. Please try again.';
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposed = true;
    unawaited(endCall());
    super.onClose();
  }
}
