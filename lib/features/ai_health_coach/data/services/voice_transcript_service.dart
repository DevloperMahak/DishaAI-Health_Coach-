import 'dart:async';
import 'dart:collection';

import 'ai_service.dart';

/// Sender values accepted by the Rhea Live transcript API.
enum VoiceTranscriptSender { user, ai }

extension VoiceTranscriptSenderExtension on VoiceTranscriptSender {
  String get apiValue {
    switch (this) {
      case VoiceTranscriptSender.user:
        return 'user';
      case VoiceTranscriptSender.ai:
        return 'ai';
    }
  }
}

/// Represents a completed conversation turn.
///
/// The event ID remains unchanged across retries.
class VoiceTranscriptEntry {
  final String sessionId;
  final VoiceTranscriptSender sender;
  final String transcript;
  final String eventId;

  const VoiceTranscriptEntry({
    required this.sessionId,
    required this.sender,
    required this.transcript,
    required this.eventId,
  });
}

/// Saves completed Gemini Live conversation turns.
///
/// Responsibilities:
/// - Prevent duplicate submissions within the service instance.
/// - Preserve event IDs across retries.
/// - Process queued transcripts sequentially.
/// - Retry transient failures.
/// - Support bounded shutdown flushing.
///
/// Important:
/// The backend must enforce uniqueness using event_id.
/// Client-side deduplication alone cannot guarantee exactly-once storage.
class VoiceTranscriptService {
  VoiceTranscriptService({
    AiService? aiService,
    this.maxRetries = 3,
    this.maxQueueSize = 100,
  }) : _aiService = aiService ?? AiService() {
    if (maxRetries < 0) {
      throw ArgumentError.value(
        maxRetries,
        'maxRetries',
        'Must not be negative.',
      );
    }

    if (maxQueueSize < 1) {
      throw ArgumentError.value(
        maxQueueSize,
        'maxQueueSize',
        'Must be at least 1.',
      );
    }
  }

  final AiService _aiService;

  final int maxRetries;
  final int maxQueueSize;

  final Queue<VoiceTranscriptEntry> _queue = Queue<VoiceTranscriptEntry>();

  /// IDs currently queued, being processed, or already saved.
  final Set<String> _knownEventIds = <String>{};

  final Set<String> _savedEventIds = <String>{};

  Completer<void>? _processingCompleter;

  bool _isProcessing = false;
  bool _isClosed = false;

  int _eventSequence = 0;

  String? _sessionId;

  bool get isProcessing => _isProcessing;

  bool get isClosed => _isClosed;

  int get pendingCount => _queue.length + (_isProcessing ? 1 : 0);

  int get savedCount => _savedEventIds.length;

  /// Initialize the service for a new backend Live session.
  ///
  /// Create a new service instance per call whenever possible.
  void initialize(String sessionId) {
    if (_isClosed) {
      throw StateError('Transcript service has already been closed.');
    }

    final normalizedId = sessionId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError('Session ID cannot be empty.');
    }

    if (_sessionId != null && _sessionId != normalizedId) {
      throw StateError(
        'A transcript service cannot be reused for another session.',
      );
    }

