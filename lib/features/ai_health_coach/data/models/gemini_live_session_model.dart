class GeminiLiveSessionModel {
  final String sessionId;
  final String token;
  final String websocketUrl;

  /// Gemini setup provided by the backend.
  ///
  /// Forward this object unchanged in the WebSocket setup message.
  final Map<String, dynamic> setup;

  final GeminiLiveAudioConfig inputAudio;
  final GeminiLiveAudioConfig outputAudio;

  const GeminiLiveSessionModel({
    required this.sessionId,
    required this.token,
    required this.websocketUrl,
    required this.setup,
    required this.inputAudio,
    required this.outputAudio,
  });

  // ============================================================
  // PARSE BACKEND RESPONSE
  // ============================================================

  factory GeminiLiveSessionModel.fromJson(Map<String, dynamic> json) {
    // Accept both:
    // 1. Full API response: {"data": {...}}
    // 2. Already-unwrapped response: {...}
    //
    // This avoids problems if the API service has already extracted
    // the "data" object.
    final Map<String, dynamic> data;

    if (json.containsKey('data')) {
      data = _requireMap(json['data'], 'data');
    } else {
      data = json;
    }

    final sessionId = _requireString(data['session_id'], 'session_id');

    final token = _requireString(data['token'], 'token');

    final websocketUrl = _requireString(data['websocket_url'], 'websocket_url');

    final setup = _requireMap(data['setup'], 'setup');

    final inputAudio = GeminiLiveAudioConfig.fromJson(
      _requireMap(data['input_audio'], 'input_audio'),
      defaultSampleRate: 16000,
    );

    final outputAudio = GeminiLiveAudioConfig.fromJson(
      _requireMap(data['output_audio'], 'output_audio'),
      defaultSampleRate: 24000,
    );

    // ----------------------------------------------------------
    // VALIDATE WEBSOCKET URL
    // ----------------------------------------------------------

    final uri = Uri.tryParse(websocketUrl);

    if (uri == null ||
        uri.scheme != 'wss' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Invalid secure Gemini Live WebSocket URL.');
    }

    // ----------------------------------------------------------
    // VALIDATE NATIVE AUDIO COMPATIBILITY
    // ----------------------------------------------------------

    // The Android AudioRecord implementation records:
    // PCM16, mono, 16000 Hz.
    if (inputAudio.sampleRate != 16000) {
      throw const FormatException(
        'Unsupported microphone sample rate. Expected 16000 Hz.',
      );
    }

    // The Android AudioTrack implementation plays:
    // PCM16, mono, 24000 Hz.
    if (outputAudio.sampleRate != 24000) {
      throw const FormatException(
        'Unsupported playback sample rate. Expected 24000 Hz.',
      );
    }

    if (inputAudio.channels != 1 || outputAudio.channels != 1) {
      throw const FormatException('Gemini Live requires mono audio.');
    }

    return GeminiLiveSessionModel(
      sessionId: sessionId,
      token: token,
      websocketUrl: websocketUrl,
      setup: setup,
      inputAudio: inputAudio,
      outputAudio: outputAudio,
    );
  }

  // ============================================================
  // REQUIRED STRING
  // ============================================================

  static String _requireString(dynamic value, String field) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing or invalid Gemini Live field: $field');
    }

    return value.trim();
  }

  // ============================================================
  // REQUIRED MAP
  // ============================================================

  static Map<String, dynamic> _requireMap(dynamic value, String field) {
    if (value is! Map) {
      throw FormatException('Missing or invalid Gemini Live object: $field');
    }

    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      throw FormatException('Invalid Gemini Live object structure: $field');
    }
  }

  // ============================================================
  // SAFE DEBUG OUTPUT
  // ============================================================

  /// Never expose ephemeral credentials or the full WebSocket URL.
  @override
  String toString() {
    return 'GeminiLiveSessionModel('
        'sessionId: $sessionId, '
        'token: [REDACTED], '
        'websocketUrl: [REDACTED], '
        'setup: [REDACTED], '
        'inputAudio: $inputAudio, '
        'outputAudio: $outputAudio'
        ')';
  }
}

// ============================================================
// GEMINI LIVE AUDIO CONFIGURATION
// ============================================================

class GeminiLiveAudioConfig {
  final int sampleRate;
  final int channels;
  final String mimeType;

  const GeminiLiveAudioConfig({
    required this.sampleRate,
    required this.channels,
    required this.mimeType,
  });

  factory GeminiLiveAudioConfig.fromJson(
    Map<String, dynamic> json, {
    required int defaultSampleRate,
  }) {
    final sampleRate = _parseSampleRate(json, defaultSampleRate);

    final channels = _parseChannels(json);

    final providedMimeType = json['mime_type'] ?? json['mimeType'];

    final mimeType =
        providedMimeType is String && providedMimeType.trim().isNotEmpty
        ? providedMimeType.trim()
        : 'audio/pcm;rate=$sampleRate';

    // ----------------------------------------------------------
    // VALIDATE SAMPLE RATE
    // ----------------------------------------------------------

    if (sampleRate <= 0) {
      throw const FormatException('Invalid Gemini Live audio sample rate.');
    }

    // ----------------------------------------------------------
    // VALIDATE CHANNELS
    // ----------------------------------------------------------

    if (channels != 1) {
      throw const FormatException('Gemini Live requires mono audio.');
    }

    // ----------------------------------------------------------
    // VALIDATE AUDIO FORMAT
    // ----------------------------------------------------------

    if (!mimeType.toLowerCase().startsWith('audio/pcm')) {
      throw const FormatException('Unsupported Gemini Live audio MIME type.');
    }

    // If the MIME type declares a sample rate, verify it agrees
    // with the audio configuration.
    final mimeRateMatch = RegExp(
      r'(?:^|;)\s*rate\s*=\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(mimeType);

    if (mimeRateMatch != null) {
      final mimeRate = int.tryParse(mimeRateMatch.group(1)!);

      if (mimeRate != sampleRate) {
        throw const FormatException(
          'Gemini Live audio MIME rate does not match sample rate.',
        );
      }
    }

    return GeminiLiveAudioConfig(
      sampleRate: sampleRate,
      channels: channels,
      mimeType: mimeType,
    );
  }

  // ============================================================
  // PARSE SAMPLE RATE
  // ============================================================

  static int _parseSampleRate(Map<String, dynamic> json, int fallback) {
    final value =
        json['sample_rate'] ?? json['sample_rate_hz'] ?? json['sampleRate'];

    if (value == null) {
      return fallback;
    }

    if (value is int) {
      return value;
    }

    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }

    if (value is String) {
      final parsed = int.tryParse(value.trim());

      if (parsed != null) {
        return parsed;
      }
    }

    throw const FormatException('Invalid Gemini Live audio sample rate.');
  }

  // ============================================================
  // PARSE CHANNEL COUNT
  // ============================================================

  static int _parseChannels(Map<String, dynamic> json) {
    final value = json['channels'] ?? 1;

    if (value is int) {
      return value;
    }

    if (value is String) {
      final parsed = int.tryParse(value.trim());

      if (parsed != null) {
        return parsed;
      }
    }

    throw const FormatException('Invalid Gemini Live audio channel count.');
  }

  // ============================================================
  // SAFE DEBUG OUTPUT
  // ============================================================

  @override
  String toString() {
    return 'GeminiLiveAudioConfig('
        'sampleRate: $sampleRate, '
        'channels: $channels, '
        'mimeType: $mimeType'
        ')';
  }
}
