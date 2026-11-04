import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_constants.dart';
import '../../../../core/storage/auth_storage.dart';
import '../models/progress_model.dart';

class ProgressService {
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
  // GET PROGRESS
  //
  // GET /api/progress?filter=today&date=YYYY-MM-DD
  // ============================================================

  Future<ProgressModel> getProgress({
    required String filter,
    String? date,
  }) async {
    final queryParameters = <String, String>{'filter': filter};

    if (date != null && date.trim().isNotEmpty) {
      queryParameters['date'] = date.trim();
    }

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.progress}',
    ).replace(queryParameters: queryParameters);

    print('========== PROGRESS GET ==========');
    print('URL: $uri');

    final response = await http.get(uri, headers: _headers());

    print('STATUS: ${response.statusCode}');
    print('RESPONSE: ${response.body}');
    print('==================================');

    return _handleResponse(response);
  }

  // ============================================================
  // RESPONSE HANDLER
  // ============================================================

  ProgressModel _handleResponse(http.Response response) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid server response (${response.statusCode})');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid progress response');
      }

      final data = decoded['data'];

      if (data is! Map<String, dynamic>) {
        throw Exception('Progress data is missing');
      }

      return ProgressModel.fromJson(data);
    }

    String message = 'Something went wrong';

    if (decoded is Map<String, dynamic>) {
      message =
          decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          message;
    }

    if (response.statusCode == 401) {
      throw Exception(
        message.isEmpty ? 'Unauthenticated. Please login again.' : message,
      );
    }

    if (response.statusCode == 422) {
      throw Exception(message.isEmpty ? 'Invalid progress filter.' : message);
    }

    throw Exception(message);
  }
}
