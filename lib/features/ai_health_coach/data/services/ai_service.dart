import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/storage/auth_storage.dart';
import '../models/ai_response_model.dart';

class AiService {
  final AuthStorage _storage = AuthStorage.instance;

  // ============================================================
  // HEADERS
  // ============================================================
  Map<String, String> _headers({bool isMultipart = false}) {
    final token = _storage.accessToken;
    if (token == null || token.trim().isEmpty) {
      throw Exception('Unauthenticated. Please login again.');
    }

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token.trim()}',
    };

    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  // ============================================================
  // 1. AI HEALTH COACH CHAT
  // ============================================================
  Future<AiResponseModel> sendChatMessage(String message) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiChat}'),
      headers: _headers(),
      body: jsonEncode({'message': message}),
    );
    return _handleResponse(response, 'Chat');
  }

  // ============================================================
  // 2. AI PROFILE ANALYZER
  // ============================================================
  Future<AiResponseModel> analyzeProfile() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiAnalyzeProfile}'),
      headers: _headers(),
    );
    return _handleResponse(response, 'Profile Analysis');
  }

  // ============================================================
  // 3. AI SCAN FOOD IMAGE
  // ============================================================
  Future<AiResponseModel> scanFoodImage(File imageFile) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.scanFood}');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(isMultipart: true))
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response, 'Food Scan');
  }

  // ============================================================
  // 4. AI VITALS ANALYSIS
  // ============================================================
  Future<AiResponseModel> analyzeVitals() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiAnalyzeHealth}'),
      headers: _headers(),
    );
    return _handleResponse(response, 'Vitals Analysis');
  }

  // ============================================================
  // 5. AI LAB REPORT ANALYZER
  // ============================================================
  Future<AiResponseModel> analyzeLabReport() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiAnalyzeLabReport}'),
      headers: _headers(),
    );
    return _handleResponse(response, 'Lab Report Analysis');
  }

  // ============================================================
  // 6. AI DAILY RECOMMENDATIONS
  // ============================================================
  Future<AiResponseModel> getRecommendations() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiRecommend}'),
      headers: _headers(),
    );
    return _handleResponse(response, 'Daily Recommendations');
  }

  // ============================================================
  // 7. AI GENERATE HEALTH PLAN
  // ============================================================
  Future<AiResponseModel> generateHealthPlan() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiGeneratePlan}'),
      headers: _headers(),
    );
    return _handleResponse(response, 'Generate Health Plan');
  }

  // ============================================================
  // 8. AI SYMPTOM CHECKER
  // ============================================================
  Future<AiResponseModel> checkSymptoms(String symptoms) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiSymptomChecker}'),
      headers: _headers(),
      body: jsonEncode({'symptoms': symptoms}),
    );
    return _handleResponse(response, 'Symptom Checker');
  }

  // ============================================================
  // 9. AI EXPLAIN MEDICAL REPORT
  // ============================================================
  Future<AiResponseModel> explainMedicalReport(String reportSummary) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiExplainReport}'),
      headers: _headers(),
      body: jsonEncode({'report_summary': reportSummary}),
    );
    return _handleResponse(response, 'Explain Medical Report');
  }

  // ============================================================
  // 10. GET CHAT HISTORY
  // ============================================================
  Future<AiResponseModel> getChatHistory() async {
    final response = await http.get(
      // Ensure ApiConstants.baseUrl does not have a trailing slash
      Uri.parse('${ApiConstants.baseUrl}/chat/history'),
      headers: _headers(),
    );
    return _handleResponse(response, 'Get Chat History');
  }

  // ============================================================
  // 11. CLEAR CHAT HISTORY
  // ============================================================
  Future<AiResponseModel> clearChatHistory() async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/chat/history'),
      headers: _headers(),
    );
    return _handleResponse(response, 'Clear Chat History');
  }

  // ============================================================
  // RESPONSE HANDLER
  // ============================================================
  AiResponseModel _handleResponse(http.Response response, String featureName) {
    debugPrint('========== $featureName ==========');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid server response from $featureName.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return AiResponseModel.fromJson(decoded);
      }
      return AiResponseModel(data: decoded);
    }

    String errorMessage = 'Something went wrong with $featureName';
    if (decoded is Map<String, dynamic>) {
      errorMessage =
          decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          errorMessage;
    }

    if (response.statusCode == 401) {
      throw Exception('Unauthenticated. Please login again.');
    }

    throw Exception(errorMessage);
  }

  // ============================================================
  // 12. SCHEDULE AI CHECK-IN
  // ============================================================
  Future<AiResponseModel> scheduleCheckin({
    required String time,
    required List<String> days,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/ai/schedule-checkin'),
      headers: _headers(),
      body: jsonEncode({'time': time, 'days': days}),
    );
    return _handleResponse(response, 'Schedule AI Check-in');
  }

  // ============================================================
  // 13. GET AI CHECK-IN SCHEDULE
  // ============================================================
  Future<AiResponseModel> getCheckinSchedule() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/ai/checkin-schedule'),
      headers: _headers(),
    );
    return _handleResponse(response, 'Get Check-in Schedule');
  }
}
