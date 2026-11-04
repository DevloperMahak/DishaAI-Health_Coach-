import 'package:dio/dio.dart';
import 'package:disha_ai/features/dashboard/data/models/mood_checkin_model.dart';
import 'package:get_storage/get_storage.dart';

class MoodCheckinService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://rhea-ai.acttconnect.com/api',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  final GetStorage _storage = GetStorage();

  String? get _token => _storage.read('access_token') ?? _storage.read('token');

  Options get _authHeader {
    final token = _token;

    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
  }

  // ============================================================
  // SUBMIT MOOD CHECK-IN
  // ============================================================
  //
  // API:
  // POST /api/health
  //
  // Request:
  // {
  //   "date": "2026-10-07",
  //   "mood": "anxious"
  // }
  //
  // IMPORTANT:
  // Flutter sends ONLY:
  // - date
  // - mood
  //
  // Flutter DOES NOT send stress_level.
  //
  // Backend automatically calculates stress_level.
  // ============================================================

  Future<MoodCheckinModel> submitMood({required String mood}) async {
    final String normalizedMood = mood.trim().toLowerCase();

    if (normalizedMood.isEmpty) {
      throw Exception('Please select your mood.');
    }

    // These are the 8 mood values defined by the API document.
    const List<String> validMoods = [
      'anxious',
      'overwhelmed',
      'low_sad',
      'irritated',
      'tired',
      'calm',
      'happy',
      'energetic',
    ];

    if (!validMoods.contains(normalizedMood)) {
      throw Exception('Invalid mood selected.');
    }

    // API expects YYYY-MM-DD.
    final String date = DateTime.now().toIso8601String().split('T').first;

    final Map<String, dynamic> payload = {'date': date, 'mood': normalizedMood};

    try {
      print('');
      print('══════════════════════════════════════════');
      print('🧠 [MOOD SERVICE] submitMood()');
      print('══════════════════════════════════════════');
      print('➡️ Endpoint: POST /health');
      print('📅 Date: $date');
      print('😊 Mood: $normalizedMood');
      print('📦 Payload: $payload');
      print('🚫 Stress level is NOT being sent by Flutter.');

      final response = await _dio.post(
        '/health',
        data: payload,
        options: _authHeader,
      );

      print('⬅️ Status Code: ${response.statusCode}');
      print('📥 Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic responseData = response.data;

        if (responseData is! Map) {
          throw Exception('Invalid response received from server.');
        }

        final Map<String, dynamic> responseMap = Map<String, dynamic>.from(
          responseData,
        );

        final bool success = responseMap['success'] == true;

        if (!success) {
          final String message =
              responseMap['message']?.toString() ??
              'Unable to save mood check-in.';

          throw Exception(message);
        }

        final dynamic data = responseMap['data'];

        if (data is! Map) {
          throw Exception('Mood response data is missing.');
        }

        final Map<String, dynamic> moodData = Map<String, dynamic>.from(data);

        final MoodCheckinModel result = MoodCheckinModel.fromJson(moodData);

        print('');
        print('✅ [MOOD SERVICE] Mood saved successfully.');
        print('😊 Mood: ${result.mood}');
        print('🧠 Backend Stress: ${result.stressLevel}');
        print('══════════════════════════════════════════');

        return result;
      }

      final String message = response.data is Map
          ? response.data['message']?.toString() ??
                'Failed to save mood check-in.'
          : 'Failed to save mood check-in.';

      throw Exception('$message Server returned ${response.statusCode}.');
    } on DioException catch (e) {
      print('');
      print('══════════════════════════════════════════');
      print('❌ [MOOD SERVICE] DioException');
      print('══════════════════════════════════════════');
      print('Type: ${e.type}');
      print('Status: ${e.response?.statusCode}');
      print('Response: ${e.response?.data}');
      print('Message: ${e.message}');

      String message = 'Unable to save mood check-in.';

      final dynamic responseData = e.response?.data;

      if (responseData is Map) {
        message =
            responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            message;
      }

      if (e.response?.statusCode == 401) {
        message = 'Your session has expired. Please log in again.';
      } else if (e.response?.statusCode == 422) {
        if (message == 'Unable to save mood check-in.') {
          message = 'Please select a valid mood.';
        }
      } else if (e.response?.statusCode != null &&
          e.response!.statusCode! >= 500) {
        message = 'Server error. Please try again later.';
      }

      throw Exception(message);
    } catch (e) {
      print('❌ [MOOD SERVICE] Error: $e');

      rethrow;
    }
  }
}
