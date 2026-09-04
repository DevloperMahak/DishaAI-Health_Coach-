import 'dart:convert';

import 'package:disha_ai/features/nutritionist/data/models/expert_model.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_constants.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../ai_health_coach/data/models/ai_response_model.dart';

class ExpertService {
  final AuthStorage _storage = AuthStorage.instance;

  // ============================================================
  // HEADERS
  // ============================================================

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

  // ============================================================
  // GET EXPERT LIST
  // GET /experts
  // ============================================================

  Future<List<ExpertModel>> getExperts() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/experts'),
      headers: _headers(),
    );

    final decoded = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = decoded is Map<String, dynamic>
          ? decoded['data'] ?? decoded
          : decoded;

      List listData = [];
      if (data is List) {
        listData = data;
      } else if (data is Map && data['experts'] is List) {
        listData = data['experts'];
      }

      return listData
          .map((e) => ExpertModel.fromJson(e))
          .toSet()
          .toList()
          .cast<ExpertModel>();
    }

    throw Exception(_extractMessage(decoded));
  }

  // ============================================================
  // CONSULT NOW / EXPERT ENQUIRY
  // POST /experts/enquiry
  // ============================================================

  Future<AiResponseModel> consultExpert({
    required int expertId,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/experts/enquiry'),
      headers: _headers(),
      body: jsonEncode({'expert_id': expertId, 'message': message}),
    );

    final decoded = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return AiResponseModel.fromJson(decoded);
      }
      return AiResponseModel(data: decoded);
    }

    throw Exception(_extractMessage(decoded));
  }

  // ============================================================
  // JSON DECODE
  // ============================================================

  dynamic _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid server response (${response.statusCode})');
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _extractMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      return decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          'Something went wrong';
    }

    return 'Something went wrong';
  }
}
