import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:disha_ai/core/network/api_client.dart';

class WaterTrackerService {
  final Dio _dio = ApiClient.instance.dio;

  // ===============================================================
  // GET DAILY WATER
  // ===============================================================

  Future<Map<String, dynamic>> getWaterLog({String? date}) async {
    try {
      debugPrint('🌐 [WATER GET] /water-log');
      debugPrint('📅 Date: $date');

      final response = await _dio.get(
        '/water-log',
        queryParameters: {if (date != null && date.isNotEmpty) 'date': date},
      );

      debugPrint(
        '📥 [WATER GET SUCCESS] '
        'Status: ${response.statusCode}',
      );

      debugPrint('📦 [WATER GET RESPONSE] ${response.data}');

      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data as Map);
      }

      return {'success': false, 'message': 'Invalid water API response.'};
    } on DioException catch (e) {
      debugPrint('❌ [WATER GET ERROR]');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Message: ${e.message}');

      return {
        'success': false,
        'message': _extractErrorMessage(e, 'Failed to load water data.'),
      };
    } catch (e) {
      debugPrint('❌ [WATER GET FATAL] $e');

      return {'success': false, 'message': 'Unexpected error occurred.'};
    }
  }

  // ===============================================================
  // POST ADD WATER
  // ===============================================================

  Future<Map<String, dynamic>> addWater({
    required int amountMl,
    DateTime? loggedAt,
  }) async {
    try {
      final payload = <String, dynamic>{
        'amount_ml': amountMl,
        if (loggedAt != null) 'logged_at': loggedAt.toIso8601String(),
      };

      debugPrint('🌐 [WATER POST] /water-log');
      debugPrint('📦 Payload: $payload');

      final response = await _dio.post('/water-log', data: payload);

      debugPrint(
        '📥 [WATER POST SUCCESS] '
        'Status: ${response.statusCode}',
      );

      debugPrint('📦 [WATER POST RESPONSE] ${response.data}');

      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data as Map);
      }

      return {'success': false, 'message': 'Invalid water API response.'};
    } on DioException catch (e) {
      debugPrint('❌ [WATER POST ERROR]');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Message: ${e.message}');

      return {
        'success': false,
        'message': _extractErrorMessage(e, 'Failed to add water.'),
      };
    } catch (e) {
      debugPrint('❌ [WATER POST FATAL] $e');

      return {'success': false, 'message': 'Unexpected error occurred.'};
    }
  }

  // ===============================================================
  // DELETE WATER
  // ===============================================================

  Future<Map<String, dynamic>> deleteWater({required String id}) async {
    try {
      debugPrint('🌐 [WATER DELETE] /water-log/$id');

      final response = await _dio.delete('/water-log/$id');

      debugPrint(
        '📥 [WATER DELETE SUCCESS] '
        'Status: ${response.statusCode}',
      );

      debugPrint('📦 [WATER DELETE RESPONSE] ${response.data}');

      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data as Map);
      }

      return {'success': false, 'message': 'Invalid water API response.'};
    } on DioException catch (e) {
      debugPrint('❌ [WATER DELETE ERROR]');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Message: ${e.message}');

      return {
        'success': false,
        'message': _extractErrorMessage(e, 'Failed to delete water entry.'),
      };
    } catch (e) {
      debugPrint('❌ [WATER DELETE FATAL] $e');

      return {'success': false, 'message': 'Unexpected error occurred.'};
    }
  }

  // ===============================================================
  // ERROR MESSAGE
  // ===============================================================

  String _extractErrorMessage(DioException error, String fallback) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final message = responseData['message'];

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }

      final errorMessage = responseData['error'];

      if (errorMessage != null && errorMessage.toString().trim().isNotEmpty) {
        return errorMessage.toString();
      }
    }

    return fallback;
  }
}
