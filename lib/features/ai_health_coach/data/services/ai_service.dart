import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/storage/auth_storage.dart';
import '../models/ai_response_model.dart';
import 'package:http_parser/http_parser.dart';
import '../models/gemini_live_session_model.dart';

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
  // 3B. LOG FOOD (POST /api/food-log)
  // ============================================================
  Future<AiResponseModel> logFood({
    required String foodName,
    required String mealType,
    required int calories,
    required num protein,
    required num carbs,
    required num fat,
    required String servingSize,
    required String date,
    String? imageUrl,
  }) async {
    final Map<String, dynamic> bodyData = {
      'food_name': foodName,
      'meal_type': mealType,
      'calories': calories,
      'protein_g': protein,
      'carbs_g': carbs,
      'fat_g': fat,
      'serving_size': servingSize,
      'date': date,
    };

    if (imageUrl != null && imageUrl.isNotEmpty) {
      bodyData['image_url'] = imageUrl;
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/food-log'),
      headers: _headers(),
      body: jsonEncode(bodyData),
    );
    return _handleResponse(response, 'Log Food');
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
  // 5. AI LAB REPORT ANALYZER (UPDATED FOR MULTIPART)
  // ============================================================
  // ============================================================
  // 5. AI LAB REPORT ANALYZER
  // POST /api/ai/analyze-labs
  // ============================================================
  // ============================================================
  // 5. AI LAB REPORT ANALYZER
  // POST /api/ai/analyze-labs
  // ============================================================

  Future<AiResponseModel> analyzeLabReport({
    required File reportFile,
    String? labName,
    String? reportDate,
    String? notes,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/ai/analyze-labs');

      debugPrint('========== LAB REPORT ANALYSIS ==========');
      debugPrint('URL: $uri');
      debugPrint('FILE: ${reportFile.path}');

      // ----------------------------------------------------------
      // CHECK FILE EXISTS
      // ----------------------------------------------------------

      if (!await reportFile.exists()) {
        throw Exception('Selected lab report file does not exist.');
      }

      // ----------------------------------------------------------
      // CHECK FILE SIZE
      // Maximum allowed by API = 10 MB
      // ----------------------------------------------------------

      final fileSize = await reportFile.length();

      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Lab report must be smaller than 10 MB.');
      }

      // ----------------------------------------------------------
      // CREATE MULTIPART REQUEST
      // ----------------------------------------------------------

      final request = http.MultipartRequest('POST', uri);

      // IMPORTANT:
      // Do NOT manually set Content-Type.
      // MultipartRequest automatically creates the correct
      // multipart/form-data boundary.
      request.headers.addAll(_headers(isMultipart: true));

      // ----------------------------------------------------------
      // REQUIRED FILE
      //
      // DOCUMENTATION:
      // report_file
      //
      // NOT:
      // report_files[]
      // ----------------------------------------------------------

      final ext = reportFile.path.split('.').last.toLowerCase();
      MediaType contentType;
      if (ext == 'png') {
        contentType = MediaType('image', 'png');
      } else if (ext == 'webp') {
        contentType = MediaType('image', 'webp');
      } else if (ext == 'pdf') {
        contentType = MediaType('application', 'pdf');
      } else {
        contentType = MediaType('image', 'jpeg');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'report_file',
          reportFile.path,
          contentType: contentType,
        ),
      );

      // ----------------------------------------------------------
      // OPTIONAL LAB NAME
      // ----------------------------------------------------------

      if (labName != null && labName.trim().isNotEmpty) {
        request.fields['lab_name'] = labName.trim();
      }

      // ----------------------------------------------------------
      // OPTIONAL REPORT DATE
      //
      // Expected:
      // YYYY-MM-DD
      // ----------------------------------------------------------

      if (reportDate != null && reportDate.trim().isNotEmpty) {
        request.fields['report_date'] = reportDate.trim();
      }

      // ----------------------------------------------------------
      // OPTIONAL NOTES
      // ----------------------------------------------------------

      if (notes != null && notes.trim().isNotEmpty) {
        request.fields['notes'] = notes.trim();
      }

      debugPrint('LAB FILE FIELD: report_file');

      debugPrint('LAB FILE SIZE: $fileSize bytes');

      if (request.fields.isNotEmpty) {
        debugPrint('LAB FORM FIELDS: ${request.fields}');
      }

      // ----------------------------------------------------------
      // SEND REQUEST
      // ----------------------------------------------------------

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('LAB API STATUS: ${response.statusCode}');

      debugPrint('LAB API RESPONSE: ${response.body}');

      // ----------------------------------------------------------
      // HANDLE RESPONSE
      // ----------------------------------------------------------

      return _handleResponse(response, 'Lab Report Analysis');
    } catch (e) {
      debugPrint('LAB ANALYSIS ERROR: $e');

      rethrow;
    }
  }

  // ============================================================
  // 5B. ADD MEDICINE / PRESCRIPTION (NEW MULTIPART MODULE)
  // ============================================================
  Future<AiResponseModel> addMedicine({
    File? attachment,
    String? name,
    String? dosage,
    String? frequency,
    String? instructions,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/medicines',
    ); // POST /api/medicines[cite: 1]

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(isMultipart: true));

    if (attachment != null) {
      request.files.add(
        await http.MultipartFile.fromPath('attachments[]', attachment.path),
      ); // Field must be 'attachments[]'[cite: 1]
    } else if (name == null || name.trim().isEmpty) {
      throw Exception(
        'Either an attachment or a medicine name is required.',
      ); // Backend expects one or the other[cite: 1]
    }

    if (name != null) request.fields['name'] = name;
    if (dosage != null) request.fields['dosage'] = dosage;
    if (frequency != null) request.fields['frequency'] = frequency;
    if (instructions != null) request.fields['instructions'] = instructions;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response, 'Add Medicine');
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
  // 3C. SEARCH FOOD BY NAME
  // ============================================================
  Future<AiResponseModel> searchFoodByName(String foodName) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/foods/search?query=$foodName'),
      headers: _headers(),
    );
    return _handleResponse(response, 'Search Food');
  }

  // ============================================================
  // 10. GET CHAT HISTORY
  // ============================================================
  Future<AiResponseModel> getChatHistory() async {
    final response = await http.get(
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

  // ============================================================
  // 14. GET FOOD LOGS BY DATE
  // ============================================================
  Future<AiResponseModel> getFoodLogs({required String date}) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/food-log?date=$date'),
      headers: _headers(),
    );
    return _handleResponse(response, 'Get Food Logs');
  }

  // ============================================================
  // 15. GET NUTRITION ALIAS
  // ============================================================
  Future<AiResponseModel> getNutritionSummary({required String date}) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/nutrition?date=$date'),
      headers: _headers(),
    );
    return _handleResponse(response, 'Get Nutrition Summary');
  }

  // ============================================================
  // 16. RHEA AI VOICE - START SESSION
  // POST /api/rhea-ai/voice/start
  // ============================================================
  Future<AiResponseModel> startVoiceSession() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/rhea-ai/voice/start');

    debugPrint('========== RHEA VOICE START ==========');
    debugPrint('URL: $uri');

    final response = await http.post(uri, headers: _headers());

    debugPrint('VOICE START STATUS: ${response.statusCode}');
    debugPrint('VOICE START RESPONSE: ${response.body}');

    return _handleResponse(response, 'Rhea Voice Start');
  }

  // ============================================================
  // 17. RHEA AI VOICE - SEND TEXT MESSAGE
  // POST /api/rhea-ai/voice/message
  // ============================================================
  Future<AiResponseModel> sendVoiceText({
    required String sessionId,
    required String message,
  }) async {
    if (sessionId.trim().isEmpty) {
      throw Exception('Voice session ID is missing.');
    }

    if (message.trim().isEmpty) {
      throw Exception('Voice message cannot be empty.');
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/rhea-ai/voice/message');

    debugPrint('========== RHEA VOICE MESSAGE ==========');
    debugPrint('URL: $uri');
    debugPrint('SESSION ID: $sessionId');
    debugPrint('MESSAGE: $message');

    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'session_id': sessionId, 'message': message.trim()}),
    );

    debugPrint('VOICE MESSAGE STATUS: ${response.statusCode}');
    debugPrint('VOICE MESSAGE RESPONSE: ${response.body}');

    return _handleResponse(response, 'Rhea Voice Message');
  }

  // ============================================================
  // 18. RHEA AI VOICE - SEND AUDIO
  // POST /api/rhea-ai/voice/message
  // multipart/form-data
  // ============================================================
  Future<AiResponseModel> sendVoiceAudio({
    required String sessionId,
    required File audioFile,
  }) async {
    if (sessionId.trim().isEmpty) {
      throw Exception('Voice session ID is missing.');
    }

    if (!await audioFile.exists()) {
      throw Exception('Voice audio file does not exist.');
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/rhea-ai/voice/message');

    debugPrint('========== RHEA VOICE AUDIO ==========');
    debugPrint('URL: $uri');
    debugPrint('SESSION ID: $sessionId');
    debugPrint('AUDIO FILE: ${audioFile.path}');

    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(_headers(isMultipart: true));

    request.fields['session_id'] = sessionId;

    request.files.add(
      await http.MultipartFile.fromPath('audio', audioFile.path),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('VOICE AUDIO STATUS: ${response.statusCode}');

    debugPrint('VOICE AUDIO RESPONSE: ${response.body}');

    return _handleResponse(response, 'Rhea Voice Audio');
  }

  // ============================================================
  // 19. RHEA AI VOICE - END SESSION
  // POST /api/rhea-ai/voice/end
  // ============================================================
  Future<AiResponseModel> endVoiceSession({required String sessionId}) async {
    if (sessionId.trim().isEmpty) {
      throw Exception('Voice session ID is missing.');
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/rhea-ai/voice/end');

    debugPrint('========== RHEA VOICE END ==========');
    debugPrint('URL: $uri');
    debugPrint('SESSION ID: $sessionId');

    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'session_id': sessionId}),
    );

    debugPrint('VOICE END STATUS: ${response.statusCode}');

    debugPrint('VOICE END RESPONSE: ${response.body}');

    return _handleResponse(response, 'Rhea Voice End');
  }

  // ============================================================
  // GEMINI LIVE API (isolated from legacy response-body logging)
  // ============================================================
  Future<GeminiLiveSessionModel> startGeminiLiveSession() async {
    final result = await _postGeminiLive(
      '/rhea-ai/voice/live/session',
      const <String, dynamic>{},
      operation: 'Start Live session',
      timeout: const Duration(seconds: 20),
    );
    try {
      return GeminiLiveSessionModel.fromJson(result);
    } on FormatException {
      throw const GeminiLiveApiException(
        'Invalid Rhea Live session configuration.',
      );
    } on TypeError {
      throw const GeminiLiveApiException(
        'Invalid Rhea Live session configuration.',
      );
    }
  }

  Future<void> saveGeminiLiveTranscript({
    required String sessionId,
    required String sender,
    required String transcript,
    required String eventId,
  }) async {
    if (sessionId.trim().isEmpty ||
        eventId.trim().isEmpty ||
        transcript.trim().isEmpty) {
      throw const GeminiLiveApiException(
        'Incomplete Live transcript information.',
      );
    }
    if (sender != 'user' && sender != 'ai') {
      throw const GeminiLiveApiException('Invalid Live transcript sender.');
    }
    await _postGeminiLive(
      '/rhea-ai/voice/live/transcript',
      {
        'session_id': sessionId.trim(),
        'sender': sender,
        'transcript': transcript.trim(),
        'event_id': eventId.trim(),
      },
      operation: 'Save Live transcript',
      timeout: const Duration(seconds: 15),
    );
  }

  Future<void> endGeminiLiveSession({required String sessionId}) async {
    if (sessionId.trim().isEmpty) {
      throw const GeminiLiveApiException('Live session ID is missing.');
    }
    await _postGeminiLive(
      '/rhea-ai/voice/end',
      {'session_id': sessionId.trim()},
      operation: 'End Live session',
      timeout: const Duration(seconds: 10),
    );
  }

  Future<Map<String, dynamic>> _postGeminiLive(
    String endpoint,
    Map<String, dynamic> payload, {
    required String operation,
    required Duration timeout,
  }) async {
    // ============================================================
    // 1. VALIDATE HTTPS URL
    // ============================================================

    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    if (uri.scheme != 'https' || uri.host.isEmpty) {
      throw const GeminiLiveApiException(
        'Rhea Live requires a secure HTTPS connection.',
      );
    }

    // ============================================================
    // 2. AUTHENTICATION
    // ============================================================

    late final Map<String, String> headers;

    try {
      headers = _headers();
    } catch (_) {
      throw const GeminiLiveApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
        requiresAuthentication: true,
      );
    }

    // ============================================================
    // 3. SEND REQUEST
    // ============================================================

    late final http.Response response;

    try {
      response = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(timeout);
    } on TimeoutException {
      throw const GeminiLiveApiException(
        'Rhea is taking too long to respond. Please try again.',
        retryable: true,
      );
    } on HandshakeException {
      throw const GeminiLiveApiException(
        'Unable to establish a secure connection to Rhea.',
        retryable: true,
      );
    } on SocketException {
      throw const GeminiLiveApiException(
        'Please check your internet connection.',
        retryable: true,
      );
    } on http.ClientException {
      throw const GeminiLiveApiException(
        'Unable to connect to Rhea. Please try again.',
        retryable: true,
      );
    } on GeminiLiveApiException {
      rethrow;
    } catch (_) {
      throw const GeminiLiveApiException(
        'An unexpected connection error occurred.',
        retryable: true,
      );
    }

    // Never print the response body.
    // The session response contains an ephemeral Gemini credential.
    debugPrint('RHEA LIVE: $operation HTTP ${response.statusCode}');

    // ============================================================
    // 4. HANDLE HTTP STATUS
    // ============================================================

    final status = response.statusCode;

    if (status == 401) {
      throw const GeminiLiveApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
        requiresAuthentication: true,
      );
    }

    if (status == 403) {
      throw const GeminiLiveApiException(
        'You do not have access to Rhea Live.',
        statusCode: 403,
      );
    }

    if (status == 408 || status == 429 || status >= 500) {
      throw GeminiLiveApiException(
        status == 429
            ? 'Rhea is busy. Please try again shortly.'
            : 'Rhea is temporarily unavailable. Please try again.',
        statusCode: status,
        retryable: true,
      );
    }

    if (status < 200 || status >= 300) {
      throw GeminiLiveApiException(
        'Unable to complete the Rhea Live request.',
        statusCode: status,
      );
    }

    // ============================================================
    // 5. HANDLE EMPTY RESPONSE
    // ============================================================

    if (response.body.trim().isEmpty) {
      // Only transcript saving and ending a session can return
      // an empty successful response.
      if (endpoint == '/rhea-ai/voice/end' ||
          endpoint == '/rhea-ai/voice/live/transcript') {
        return <String, dynamic>{};
      }

      throw const GeminiLiveApiException(
        'Rhea returned an empty session response.',
      );
    }

    // ============================================================
    // 6. DECODE JSON
    // ============================================================

    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const GeminiLiveApiException(
        'Rhea returned an invalid JSON response.',
      );
    }

    if (decoded is! Map) {
      throw const GeminiLiveApiException('Unexpected Rhea response format.');
    }

    late final Map<String, dynamic> result;

    try {
      result = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw const GeminiLiveApiException('Unexpected Rhea response format.');
    }

    // ============================================================
    // 7. CHECK BACKEND SUCCESS
    // ============================================================

    if (result['success'] == false) {
      throw const GeminiLiveApiException(
        'Rhea could not complete the request.',
      );
    }

    return result;
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
  // DELETE FOOD LOG (DELETE /api/food-log/{id})
  // ============================================================
  Future<AiResponseModel> deleteFoodLog(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/food-log/$id'),
      headers: _headers(),
    );
    return _handleResponse(response, 'Delete Food Log');
  }
}

/// Typed failures for the new Gemini Live endpoints only.
class GeminiLiveApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool retryable;
  final bool requiresAuthentication;

  const GeminiLiveApiException(
    this.message, {
    this.statusCode,
    this.retryable = false,
    this.requiresAuthentication = false,
  });

  @override
  String toString() => message;
}
