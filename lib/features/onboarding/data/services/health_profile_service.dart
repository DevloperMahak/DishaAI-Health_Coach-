import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_constants.dart';
import '../../../../core/storage/auth_storage.dart';
import '../models/health_profile_model.dart';

class HealthProfileService {
  final AuthStorage _storage = AuthStorage.instance;

  // ============================================================
  // HEADERS
  // ============================================================

  Map<String, String> _headers() {
    final token = _storage.accessToken;

    if (token == null || token.trim().isEmpty) {
      throw Exception('Unauthenticated. Please login again.');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token.trim()}',
    };
  }

  // ============================================================
  // SAVE HEALTH PROFILE
  // POST /user/health-profile
  // ============================================================

  Future<HealthProfileModel> saveHealthProfile(
    HealthProfileModel profile,
  ) async {
    final token = _storage.accessToken;

    print('========== HEALTH PROFILE POST ==========');
    print('URL: ${ApiConstants.baseUrl}${ApiConstants.healthProfile}');
    print('TOKEN EXISTS: ${token != null && token.trim().isNotEmpty}');
    print('TOKEN LENGTH: ${token?.length ?? 0}');
    print('BODY: ${jsonEncode(profile.toJson())}');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.healthProfile}'),
      headers: _headers(),
      body: jsonEncode(profile.toJson()),
    );

    print('STATUS: ${response.statusCode}');
    print('RESPONSE: ${response.body}');
    print('==========================================');

    return _handleProfileResponse(response);
  }

  // ============================================================
  // GET HEALTH PROFILE
  // GET /user/health-profile
  // ============================================================

  Future<HealthProfileModel> getHealthProfile() async {
    final token = _storage.accessToken;

    print('========== HEALTH PROFILE GET ==========');
    print('URL: ${ApiConstants.baseUrl}${ApiConstants.healthProfile}');
    print('TOKEN EXISTS: ${token != null && token.trim().isNotEmpty}');
    print('TOKEN LENGTH: ${token?.length ?? 0}');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.healthProfile}'),
      headers: _headers(),
    );

    print('STATUS: ${response.statusCode}');
    print('RESPONSE: ${response.body}');
    print('========================================');

    return _handleProfileResponse(response);
  }

  // ============================================================
  // UPDATE HEALTH PROFILE
  // PUT /user/health-profile
  // ============================================================

  Future<HealthProfileModel> updateHealthProfile(
    HealthProfileModel profile,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.healthProfile}'),
      headers: _headers(),
      body: jsonEncode(profile.toJson()),
    );

    print('========== HEALTH PROFILE PUT ==========');
    print('STATUS: ${response.statusCode}');
    print('RESPONSE: ${response.body}');
    print('========================================');

    return _handleProfileResponse(response);
  }

  // ============================================================
  // RESPONSE HANDLER
  // ============================================================

  HealthProfileModel _handleProfileResponse(http.Response response) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid server response (${response.statusCode})');
    }

    // ----------------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------------

    if (response.statusCode >= 200 && response.statusCode < 300) {
      Map<String, dynamic> data;

      if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is Map<String, dynamic>) {
          data = Map<String, dynamic>.from(decoded['data']);
        } else {
          data = decoded;
        }
      } else {
        throw Exception('Invalid health profile response');
      }

      return HealthProfileModel.fromJson(data);
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    String message = 'Something went wrong';

    if (decoded is Map<String, dynamic>) {
      message =
          decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          message;
    }

    // Explicit authentication error
    if (response.statusCode == 401) {
      throw Exception(
        message.isEmpty ? 'Unauthenticated. Please login again.' : message,
      );
    }

    throw Exception(message);
  }

  // ============================================================
  // UPDATE ONBOARDING PROFILE
  // PUT /user/health-profile
  // ============================================================
  Future<HealthProfileModel> updateOnboardingProfile(
    Map<String, dynamic> data,
  ) async {
    final token = _storage.accessToken;

    print('========== ONBOARDING PROFILE UPDATE ==========');
    print('URL: ${ApiConstants.baseUrl}${ApiConstants.healthProfile}');
    print('TOKEN EXISTS: ${token != null && token.trim().isNotEmpty}');
    print('BODY: ${jsonEncode(data)}');

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.healthProfile}'),
      headers: _headers(),
      body: jsonEncode(data),
    );

    print('STATUS: ${response.statusCode}');
    print('RESPONSE: ${response.body}');
    print('===============================================');

    return _handleProfileResponse(response);
  }
}
