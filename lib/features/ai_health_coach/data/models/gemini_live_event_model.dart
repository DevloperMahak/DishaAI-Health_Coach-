import 'dart:convert';
import 'dart:typed_data';

// ============================================================
// GEMINI LIVE EVENT TYPES
// ============================================================

enum GeminiLiveEventType {
  setupComplete,
  audio,
  inputTranscription,
  outputTranscription,
  turnComplete,
  interrupted,
  generationComplete,
  goAway,
  sessionResumption,
  usageMetadata,
  error,
  unknown,
}

// ============================================================
// GEMINI LIVE EVENT MODEL
// ============================================================

class GeminiLiveEventModel {
  final GeminiLiveEventType type;

  /// Decoded assistant PCM audio.
  final Uint8List? audioData;

  /// User or assistant transcription.
  final String? transcript;

  /// Audio MIME type supplied by Gemini.
  final String? mimeType;

  /// Error message when an error event is received.
  final String? errorMessage;

  /// Optional error code.
  final String? errorCode;

  /// Indicates that the assistant turn has completed.
  final bool turnComplete;

  /// Indicates that the assistant was interrupted.
  final bool interrupted;

  /// Optional session resumption information.
  final Map<String, dynamic>? sessionResumption;

  /// Optional server go-away information.
  final Map<String, dynamic>? goAway;

