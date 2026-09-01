import 'package:dio/dio.dart';
import 'package:disha_ai/core/network/api_client.dart';
import 'package:disha_ai/features/profile/data/models/settings_model.dart';
import 'package:flutter/foundation.dart';

class SettingsService {
  final Dio _dio = ApiClient.instance.dio;

  // GET /api/settings
  Future<SettingsModel> getSettings() async {
    try {
      debugPrint('🌐 [API GET] Requesting /settings');
      final response = await _dio.get('/settings');
      debugPrint('📥 [API GET SUCCESS] Data: ${response.data}');
      return SettingsModel.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ [API GET ERROR] Status: ${e.response?.statusCode}');
      debugPrint('   ↳ Response Data: ${e.response?.data}');
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load app settings',
      );
    }
  }

  // PUT /api/settings
  Future<SettingsModel> updateSettings({
    required String preferredLanguage,
    required bool pushNotifications,
    required bool microphoneAccess,
    required String unitSystem,
  }) async {
    // Construct the payload to send to the backend
    final Map<String, dynamic> payload = {
      'preferred_language': preferredLanguage,
      'push_notifications': pushNotifications,
      'microphone_access': microphoneAccess,
      'unit_system': unitSystem,

      // ⚠️ UNCOMMENT THE LINE BELOW if your backend throws a 422 error
      // 'dark_mode': false,
    };

    debugPrint('🌐 [API PUT] Sending update to /settings');
    debugPrint('📦 [API PUT PAYLOAD] $payload');

    try {
      final response = await _dio.put('/settings', data: payload);
      debugPrint(
        '📥 [API PUT SUCCESS] Status: ${response.statusCode} | Data: ${response.data}',
      );
      return SettingsModel.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ [API PUT ERROR] Request Failed!');
      debugPrint('   ↳ Status Code: ${e.response?.statusCode}');
      debugPrint('   ↳ Response Body: ${e.response?.data}');
      debugPrint('   ↳ Error Message: ${e.message}');

      final String serverMessage =
          e.response?.data['message'] ?? 'Failed to update app settings';
      throw Exception(serverMessage);
    } catch (e) {
      debugPrint('❌ [API PUT FATAL ERROR] Non-Dio exception occurred: $e');
      throw Exception('Unexpected error occurred');
    }
  }
}