    _sessionId = normalizedId;
  }

  /// Generate a stable ID for one completed turn.
  ///
  /// Never generate a new ID when retrying an existing turn.
  String nextEventId(VoiceTranscriptSender sender) {
    final sessionId = _sessionId;

    if (sessionId == null) {
      throw StateError('Transcript service is not initialized.');
    }

    _eventSequence++;

    final prefix = sender == VoiceTranscriptSender.user
        ? 'user-turn'
        : 'ai-turn';

    return '$prefix-${_eventSequence.toString().padLeft(6, '0')}';
  }

  /// Enqueue a completed transcript.
  ///
  /// Returns false if the entry is empty, duplicated, or cannot be
  /// accepted because the bounded queue is full.
  ///
  /// Call this only for final conversation turns.
  bool enqueue({
    required VoiceTranscriptSender sender,
    required String transcript,
    String? eventId,
  }) {
    if (_isClosed) {
      return false;
    }

    final sessionId = _sessionId;

    if (sessionId == null) {
      throw StateError('Transcript service is not initialized.');
    }

    final normalizedTranscript = transcript.trim();

    if (normalizedTranscript.isEmpty) {
      return false;
    }

    final id = eventId?.trim() ?? nextEventId(sender);

    if (id.isEmpty) {
      return false;
    }

    if (_knownEventIds.contains(id)) {
      return false;
    }

    if (_queue.length >= maxQueueSize) {
      return false;
    }

    final entry = VoiceTranscriptEntry(
      sessionId: sessionId,
      sender: sender,
      transcript: normalizedTranscript,
      eventId: id,
    );

    _knownEventIds.add(id);
    _queue.addLast(entry);

    _startProcessing();

    return true;
  }

  void _startProcessing() {
    if (_isProcessing || _queue.isEmpty) {
      return;
    }

    _isProcessing = true;

    final completer = Completer<void>();
    _processingCompleter = completer;

    unawaited(_processQueue(completer));
  }

  Future<void> _processQueue(Completer<void> completer) async {
    try {
      while (_queue.isNotEmpty) {
        final entry = _queue.removeFirst();

        final saved = await _saveWithRetry(entry);

        if (saved) {
          _savedEventIds.add(entry.eventId);
        } else {
          // Do not silently treat a failed transcript as saved.
          //
          // The controller can inspect failedCount and show
          // a warning before closing the call.
          _failedEntries.add(entry);
        }
      }
    } finally {
      _isProcessing = false;

      if (!completer.isCompleted) {
        completer.complete();
      }

      if (identical(_processingCompleter, completer)) {
        _processingCompleter = null;
      }

      if (_queue.isNotEmpty) {
        _startProcessing();
      }
    }
  }

  final List<VoiceTranscriptEntry> _failedEntries = <VoiceTranscriptEntry>[];

  int get failedCount => _failedEntries.length;

  List<VoiceTranscriptEntry> get failedEntries =>
      List<VoiceTranscriptEntry>.unmodifiable(_failedEntries);

  Future<bool> _saveWithRetry(VoiceTranscriptEntry entry) async {
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        await _aiService.saveGeminiLiveTranscript(
          sessionId: entry.sessionId,
          sender: entry.sender.apiValue,
          transcript: entry.transcript,
          eventId: entry.eventId,
        );

        return true;
      } on GeminiLiveApiException catch (error) {
        if (!error.retryable || attempt >= maxRetries) {
          return false;
        }
      } catch (_) {
        // Unknown errors are not retried automatically.
        return false;
      }

      final delay = _retryDelay(attempt);

      await Future<void>.delayed(delay);
    }

    return false;
  }

  Duration _retryDelay(int attempt) {
    switch (attempt) {
      case 0:
        return const Duration(milliseconds: 500);
      case 1:
        return const Duration(seconds: 1);
      default:
        return const Duration(seconds: 2);
    }
  }

  /// Wait until all currently queued entries have been processed.
  ///
  /// Returns true when every accepted entry was saved.
  ///
  /// A timeout means processing may still be running.
  Future<bool> flush({Duration timeout = const Duration(seconds: 8)}) async {
    if (_queue.isNotEmpty && !_isProcessing) {
      _startProcessing();
    }

    final completer = _processingCompleter;

    if (completer != null) {
      try {
        await completer.future.timeout(timeout);
      } on TimeoutException {
        return false;
      }
    }

    return _queue.isEmpty && !_isProcessing && _failedEntries.isEmpty;
  }

  /// Retry previously failed entries.
  ///
  /// Their event IDs remain unchanged.
  ///
  /// Invoke this only when connectivity has recovered or
  /// the user explicitly retries saving.
  void retryFailed() {
    if (_isClosed || _failedEntries.isEmpty) {
      return;
    }

    final retryableEntries = List<VoiceTranscriptEntry>.from(_failedEntries);

    _failedEntries.clear();

    for (final entry in retryableEntries) {
      if (_queue.length >= maxQueueSize) {
        _failedEntries.add(entry);
        continue;
      }

      _queue.addLast(entry);
    }

    _startProcessing();
  }

  /// Stop accepting new entries and wait briefly for pending saves.
  ///
  /// Returns false if one or more transcripts remain unsaved.
  Future<bool> close({Duration timeout = const Duration(seconds: 8)}) async {
    _isClosed = true;

    return flush(timeout: timeout);
  }
}
