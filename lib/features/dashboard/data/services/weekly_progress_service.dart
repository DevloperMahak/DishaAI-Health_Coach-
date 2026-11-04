import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_constants.dart';
import '../../../../core/storage/auth_storage.dart';
import '../models/weekly_progress_model.dart';

class WeeklyProgressService {
  final AuthStorage _storage = AuthStorage.instance;

  Map<String, String> _headers() {
    final token = _storage.accessToken;

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<WeeklyProgressModel> getWeeklyProgress({
    String? startDate,
    String? endDate,
  }) async {
    final queryParameters = <String, String>{};

    if (startDate != null && startDate.isNotEmpty) {
      queryParameters['start_date'] = startDate;
    }

    if (endDate != null && endDate.isNotEmpty) {
      queryParameters['end_date'] = endDate;
    }

    final uri =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.weeklyProgress}',
        ).replace(
          queryParameters: queryParameters.isEmpty ? null : queryParameters,
        );

    print('========== WEEKLY PROGRESS GET ==========');
    print('URL: $uri');

    final response = await http.get(uri, headers: _headers());

    print('STATUS: ${response.statusCode}');
    print('RESPONSE: ${response.body}');
    print('=========================================');

    return _handleResponse(response);
  }

  WeeklyProgressModel _handleResponse(http.Response response) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid server response (${response.statusCode})');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _extractData(decoded);

      return WeeklyProgressModel.fromJson(data);
    }

    throw Exception(_extractMessage(decoded));
  }

  Map<String, dynamic> _extractData(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];

      if (data is Map<String, dynamic>) {
        return data;
      }

      return decoded;
    }

    throw Exception('Invalid weekly progress response');
  }

  String _extractMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      return decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          'Unable to fetch weekly progress';
    }

    return 'Unable to fetch weekly progress';
  }
}
