import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum LiveAudioState {
  idle,
  initializing,
  ready,
  recording,
  stopped,
  error,
  disposed,
}

class LiveAudioException implements Exception {
  final String message;
  final bool permissionDenied;

  const LiveAudioException(this.message, {this.permissionDenied = false});

  @override
  String toString() => message;
}

/// Full-duplex PCM audio service for Rhea AI Gemini Live.
///
/// Android implementation:
/// - AudioRecord: 16 kHz, mono, PCM16 microphone input.
/// - AudioTrack: 24 kHz, mono, PCM16 speaker output.
///
/// Native platform channels must be implemented separately.
class LiveAudioService {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.rheaai.healthcoach/live_audio',
  );

  static const EventChannel _microphoneChannel = EventChannel(
    'com.rheaai.healthcoach/live_audio/microphone',
  );

  static const int microphoneSampleRate = 16000;
  static const int speakerSampleRate = 24000;
  static const int channelCount = 1;
  static const int bytesPerSample = 2;

  final StreamController<Uint8List> _microphoneController =
      StreamController<Uint8List>.broadcast(sync: true);

  final StreamController<LiveAudioState> _stateController =
      StreamController<LiveAudioState>.broadcast();

  StreamSubscription<dynamic>? _microphoneSubscription;

  LiveAudioState _state = LiveAudioState.idle;

  bool _initialized = false;
  bool _recording = false;
  bool _muted = false;
  bool _disposed = false;

  /// Incremented when playback is interrupted or reset.
  ///
  /// Used to invalidate pending Dart-side playback requests.
  int _playbackGeneration = 0;

  /// Serializes playback submissions to the native platform.
  Future<void> _playbackTail = Future<void>.value();

  LiveAudioState get state => _state;

  bool get isInitialized => _initialized;

  bool get isRecording => _recording;

  bool get isMuted => _muted;

  bool get isDisposed => _disposed;

  Stream<Uint8List> get microphoneStream => _microphoneController.stream;

  Stream<LiveAudioState> get stateStream => _stateController.stream;

  void _setState(LiveAudioState next) {
    if (_disposed || _state == next) return;

    _state = next;

    if (!_stateController.isClosed) {
      _stateController.add(next);
    }
  }

  void _ensureActive() {
    if (_disposed) {
      throw const LiveAudioException(
        'Audio service has already been disposed.',
      );
    }
  }

  /// Initialize the native audio engine.
  ///
  /// This does not start microphone recording.
  Future<void> initialize() async {
    _ensureActive();

    if (_initialized) return;

    _setState(LiveAudioState.initializing);

    try {
      await _methodChannel.invokeMethod<void>('initialize', {
        'inputSampleRate': microphoneSampleRate,
        'outputSampleRate': speakerSampleRate,
        'channels': channelCount,
      });

      _initialized = true;
      _setState(LiveAudioState.ready);
    } on MissingPluginException {
      _setState(LiveAudioState.error);

      throw const LiveAudioException('Native audio engine is not installed.');
    } on PlatformException catch (error) {
      _setState(LiveAudioState.error);

      throw LiveAudioException(
        _friendlyError(error),
        permissionDenied: error.code == 'MIC_PERMISSION_DENIED',
      );
    } catch (_) {
      _setState(LiveAudioState.error);

      throw const LiveAudioException('Unable to initialize the audio engine.');
    }
  }

  /// Start streaming microphone PCM16 audio.
  ///
  /// The native layer must:
  /// - Check RECORD_AUDIO permission.
  /// - Configure mono PCM16 recording at 16 kHz.
  /// - Emit Uint8List-compatible byte buffers.
  /// - Keep recording active during speaker playback.
  Future<void> startMicrophone() async {
    _ensureActive();

    if (!_initialized) {
      await initialize();
    }

    if (_recording) return;

    try {
      _microphoneSubscription = _microphoneChannel
          .receiveBroadcastStream()
          .listen(
            _handleMicrophoneData,
            onError: (Object error) {
              debugPrint('RHEA AUDIO: Microphone stream error.');

              _recording = false;
              _setState(LiveAudioState.error);
            },
            onDone: () {
              _recording = false;

              if (!_disposed) {
                _setState(LiveAudioState.stopped);
              }
            },
            cancelOnError: false,
          );

      await _methodChannel.invokeMethod<void>('startMicrophone');

      _recording = true;
      _setState(LiveAudioState.recording);
    } on PlatformException catch (error) {
      await _cancelMicrophoneSubscription();

      _recording = false;
      _setState(LiveAudioState.error);

      throw LiveAudioException(
        _friendlyError(error),
        permissionDenied: error.code == 'MIC_PERMISSION_DENIED',
      );
    } on MissingPluginException {
      await _cancelMicrophoneSubscription();

      _recording = false;
      _setState(LiveAudioState.error);

      throw const LiveAudioException(
        'Native microphone implementation is unavailable.',
      );
    } catch (_) {
      await _cancelMicrophoneSubscription();

      _recording = false;
      _setState(LiveAudioState.error);

      throw const LiveAudioException('Unable to start microphone recording.');
    }
  }

  void _handleMicrophoneData(dynamic data) {
    if (_disposed || !_recording || _muted) {
      return;
    }

    Uint8List? pcm;

    if (data is Uint8List) {
      pcm = data;
    } else if (data is List<int>) {
      pcm = Uint8List.fromList(data);
    }

    if (pcm == null || pcm.isEmpty) {
      return;
    }

    // PCM16 samples occupy two bytes.
    if (pcm.lengthInBytes.isOdd) {
      debugPrint('RHEA AUDIO: Dropped malformed microphone chunk.');
      return;
    }

    if (!_microphoneController.isClosed) {
      _microphoneController.add(pcm);
    }
  }

  /// Mute microphone transmission without ending the recording.
  ///
  /// Muting locally drops microphone chunks.
  Future<void> setMuted(bool muted) async {
    _ensureActive();

    _muted = muted;
  }

  /// Stop microphone capture.
  Future<void> stopMicrophone() async {
    if (_disposed) return;

    // Mark stopped before awaiting native cleanup so no new
    // microphone data is forwarded during shutdown.
    _recording = false;

    try {
      if (_initialized) {
        await _methodChannel.invokeMethod<void>('stopMicrophone');
      }
    } on PlatformException {
      debugPrint('RHEA AUDIO: Native microphone stop failed.');
    } on MissingPluginException {
      debugPrint('RHEA AUDIO: Native microphone stop unavailable.');
    } finally {
      await _cancelMicrophoneSubscription();

      if (!_disposed) {
        _setState(LiveAudioState.stopped);
      }
    }
  }

  Future<void> _cancelMicrophoneSubscription() async {
    final subscription = _microphoneSubscription;
    _microphoneSubscription = null;

    try {
      await subscription?.cancel();
    } catch (_) {
      // Continue cleanup.
    }
  }

  /// Queue one assistant PCM16 audio chunk for playback.
  ///
  /// Audio format:
  /// - 24 kHz
  /// - mono
  /// - signed 16-bit little-endian PCM
  ///
  /// The native layer must maintain a bounded low-latency queue.
  ///
  /// This method does not wait for the audio to finish playing.
  Future<void> playAudioChunk(Uint8List pcm) async {
    _ensureActive();

    if (!_initialized) {
      throw const LiveAudioException('Audio service is not initialized.');
    }

    if (pcm.isEmpty) return;

    if (pcm.lengthInBytes.isOdd) {
      throw const LiveAudioException('Invalid PCM16 playback chunk.');
    }

    final generation = _playbackGeneration;

    // Copy the buffer because the caller may reuse its memory.
    final audioBytes = Uint8List.fromList(pcm);

    final previous = _playbackTail;

    final operation = previous.then((_) async {
      if (_disposed || !_initialized || generation != _playbackGeneration) {
        return;
      }

      try {
        await _methodChannel.invokeMethod<void>('playAudioChunk', {
          'audio': audioBytes,
          'generation': generation,
        });
      } on PlatformException catch (error) {
        if (generation != _playbackGeneration) {
          return;
        }

        throw LiveAudioException(_friendlyError(error));
      } on MissingPluginException {
        throw const LiveAudioException('Native audio playback is unavailable.');
      }
    });

    // Keep the internal chain usable even when one chunk fails.
    _playbackTail = operation.catchError((Object _) {});

    return operation;
  }

  /// Immediately interrupt Rhea's audio.
  ///
  /// Must:
  /// - Invalidate pending Dart playback submissions.
  /// - Clear native queued audio.
  /// - Stop currently audible output.
  ///
  /// The native implementation will enforce generation checks too.
  Future<void> interruptPlayback() async {
    if (_disposed) return;

    _playbackGeneration++;

    if (!_initialized) return;

    try {
      await _methodChannel.invokeMethod<void>('interruptPlayback', {
        'generation': _playbackGeneration,
      });
    } on PlatformException {
      debugPrint('RHEA AUDIO: Unable to interrupt native playback.');
    } on MissingPluginException {
      debugPrint('RHEA AUDIO: Native playback interruption unavailable.');
    }
  }

  /// Stop speaker playback and clear its queued audio.
  Future<void> stopPlayback() async {
    if (_disposed) return;

    _playbackGeneration++;

    if (!_initialized) return;

    try {
      await _methodChannel.invokeMethod<void>('stopPlayback', {
        'generation': _playbackGeneration,
      });
    } on PlatformException {
      debugPrint('RHEA AUDIO: Unable to stop native playback.');
    } on MissingPluginException {
      debugPrint('RHEA AUDIO: Native playback stop unavailable.');
    }
  }

  /// Release audio resources after the call ends.
  ///
  /// Safe to call more than once.
  Future<void> dispose() async {
    if (_disposed) return;

    // Block new audio immediately.
    _disposed = true;
    _recording = false;
    _playbackGeneration++;

    try {
      await _methodChannel.invokeMethod<void>('dispose');
    } catch (_) {
      debugPrint('RHEA AUDIO: Native audio cleanup encountered an error.');
    }

    await _cancelMicrophoneSubscription();

    _initialized = false;
    _state = LiveAudioState.disposed;

    await _microphoneController.close();
    await _stateController.close();
  }

  String _friendlyError(PlatformException error) {
    switch (error.code) {
      case 'MIC_PERMISSION_DENIED':
        return 'Microphone permission is required to talk to Rhea. '
            'Please allow microphone access in Settings.';

      case 'MIC_UNAVAILABLE':
        return 'Your microphone is unavailable. '
            'Please close other recording apps and try again.';

      case 'AUDIO_INIT_FAILED':
        return 'Unable to initialize voice audio. Please try again.';

      case 'AUDIO_PLAYBACK_FAILED':
        return 'Unable to play Rhea voice audio. Please try again.';

      case 'AUDIO_RECORD_FAILED':
        return 'Unable to record your voice. Please try again.';

      default:
        return 'A voice audio error occurred. Please try again.';
    }
  }
}
