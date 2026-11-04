import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_constants.dart';
import '../models/app_links_model.dart';

class AppLinksService {
  // ============================================================
  // GET APP LINKS
  // GET /api/app-links
  //
  // Public endpoint.
  // No authentication required.
  // ============================================================

  Future<AppLinksModel> getAppLinks() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.appLinks}');

    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _parseResponse(decoded);
    }

    throw Exception(_extractMessage(decoded) ?? 'Failed to load app links.');
  }

  // ============================================================
  // RESPONSE PARSER
  // ============================================================

  AppLinksModel _parseResponse(dynamic decoded) {
    if (decoded is! Map) {
      throw Exception('Invalid app links response.');
    }

    final root = Map<String, dynamic>.from(decoded);

    final rawData = root['data'];

    if (rawData is! Map) {
      return const AppLinksModel.empty();
    }

    return AppLinksModel.fromJson(Map<String, dynamic>.from(rawData));
  }

  // ============================================================
  // JSON DECODER
  // ============================================================

  dynamic _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid server response (${response.statusCode}).');
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String? _extractMessage(dynamic decoded) {
    if (decoded is Map) {
      return decoded['message']?.toString() ?? decoded['error']?.toString();
    }

    return null;
  }
}
