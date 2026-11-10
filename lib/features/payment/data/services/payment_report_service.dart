import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_constants.dart';
import '../../../../core/storage/auth_storage.dart';
import '../models/payment_report_models.dart';

class PaymentReportService {
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
  // 1. GET MEMBERSHIP PLANS
  // GET /membership/plans
  // ============================================================

  Future<List<Map<String, dynamic>>> getMembershipPlans() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/membership/plans');

    debugPrint('========== GET MEMBERSHIP PLANS ==========');
    debugPrint('URL: $uri');

    final response = await http.get(uri, headers: _headers());

    debugPrint('STATUS: ${response.statusCode}');

    final decoded = _decode(response);

    if (!_isSuccessful(response, decoded)) {
      throw Exception(_extractMessage(decoded));
    }

    final data = _extractData(decoded);
    final plans = data['plans'];

    if (plans is! List) {
      throw Exception('Invalid membership plans response');
    }

    return plans
        .whereType<Map>()
        .map((plan) => Map<String, dynamic>.from(plan))
        .toList();
  }

  // ============================================================
  // 2. GET MEMBERSHIP STATUS
  // GET /membership/status
  // ============================================================

  Future<Map<String, dynamic>> getMembershipStatus() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/membership/status');

    debugPrint('========== GET MEMBERSHIP STATUS ==========');
    debugPrint('URL: $uri');

    final response = await http.get(uri, headers: _headers());

    debugPrint('STATUS: ${response.statusCode}');

    final decoded = _decode(response);

    if (!_isSuccessful(response, decoded)) {
      throw Exception(_extractMessage(decoded));
    }

    return _extractData(decoded);
  }

  // ============================================================
  // 3. CREATE MEMBERSHIP RAZORPAY ORDER
  // POST /payment/create-order
  //
  // Request:
  // {
  //   "plan_code": "initial_access"
  // }
  //
  // Amount is determined by backend.
  // ============================================================

  Future<PaymentOrderModel> createMembershipOrder({
    required String planCode,
  }) async {
    if (planCode.trim().isEmpty) {
      throw Exception('Membership plan code is required');
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/payment/create-order');

    final body = {'plan_code': planCode.trim()};

    debugPrint('========== CREATE MEMBERSHIP ORDER ==========');
    debugPrint('URL: $uri');
    debugPrint('BODY: ${jsonEncode(body)}');

    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );

    debugPrint('STATUS: ${response.statusCode}');

    return _handleOrderResponse(response);
  }

  // ============================================================
  // 4. VERIFY MEMBERSHIP RAZORPAY PAYMENT
  // POST /payment/verify
  //
  // Request:
  // {
  //   "razorpay_order_id": "...",
  //   "razorpay_payment_id": "...",
  //   "razorpay_signature": "..."
  // }
  //
  // Do not send payment_type or plan_code here.
  // ============================================================

  Future<Map<String, dynamic>> verifyMembershipPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    if (orderId.trim().isEmpty ||
        paymentId.trim().isEmpty ||
        signature.trim().isEmpty) {
      throw Exception('Incomplete Razorpay payment details');
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/payment/verify');

    final body = {
      'razorpay_order_id': orderId.trim(),
      'razorpay_payment_id': paymentId.trim(),
      'razorpay_signature': signature.trim(),
    };

    debugPrint('========== VERIFY MEMBERSHIP PAYMENT ==========');
    //debugPrint('URL: $uri');
    //debugPrint('ORDER ID: $orderId');
    //debugPrint('PAYMENT ID: $paymentId');

    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );

    debugPrint('STATUS: ${response.statusCode}');

    final decoded = _decode(response);

    if (!_isSuccessful(response, decoded)) {
      throw Exception(_extractMessage(decoded));
    }

    debugPrint('Membership payment verified successfully');

    return _extractData(decoded);
  }

  // ============================================================
  // 5. GET MEMBERSHIP HISTORY
  // GET /membership/history
  // ============================================================

  Future<Map<String, dynamic>> getMembershipHistory() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/membership/history');

    final response = await http.get(uri, headers: _headers());

    final decoded = _decode(response);

    if (!_isSuccessful(response, decoded)) {
      throw Exception(_extractMessage(decoded));
    }

    return _extractData(decoded);
  }

  // ============================================================
  // 6. GET CURRENT USER / ONBOARDING STATUS
  // GET /auth/me
  // ============================================================

  Future<bool> isOnboardingCompleted() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/auth/me');

    debugPrint('========== CHECK ONBOARDING STATUS ==========');

    final response = await http.get(uri, headers: _headers());

    debugPrint('STATUS: ${response.statusCode}');

    final decoded = _decode(response);

    if (!_isSuccessful(response, decoded)) {
      throw Exception(_extractMessage(decoded));
    }

    final data = _extractData(decoded);
    final user = data['user'];

    final onboardingCompleted =
        data['onboarding_completed'] ??
        (user is Map ? user['onboarding_completed'] : null);

    return _parseBool(onboardingCompleted);
  }

  // ============================================================
  // 7. FETCH WEEKLY REPORT
  // GET /reports/weekly
  // ============================================================

  Future<HealthReportModel> getWeeklyReport() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/reports/weekly'),
      headers: _headers(),
    );

    return _handleReportResponse(response);
  }

  // ============================================================
  // 8. FETCH MONTHLY REPORT
  // GET /reports/monthly
  // ============================================================

  Future<HealthReportModel> getMonthlyReport() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/reports/monthly'),
      headers: _headers(),
    );

    return _handleReportResponse(response);
  }

  // ============================================================
  // ORDER RESPONSE HANDLER
  // ============================================================

  PaymentOrderModel _handleOrderResponse(http.Response response) {
    final decoded = _decode(response);

    if (_isSuccessful(response, decoded)) {
      return PaymentOrderModel.fromJson(_extractData(decoded));
    }

    throw Exception(_extractMessage(decoded));
  }

  // ============================================================
  // REPORT RESPONSE HANDLER
  // ============================================================

  HealthReportModel _handleReportResponse(http.Response response) {
    final decoded = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded['success'] == false) {
        throw Exception(_extractMessage(decoded));
      }

      return HealthReportModel.fromJson(_extractData(decoded));
    }

    throw Exception(_extractMessage(decoded));
  }

  // ============================================================
  // COMMON SUCCESS CHECK
  // ============================================================

  bool _isSuccessful(http.Response response, dynamic decoded) {
    return response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded is Map<String, dynamic> &&
        decoded['success'] == true;
  }

  // ============================================================
  // DECODE RESPONSE
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

    throw Exception('Invalid server response structure');
  }

  // ============================================================
  // PARSE BOOLEAN
  // ============================================================

  bool _parseBool(dynamic value) {
    if (value is bool) return value;

    if (value is int) return value == 1;

    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }

    return false;
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
