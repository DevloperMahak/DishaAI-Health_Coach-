import 'package:dio/dio.dart';
import 'package:disha_ai/features/onboarding/data/models/health_nutrition_model.dart';
import 'package:get_storage/get_storage.dart';

class HealthNutritionService {
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

  Options get _authHeader =>
      Options(headers: {'Authorization': 'Bearer $_token'});

  // ================= HEALTH LOGS =================

  Future<HealthLogModel?> getHealthLogs() async {
    try {
      final response = await _dio.get('/health', options: _authHeader);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return HealthLogModel.fromJson(data);
      }
    } catch (e) {
      print("Error fetching health logs: $e");
    }
    return null;
  }

  Future<bool> logHealthMetrics(HealthLogModel metrics) async {
    try {
      final response = await _dio.post(
        '/health',
        data: metrics.toJson(),
        options: _authHeader,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error logging health metrics: $e");
      return false;
    }
  }

  Future<bool> updateHealthMetrics(Map<String, dynamic> updateData) async {
    try {
      final response = await _dio.put(
        '/health',
        data: updateData,
        options: _authHeader,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating health metrics: $e");
      return false;
    }
  }

  Future<bool> deleteHealthMetrics() async {
    try {
      final response = await _dio.delete('/health', options: _authHeader);
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting health metrics: $e");
      return false;
    }
  }

  // ================= NUTRITION =================

  Future<NutritionSummaryModel?> getNutritionSummary() async {
    try {
      final response = await _dio.get('/nutrition', options: _authHeader);
      if (response.statusCode == 200 && response.data != null) {
        return NutritionSummaryModel.fromJson(response.data);
      }
    } catch (e) {
      print("Error fetching nutrition summary: $e");
    }
    return null;
  }

  Future<bool> logMealItem(Map<String, dynamic> mealData) async {
    try {
      final response = await _dio.post(
        '/food-log',
        data: mealData,
        options: _authHeader,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error logging meal: $e");
      return false;
    }
  }
  // ================= WATER INTAKE =================

  Future<bool> logWaterIntake(int amountMl) async {
    try {
      final response = await _dio.post(
        '/water',
        data: {'amount_ml': amountMl},
        options: _authHeader,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error logging water: $e");
      return false;
    }
  }
  // ================= SLEEP =================

  // ================= SLEEP =================

  Future<SleepLogModel?> logSleep({
    required String date,
    required double sleepHours,
  }) async {
    try {
      final payload = {'date': date, 'sleep_hours': sleepHours};

      print('====================================');
      print('🌙 [SLEEP SERVICE] REQUEST STARTED');
      print('📍 Endpoint: POST /sleep');
      print('📦 Payload: $payload');
      print('🔐 Token available: ${_token?.isNotEmpty == true}');
      print('====================================');

      final response = await _dio.post(
        '/sleep',
        data: payload,
        options: _authHeader,
      );

      print('✅ [SLEEP SERVICE] SUCCESS');
      print('📊 Status: ${response.statusCode}');
      print('📥 Response: ${response.data}');

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final responseBody = Map<String, dynamic>.from(response.data);

        final sleepData = responseBody['data'] is Map
            ? Map<String, dynamic>.from(responseBody['data'])
            : responseBody;

        return SleepLogModel.fromJson(sleepData);
      }

      return null;
    } on DioException catch (e) {
      print('====================================');
      print('❌ [SLEEP SERVICE] API ERROR');
      print('📍 URL: ${e.requestOptions.uri}');
      print('📌 Method: ${e.requestOptions.method}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('📥 Server Response: ${e.response?.data}');
      print('📝 Error Type: ${e.type}');
      print('📝 Error Message: ${e.message}');
      print('====================================');

      return null;
    } catch (e) {
      print('❌ [SLEEP SERVICE] Unexpected Error: $e');
      return null;
    }
  }
}
