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
  // 1. CREATE RAZORPAY ORDER
  // POST /payment/create-order
  // ============================================================

  Future<PaymentOrderModel> createOrder(num amount) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/payment/create-order'),
      headers: _headers(),
      body: jsonEncode({'amount': amount}),
    );

    debugPrint('PAYMENT ORDER STATUS: ${response.statusCode}');
    debugPrint('PAYMENT ORDER BODY: ${response.body}');

    return _handleOrderResponse(response);
  }

  // ============================================================
  // 2. VERIFY PAYMENT SIGNATURE
  // POST /payment/verify
  // ============================================================

  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/payment/verify'),
      headers: _headers(),
      body: jsonEncode({
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      }),
    );

    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    throw Exception(_extractMessage(decoded));
  }

  // ============================================================
  // 3. FETCH WEEKLY REPORT
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
  // 4. FETCH MONTHLY REPORT
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
  // RESPONSE HANDLERS
  // ============================================================

  PaymentOrderModel _handleOrderResponse(http.Response response) {
    final decoded = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _extractData(decoded);
      return PaymentOrderModel.fromJson(data);
    }

    throw Exception(_extractMessage(decoded));
  }

  HealthReportModel _handleReportResponse(http.Response response) {
    final decoded = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _extractData(decoded);
      return HealthReportModel.fromJson(data);
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

    throw Exception('Invalid server response structure');
  }

  // ============================================================
  // ERROR MESSAGE
  // =================================================5===========

  String _extractMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      return decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          'Something went wrong';
    }

    return 'Something went wrong';
  }
}
