import 'dart:convert';

import 'package:disha_ai/features/dashboard/data/models/quick_action_category_model.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_constants.dart';
import '../../../../core/storage/auth_storage.dart';

import 'package:disha_ai/features/dashboard/data/models/dashboard_model.dart';
import 'package:disha_ai/features/dashboard/data/models/today_summary_model.dart';

class DashboardService {
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
  // DASHBOARD OVERVIEW
  // GET /dashboard
  // ============================================================

  Future<DashboardModel> getDashboard() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.dashboard}'),
      headers: _headers(),
    );

    return _handleDashboardResponse(response);
  }

  // ============================================================
  // TODAY SUMMARY
  // GET /today-summary
  // ============================================================

  Future<TodaySummaryModel> getTodaySummary() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.todaySummary}'),
      headers: _headers(),
    );

    return _handleTodaySummaryResponse(response);
  }

  // ============================================================
  // QUICK ACTION CATEGORIES
  // GET /quick-actions
  // ============================================================

  Future<List<QuickActionCategoryModel>> getQuickActions() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/quick-actions'),
      headers: _headers(),
    );

    final decoded = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      dynamic rawList;

      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];

        if (data is Map<String, dynamic>) {
          rawList = data['categories'];
        } else if (data is List) {
          rawList = data;
        }
      }

      if (rawList is List) {
        final categories = rawList
            .whereType<Map>()
            .map(
              (item) => QuickActionCategoryModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

        categories.sort((a, b) => a.order.compareTo(b.order));

        return categories;
      }

      return <QuickActionCategoryModel>[];
    }

    throw Exception(_extractMessage(decoded));
  }

  // ============================================================
  // QUICK ACTION CATEGORY DETAILS
  //
  // GET /quick-actions/{slug}
  //
  // Example:
  // GET /quick-actions/meditation
  // GET /quick-actions/workout
  // ============================================================

  Future<Map<String, dynamic>> getQuickActionCategory(String slug) async {
    final cleanSlug = slug.trim();

    if (cleanSlug.isEmpty) {
      throw Exception('Category slug is required');
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/quick-actions/${Uri.encodeComponent(cleanSlug)}',
      ),
      headers: _headers(),
    );

    final decoded = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _extractData(decoded);

      return data;
    }

    throw Exception(_extractMessage(decoded));
  }

  // ============================================================
  // DASHBOARD RESPONSE
  // ============================================================

  DashboardModel _handleDashboardResponse(http.Response response) {
    final decoded = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _extractData(decoded);

      return DashboardModel.fromJson(data);
    }

    throw Exception(_extractMessage(decoded));
  }

  // ============================================================
  // TODAY SUMMARY RESPONSE
  // ============================================================

  TodaySummaryModel _handleTodaySummaryResponse(http.Response response) {
    final decoded = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _extractData(decoded);

      return TodaySummaryModel.fromJson(data);
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
  // EXTRACT DATA
  // ============================================================

  Map<String, dynamic> _extractData(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];

      if (data is Map<String, dynamic>) {
        return data;
      }

      return decoded;
    }

    throw Exception('Invalid server response');
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
