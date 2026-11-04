import 'dart:async';
import 'dart:convert';
import '../models/gemini_live_event_model.dart';
import '../models/gemini_live_session_model.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum GeminiLiveConnectionState {
  disconnected,
  connecting,
  connected,
  ready,
  closing,
  failed,
}

class GeminiLiveSocketException implements Exception {
  final String message;
  final bool retryable;

  const GeminiLiveSocketException(this.message, {this.retryable = true});

  @override
  String toString() => message;
}

/// Manages one Gemini Live WebSocket connection.
///
/// This service does not:
/// - Request backend sessions.
/// - Record microphone audio.
/// - Play assistant audio.
/// - Save transcripts.
/// - Automatically reconnect using an expired token.
///
/// Reconnection must request a fresh session from Laravel.
class GeminiLiveService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final StreamController<GeminiLiveEventModel> _eventController =
      StreamController<GeminiLiveEventModel>.broadcast();

  final StreamController<GeminiLiveConnectionState> _stateController =
      StreamController<GeminiLiveConnectionState>.broadcast();

  GeminiLiveConnectionState _state = GeminiLiveConnectionState.disconnected;

  bool _disposed = false;
  bool _closing = false;

  int _connectionGeneration = 0;

  Completer<void>? _setupCompleter;

  GeminiLiveConnectionState get state => _state;

  bool get isReady => _state == GeminiLiveConnectionState.ready;

  Stream<GeminiLiveEventModel> get events => _eventController.stream;

  Stream<GeminiLiveConnectionState> get connectionStates =>
      _stateController.stream;

  void _updateState(GeminiLiveConnectionState state) {
    if (_disposed || _state == state) return;

    _state = state;

    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// Connect using a newly issued, one-time backend token.
  ///
  /// Do not call connect twice with the same session.
  Future<void> connect(
    GeminiLiveSessionModel session, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_disposed) {
      throw const GeminiLiveSocketException(
        'Voice connection has been disposed.',
        retryable: false,
      );
    }

    if (_channel != null ||
        _state == GeminiLiveConnectionState.connecting ||
        _state == GeminiLiveConnectionState.connected ||
        _state == GeminiLiveConnectionState.ready) {
      throw const GeminiLiveSocketException(
        'A voice connection is already active.',
        retryable: false,
      );
    }

    _closing = false;
    _connectionGeneration++;

    final generation = _connectionGeneration;

    _updateState(GeminiLiveConnectionState.connecting);

    final setupCompleter = Completer<void>();
    _setupCompleter = setupCompleter;

    try {
      final originalUri = Uri.parse(session.websocketUrl);

      if (originalUri.scheme != 'wss') {
        throw const GeminiLiveSocketException(
          'Gemini Live requires a secure WebSocket.',
          retryable: false,
        );
      }

      final query = Map<String, String>.from(originalUri.queryParameters);

      query['access_token'] = session.token;

      final uri = originalUri.replace(queryParameters: query);

      final channel = WebSocketChannel.connect(uri);

      _channel = channel;

      _subscription = channel.stream.listen(
        (message) {
          if (_disposed || _closing || generation != _connectionGeneration) {
            return;
          }

          _handleMessage(message, generation);
        },
        onError: (Object error, StackTrace stackTrace) {
          _handleConnectionFailure(
            generation,
            'Rhea voice connection was interrupted.',
          );
        },
        onDone: () {
          if (_closing || generation != _connectionGeneration) {
            return;
          }

          _handleConnectionFailure(
            generation,
            'Rhea voice connection closed unexpectedly.',
          );
        },
        cancelOnError: true,
      );

      // Wait for the underlying WebSocket handshake.
      await channel.ready.timeout(timeout);

      if (_disposed || _closing || generation != _connectionGeneration) {
        throw const GeminiLiveSocketException(
          'Voice connection was cancelled.',
          retryable: false,
        );
      }

      _updateState(GeminiLiveConnectionState.connected);

      // Forward the backend-provided setup without modification.
      channel.sink.add(jsonEncode({'setup': session.setup}));

      // Gemini confirms setup through setupComplete.
      await setupCompleter.future.timeout(timeout);

      if (_disposed || _closing || generation != _connectionGeneration) {
        throw const GeminiLiveSocketException(
          'Voice connection was cancelled.',
          retryable: false,
        );
      }

      _updateState(GeminiLiveConnectionState.ready);

      debugPrint('RHEA LIVE: WebSocket setup completed.');
    } on TimeoutException {
      await _abortConnection(generation);

      throw const GeminiLiveSocketException(
        'Rhea voice connection timed out. Please try again.',
      );
    } on GeminiLiveSocketException {
      await _abortConnection(generation);
      rethrow;
    } catch (_) {
      await _abortConnection(generation);

      throw const GeminiLiveSocketException(
        'Unable to connect to Rhea Live. Please try again.',
      );
    }
  }

  void _handleMessage(dynamic message, int generation) {
    try {
      final parsedEvents = GeminiLiveEventModel.parse(message);

      for (final event in parsedEvents) {
        if (_disposed || _closing || generation != _connectionGeneration) {
          return;
        }

        if (event.type == GeminiLiveEventType.setupComplete) {
          final completer = _setupCompleter;

          if (completer != null && !completer.isCompleted) {
            completer.complete();
          }
        }

        if (event.type == GeminiLiveEventType.error) {
          final completer = _setupCompleter;

          if (completer != null && !completer.isCompleted) {
            completer.completeError(
              const GeminiLiveSocketException(
                'Gemini Live rejected the connection.',
              ),
            );
          }
        }

        if (!_eventController.isClosed) {
          _eventController.add(event);
        }
      }
    } on FormatException {
      // Malformed messages are reported without logging their content.
      if (!_eventController.isClosed) {
        _eventController.add(
          const GeminiLiveEventModel(
            type: GeminiLiveEventType.error,
            errorMessage: 'Invalid Gemini Live message received.',
          ),
        );
      }
    } catch (_) {
      if (!_eventController.isClosed) {
        _eventController.add(
          const GeminiLiveEventModel(
            type: GeminiLiveEventType.error,
            errorMessage: 'Unable to process a Rhea Live event.',
          ),
        );
      }
    }
  }

  void _handleConnectionFailure(int generation, String message) {
    if (_disposed || _closing || generation != _connectionGeneration) {
      return;
    }

    final completer = _setupCompleter;

    if (completer != null && !completer.isCompleted) {
      completer.completeError(GeminiLiveSocketException(message));
    }

    _updateState(GeminiLiveConnectionState.failed);

    if (!_eventController.isClosed) {
      _eventController.add(
        GeminiLiveEventModel(
          type: GeminiLiveEventType.error,
          errorMessage: message,
        ),
      );
    }
  }

  /// Send raw signed 16-bit little-endian PCM microphone audio.
  ///
  /// Audio must be mono at 16,000 Hz.
  ///
  /// The audio recorder service will supply correctly formatted chunks.
  void sendAudioChunk(Uint8List pcmAudio) {
    if (!isReady || _channel == null || _closing || _disposed) {
      return;
    }

    if (pcmAudio.isEmpty) {
      return;
    }

    if (pcmAudio.lengthInBytes.isOdd) {
      throw const GeminiLiveSocketException(
        'Invalid PCM audio chunk length.',
        retryable: false,
      );
    }

    final encoded = base64Encode(pcmAudio);

    try {
      _channel!.sink.add(
        jsonEncode({
          'realtimeInput': {
            'audio': {'data': encoded, 'mimeType': 'audio/pcm;rate=16000'},
          },
        }),
      );
    } catch (_) {
      throw const GeminiLiveSocketException(
        'Unable to stream microphone audio.',
      );
    }
  }

  /// Signal that the microphone audio stream has ended.
  ///
  /// This is normally sent during hang-up.
  void sendAudioStreamEnd() {
    if (!isReady || _channel == null || _closing || _disposed) {
      return;
    }

    try {
      _channel!.sink.add(
        jsonEncode({
          'realtimeInput': {'audioStreamEnd': true},
        }),
      );
    } catch (_) {
      // Hang-up cleanup must continue even if sending fails.
    }
  }

  /// Close the WebSocket connection safely.
  Future<void> disconnect() async {
    if (_disposed) return;

    _closing = true;
    _connectionGeneration++;

    _updateState(GeminiLiveConnectionState.closing);

    final completer = _setupCompleter;

    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        const GeminiLiveSocketException(
          'Voice connection was closed.',
          retryable: false,
        ),
      );
    }

    _setupCompleter = null;

    final subscription = _subscription;
    final channel = _channel;

    _subscription = null;
    _channel = null;

    try {
      await subscription?.cancel();
    } catch (_) {}

    try {
      await channel?.sink.close();
    } catch (_) {}

    _closing = false;

    _updateState(GeminiLiveConnectionState.disconnected);
  }

  Future<void> _abortConnection(int generation) async {
    if (generation != _connectionGeneration) return;

    await disconnect();
  }

  /// Release all resources.
  Future<void> dispose() async {
    if (_disposed) return;

    await disconnect();

    _disposed = true;

    await _eventController.close();
    await _stateController.close();
  }
}