  const GeminiLiveEventModel({
    required this.type,
    this.audioData,
    this.transcript,
    this.mimeType,
    this.errorMessage,
    this.errorCode,
    this.turnComplete = false,
    this.interrupted = false,
    this.sessionResumption,
    this.goAway,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  bool get hasAudio => audioData != null && audioData!.isNotEmpty;

  bool get hasTranscript => transcript != null && transcript!.trim().isNotEmpty;

  bool get isError => type == GeminiLiveEventType.error;

  // ============================================================
  // PARSE WEBSOCKET MESSAGE
  // ============================================================

  /// Parses a Gemini Live WebSocket message.
  ///
  /// Supports:
  /// - JSON text frames.
  /// - UTF-8 encoded JSON binary frames.
  ///
  /// One WebSocket frame can contain multiple events.
  ///
  /// Raw messages are never printed because they may contain
  /// health information, transcripts or audio data.
  static List<GeminiLiveEventModel> parse(dynamic message) {
    try {
      final dynamic decoded;

      if (message is String) {
        decoded = jsonDecode(message);
      } else if (message is List<int>) {
        decoded = jsonDecode(utf8.decode(message));
      } else {
        throw const FormatException(
          'Unsupported Gemini Live WebSocket frame type.',
        );
      }

      if (decoded is! Map) {
        throw const FormatException(
          'Gemini Live message must be a JSON object.',
        );
      }

      final json = Map<String, dynamic>.from(decoded);

      return fromJson(json);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'Unable to parse Gemini Live WebSocket message.',
      );
    }
  }

  // ============================================================
  // CONVERT JSON TO EVENTS
  // ============================================================

  static List<GeminiLiveEventModel> fromJson(Map<String, dynamic> json) {
    final events = <GeminiLiveEventModel>[];

    // ----------------------------------------------------------
    // 1. ERROR
    // ----------------------------------------------------------

    final error = _asMap(json['error']);

    if (error != null) {
      events.add(
        GeminiLiveEventModel(
          type: GeminiLiveEventType.error,
          errorMessage:
              _string(error['message']) ?? 'Gemini Live returned an error.',
          errorCode: _string(error['code']) ?? _string(error['status']),
        ),
      );

      return events;
    }

    // ----------------------------------------------------------
    // 2. SETUP COMPLETE
    // ----------------------------------------------------------

    if (json.containsKey('setupComplete')) {
      events.add(
        const GeminiLiveEventModel(type: GeminiLiveEventType.setupComplete),
      );
    }

    // ----------------------------------------------------------
    // 3. SESSION RESUMPTION
    // ----------------------------------------------------------

    final resumption = _asMap(json['sessionResumptionUpdate']);

    if (resumption != null) {
      events.add(
        GeminiLiveEventModel(
          type: GeminiLiveEventType.sessionResumption,
          sessionResumption: resumption,
        ),
      );
    }

    // ----------------------------------------------------------
    // 4. GO AWAY
    // ----------------------------------------------------------

    final goAway = _asMap(json['goAway']);

    if (goAway != null) {
      events.add(
        GeminiLiveEventModel(type: GeminiLiveEventType.goAway, goAway: goAway),
      );
    }

    // ----------------------------------------------------------
    // 5. USAGE METADATA
    // ----------------------------------------------------------

    if (json.containsKey('usageMetadata')) {
      events.add(
        const GeminiLiveEventModel(type: GeminiLiveEventType.usageMetadata),
      );
    }

    // ----------------------------------------------------------
    // 6. SERVER CONTENT
    // ----------------------------------------------------------

    final serverContent = _asMap(json['serverContent']);

    if (serverContent != null) {
      _parseServerContent(serverContent, events);
    }

    // ----------------------------------------------------------
    // 7. UNKNOWN EVENT
    // ----------------------------------------------------------

    if (events.isEmpty) {
      events.add(const GeminiLiveEventModel(type: GeminiLiveEventType.unknown));
    }

    return events;
  }

  // ============================================================
  // PARSE SERVER CONTENT
  // ============================================================

  static void _parseServerContent(
    Map<String, dynamic> content,
    List<GeminiLiveEventModel> events,
  ) {
    // ----------------------------------------------------------
    // USER TRANSCRIPTION
    // ----------------------------------------------------------

    final inputTranscription = _asMap(content['inputTranscription']);

    if (inputTranscription != null) {
      final text = _string(inputTranscription['text']);

      if (text != null && text.trim().isNotEmpty) {
        events.add(
          GeminiLiveEventModel(
            type: GeminiLiveEventType.inputTranscription,
            transcript: text,
          ),
        );
      }
    }

    // ----------------------------------------------------------
    // RHEA TRANSCRIPTION
    // ----------------------------------------------------------

    final outputTranscription = _asMap(content['outputTranscription']);

    if (outputTranscription != null) {
      final text = _string(outputTranscription['text']);

      if (text != null && text.trim().isNotEmpty) {
        events.add(
          GeminiLiveEventModel(
            type: GeminiLiveEventType.outputTranscription,
            transcript: text,
          ),
        );
      }
    }

    // ----------------------------------------------------------
    // RHEA AUDIO
    // ----------------------------------------------------------

    final modelTurn = _asMap(content['modelTurn']);

    if (modelTurn != null) {
      final parts = modelTurn['parts'];

      if (parts is List) {
        for (final part in parts) {
          final partMap = _asMap(part);

          if (partMap == null) {
            continue;
          }

          final inlineData = _asMap(partMap['inlineData']);

          if (inlineData == null) {
            continue;
          }

          final encoded = _string(inlineData['data']);

          final mimeType = _string(inlineData['mimeType']);

          // Only accept PCM audio.
          if (encoded == null ||
              encoded.isEmpty ||
              mimeType == null ||
              !mimeType.toLowerCase().startsWith('audio/pcm')) {
            continue;
          }

          try {
            final decodedAudio = base64Decode(encoded);

            if (decodedAudio.isEmpty) {
              continue;
            }

            // PCM16 audio must have an even byte count.
            if (decodedAudio.lengthInBytes.isOdd) {
              events.add(
                const GeminiLiveEventModel(
                  type: GeminiLiveEventType.error,
                  errorMessage: 'Received an invalid PCM audio chunk length.',
                ),
              );

              continue;
            }

            events.add(
              GeminiLiveEventModel(
                type: GeminiLiveEventType.audio,
                audioData: decodedAudio,
                mimeType: mimeType,
              ),
            );
          } on FormatException {
            events.add(
              const GeminiLiveEventModel(
                type: GeminiLiveEventType.error,
                errorMessage:
                    'Received an invalid audio chunk from Gemini Live.',
              ),
            );
          }
        }
      }
    }

    // ----------------------------------------------------------
    // INTERRUPTION
    // ----------------------------------------------------------

    if (content['interrupted'] == true) {
      events.add(
        const GeminiLiveEventModel(
          type: GeminiLiveEventType.interrupted,
          interrupted: true,
        ),
      );
    }

    // ----------------------------------------------------------
    // GENERATION COMPLETE
    // ----------------------------------------------------------

    if (content['generationComplete'] == true) {
      events.add(
        const GeminiLiveEventModel(
          type: GeminiLiveEventType.generationComplete,
        ),
      );
    }

    // ----------------------------------------------------------
    // TURN COMPLETE
    // ----------------------------------------------------------

    if (content['turnComplete'] == true) {
      events.add(
        const GeminiLiveEventModel(
          type: GeminiLiveEventType.turnComplete,
          turnComplete: true,
        ),
      );
    }
  }

  // ============================================================
  // CONVERT VALUE TO MAP
  // ============================================================

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is! Map) {
      return null;
    }

    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // CONVERT VALUE TO STRING
  // ============================================================

  static String? _string(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      return value;
    }

    if (value is num) {
      return value.toString();
    }

    return null;
  }

  // ============================================================
  // SAFE DEBUG OUTPUT
  // ============================================================

  /// Avoid logging audio data or health-related transcripts.
  @override
  String toString() {
    return 'GeminiLiveEventModel('
        'type: $type, '
        'hasAudio: $hasAudio, '
        'audioBytes: ${audioData?.lengthInBytes ?? 0}, '
        'hasTranscript: $hasTranscript, '
        'turnComplete: $turnComplete, '
        'interrupted: $interrupted, '
        'errorCode: $errorCode'
        ')';
  }
}
