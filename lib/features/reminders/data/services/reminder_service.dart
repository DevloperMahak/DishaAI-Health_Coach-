import 'package:dio/dio.dart';
import 'package:disha_ai/core/network/api_client.dart';
import 'package:disha_ai/features/reminders/data/models/reminder_model.dart';
import 'package:disha_ai/features/reminders/data/models/reminder_settings_model.dart';
import 'package:flutter/foundation.dart';

class ReminderService {
  final Dio _dio = ApiClient.instance.dio;

  // ============================================================
  // Helpers
  // ============================================================

  String _extractMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();

      if (message != null && message.trim().isNotEmpty) {
        return message;
      }

      final errorNode = data['error'];

      if (errorNode is Map) {
        final errorMessage = errorNode['message']?.toString();

        if (errorMessage != null && errorMessage.trim().isNotEmpty) {
          return errorMessage;
        }
      }
    }

    return error.message ?? 'Something went wrong.';
  }

  Map<String, dynamic> _dataMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{};
  }

  // ============================================================
  // CREATE REMINDER
  // POST /api/v1/reminders
  // ============================================================

  Future<ReminderModel> createReminder({
    required String module,
    required String type,
    String? title,
    String? message,
    String priority = 'normal',
    String? time,
    List<String>? days,
    int? intervalMinutes,
    String? goalId,
    String? timezone,
  }) async {
    final body = <String, dynamic>{
      'module': module,
      'type': type,
      'priority': priority,
    };

    if (title != null && title.trim().isNotEmpty) {
      body['title'] = title.trim();
    }

    if (message != null && message.trim().isNotEmpty) {
      body['message'] = message.trim();
    }

    if (time != null && time.trim().isNotEmpty) {
      body['time'] = time;
    }

    if (days != null && days.isNotEmpty) {
      body['days'] = days;
    }

    if (intervalMinutes != null) {
      body['interval_minutes'] = intervalMinutes;
    }

    if (goalId != null && goalId.trim().isNotEmpty) {
      body['goal_id'] = goalId.trim();
    }

    if (timezone != null && timezone.trim().isNotEmpty) {
      body['timezone'] = timezone.trim();
    }

    debugPrint('🌐 [POST] /v1/reminders');
    debugPrint('📦 Payload: $body');

    try {
      final response = await _dio.post('/v1/reminders', data: body);

      debugPrint('📥 [POST SUCCESS] ${response.statusCode} | ${response.data}');

      final data = _dataMap(response.data);
      final rawData = data['data'];

      if (rawData is! Map) {
        throw Exception('Invalid reminder response.');
      }

      return ReminderModel.fromJson(Map<String, dynamic>.from(rawData));
    } on DioException catch (e) {
      debugPrint('❌ [POST REMINDER ERROR]');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');

      throw Exception(_extractMessage(e));
    }
  }

  // ============================================================
  // GET REMINDERS
  // GET /api/v1/reminders
  // ============================================================

  Future<List<ReminderModel>> getReminders({
    String? module,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final query = <String, dynamic>{'page': page, 'per_page': perPage};

    if (module != null && module.trim().isNotEmpty) {
      query['module'] = module;
    }

    if (status != null && status.trim().isNotEmpty) {
      query['status'] = status;
    }

    debugPrint('🌐 [GET] /v1/reminders');
    debugPrint('🔎 Query: $query');

    try {
      final response = await _dio.get('/v1/reminders', queryParameters: query);

      debugPrint('📥 [GET REMINDERS SUCCESS] ${response.statusCode}');

      final data = _dataMap(response.data);
      final rawData = data['data'];

      if (rawData is! Map) {
        return <ReminderModel>[];
      }

      final rawReminders = rawData['reminders'];

      if (rawReminders is! List) {
        return <ReminderModel>[];
      }

      return rawReminders
          .whereType<Map>()
          .map(
            (item) => ReminderModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (e) {
      debugPrint('❌ [GET REMINDERS ERROR]');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');

      throw Exception(_extractMessage(e));
    }
  }

  // ============================================================
  // GET SINGLE REMINDER
  // GET /api/v1/reminders/{id}
  // ============================================================

  Future<ReminderModel> getReminder(String reminderId) async {
    try {
      final response = await _dio.get('/v1/reminders/$reminderId');

      final data = _dataMap(response.data);
      final rawData = data['data'];

      if (rawData is! Map) {
        throw Exception('Invalid reminder response.');
      }

      return ReminderModel.fromJson(Map<String, dynamic>.from(rawData));
    } on DioException catch (e) {
      debugPrint('❌ [GET REMINDER ERROR]');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');

      throw Exception(_extractMessage(e));
    }
  }

  // ============================================================
  // UPDATE REMINDER
  // PUT /api/v1/reminders/{id}
  // ============================================================

  Future<ReminderModel> updateReminder({
    required String reminderId,
    String? module,
    String? type,
    String? title,
    String? message,
    String? priority,
    String? time,
    List<String>? days,
    int? intervalMinutes,
    String? goalId,
    String? timezone,
  }) async {
    final body = <String, dynamic>{};

    if (module != null) {
      body['module'] = module;
    }

    if (type != null) {
      body['type'] = type;
    }

    if (title != null) {
      body['title'] = title.trim();
    }

    if (message != null) {
      body['message'] = message.trim();
    }

    if (priority != null) {
      body['priority'] = priority;
    }

    if (time != null) {
      body['time'] = time;
    }

    if (days != null) {
      body['days'] = days;
    }

    if (intervalMinutes != null) {
      body['interval_minutes'] = intervalMinutes;
    }

    if (goalId != null) {
      body['goal_id'] = goalId;
    }

    if (timezone != null) {
      body['timezone'] = timezone;
    }

    debugPrint('🌐 [PUT] /v1/reminders/$reminderId');
    debugPrint('📦 Payload: $body');

    try {
      final response = await _dio.put('/v1/reminders/$reminderId', data: body);

      final data = _dataMap(response.data);
      final rawData = data['data'];

      if (rawData is! Map) {
        throw Exception('Invalid reminder response.');
      }

      return ReminderModel.fromJson(Map<String, dynamic>.from(rawData));
    } on DioException catch (e) {
      debugPrint('❌ [UPDATE REMINDER ERROR]');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');

      throw Exception(_extractMessage(e));
    }
  }

  // ============================================================
  // PAUSE
  // POST /api/v1/reminders/{id}/pause
  // ============================================================

  Future<void> pauseReminder(String id) async {
    await _postAction('/v1/reminders/$id/pause');
  }

  // ============================================================
  // RESUME
  // POST /api/v1/reminders/{id}/resume
  // ============================================================

  Future<void> resumeReminder(String id) async {
    await _postAction('/v1/reminders/$id/resume');
  }

  // ============================================================
  // COMPLETE
  // POST /api/v1/reminders/{id}/complete
  // ============================================================

  Future<void> completeReminder(String id) async {
    await _postAction('/v1/reminders/$id/complete');
  }

  // ============================================================
  // SKIP
  // POST /api/v1/reminders/{id}/skip
  // ============================================================

  Future<void> skipReminder(String id) async {
    await _postAction('/v1/reminders/$id/skip');
  }

  // ============================================================
  // SNOOZE
  // POST /api/v1/reminders/{id}/snooze
  // ============================================================

  Future<void> snoozeReminder(String id, int minutes) async {
    const validMinutes = <int>[5, 10, 15, 30, 60];

    if (!validMinutes.contains(minutes)) {
      throw Exception('Invalid snooze duration.');
    }

    await _postAction('/v1/reminders/$id/snooze', <String, dynamic>{
      'minutes': minutes,
    });
  }

  // ============================================================
  // COMMON POST ACTION
  // ============================================================

  Future<void> _postAction(String path, [Map<String, dynamic>? body]) async {
    debugPrint('🌐 [POST] $path');

    try {
      final response = await _dio.post(path, data: body);

      debugPrint('📥 [ACTION SUCCESS] ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('❌ [ACTION ERROR] $path');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');

      throw Exception(_extractMessage(e));
    }
  }

  // ============================================================
  // DELETE
  // DELETE /api/v1/reminders/{id}
  // ============================================================

  Future<void> deleteReminder(String id) async {
    debugPrint('🌐 [DELETE] /v1/reminders/$id');

    try {
      await _dio.delete('/v1/reminders/$id');
    } on DioException catch (e) {
      debugPrint('❌ [DELETE REMINDER ERROR]');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');

      throw Exception(_extractMessage(e));
    }
  }

  // ============================================================
  // AI GENERATE SCHEDULE
  // POST /api/v1/ai/reminders/generate
  // ============================================================

  Future<Map<String, dynamic>> generateAiSchedule(String module) async {
    try {
      final response = await _dio.post(
        '/v1/ai/reminders/generate',
        data: <String, dynamic>{'module': module},
      );

      return _dataMap(response.data);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  // ============================================================
  // AI PERSONALIZE REMINDER
  // POST /api/v1/ai/reminders/personalize
  // ============================================================

  Future<Map<String, dynamic>> personalizeAiReminder([
    String module = 'hydration',
  ]) async {
    try {
      final response = await _dio.post(
        '/v1/ai/reminders/personalize',
        data: <String, dynamic>{'module': module},
      );

      return _dataMap(response.data);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  // ============================================================
  // GET REMINDER SETTINGS
  // GET /api/v1/settings/reminders
  // ============================================================

  Future<ReminderSettingsModel> getSettings() async {
    debugPrint('🌐 [GET] /v1/settings/reminders');

    try {
      final response = await _dio.get('/v1/settings/reminders');

      debugPrint('📥 [SETTINGS SUCCESS] ${response.statusCode}');

      final data = _dataMap(response.data);
      final rawData = data['data'];

      if (rawData is! Map) {
        throw Exception('Invalid reminder settings response.');
      }

      return ReminderSettingsModel.fromJson(Map<String, dynamic>.from(rawData));
    } on DioException catch (e) {
      debugPrint('❌ [GET REMINDER SETTINGS ERROR]');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');

      throw Exception(_extractMessage(e));
    }
  }

  // ============================================================
  // UPDATE REMINDER SETTINGS
  // PUT /api/v1/settings/reminders
  // ============================================================

  Future<ReminderSettingsModel> updateSettings(
    Map<String, dynamic> changes,
  ) async {
    debugPrint('🌐 [PUT] /v1/settings/reminders');
    debugPrint('📦 Payload: $changes');

    try {
      final response = await _dio.put('/v1/settings/reminders', data: changes);

      debugPrint('📥 [UPDATE SETTINGS SUCCESS] ${response.statusCode}');

      final data = _dataMap(response.data);
      final rawData = data['data'];

      if (rawData is! Map) {
        throw Exception('Invalid reminder settings response.');
      }

      return ReminderSettingsModel.fromJson(Map<String, dynamic>.from(rawData));
    } on DioException catch (e) {
      debugPrint('❌ [UPDATE REMINDER SETTINGS ERROR]');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');

      throw Exception(_extractMessage(e));
    }
  }
}
