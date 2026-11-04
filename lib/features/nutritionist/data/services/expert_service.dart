import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_constants.dart';
import '../../../../core/storage/auth_storage.dart';
import '../models/expert_model.dart';

class ExpertService {
  final AuthStorage _storage = AuthStorage.instance;

  static const Duration _requestTimeout = Duration(seconds: 30);

  // ============================================================
  // SAFE DEBUG LOGGING
  // ============================================================

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  // ============================================================
  // AUTHENTICATED HEADERS
  // ============================================================

  Map<String, String> _authHeaders() {
    final token = _storage.accessToken;

    if (token == null || token.trim().isEmpty) {
      throw const ExpertApiException(
        message: 'Your session has expired. Please login again.',
        statusCode: 401,
      );
    }

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // PUBLIC HEADERS
  // ============================================================

  Map<String, String> _publicHeaders() {
    return {'Accept': 'application/json', 'Content-Type': 'application/json'};
  }

  // ============================================================
  // 1. GET ALL EXPERTS
  //
  // GET /api/experts
  // PUBLIC
  // ============================================================

  Future<List<ExpertModel>> getExperts({int page = 1, int perPage = 15}) async {
    if (page < 1) page = 1;
    if (perPage < 1) perPage = 15;

    final uri = Uri.parse('${ApiConstants.baseUrl}/experts').replace(
      queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );

    _log('[EXPERT API] Fetching experts');

    try {
      final response = await http
          .get(uri, headers: _publicHeaders())
          .timeout(_requestTimeout);

      _log('[EXPERT API] HTTP ${response.statusCode}');

      final decoded = _decode(response);

      _ensureSuccess(
        response: response,
        decoded: decoded,
        defaultMessage: 'Unable to load experts.',
      );

      return _parseExperts(decoded);
    } on ExpertApiException {
      rethrow;
    } on SocketException {
      throw const ExpertApiException(
        message: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const ExpertApiException(
        message: 'Request timed out. Please try again.',
      );
    } catch (e) {
      _log('[EXPERT API] Failed to load experts');

      throw const ExpertApiException(
        message: 'Unable to load experts. Please try again.',
      );
    }
  }

  // ============================================================
  // PARSE EXPERT LIST
  // ============================================================

  List<ExpertModel> _parseExperts(dynamic decoded) {
    dynamic data;

    if (decoded is Map) {
      data = decoded['data'] ?? decoded;
    } else {
      data = decoded;
    }

    List<dynamic> listData = [];

    if (data is Map) {
      final dynamic experts = data['experts'];

      if (experts is List) {
        listData = List<dynamic>.from(experts);
      } else {
        final dynamic items = data['items'];

        if (items is List) {
          listData = List<dynamic>.from(items);
        }
      }
    } else if (data is List) {
      listData = List<dynamic>.from(data);
    }

    _log('[EXPERT API] Parsing expert list');

    final Map<int, ExpertModel> uniqueExperts = {};

    for (final item in listData) {
      if (item is! Map) {
        _log('[EXPERT API] Invalid expert item skipped');
        continue;
      }

      try {
        final expertJson = Map<String, dynamic>.from(item);

        final expert = ExpertModel.fromJson(expertJson);

        if (expert.id > 0) {
          uniqueExperts[expert.id] = expert;
        }
      } catch (_) {
        _log('[EXPERT API] Expert item parsing failed');
      }
    }

    final result = uniqueExperts.values.toList();

    _log('[EXPERT API] Expert list parsed successfully');

    return result;
  }

  // ============================================================
  // 2. GET SINGLE EXPERT
  //
  // GET /api/experts/{id}
  // PUBLIC
  // ============================================================

  Future<ExpertModel> getExpert(int expertId) async {
    if (expertId <= 0) {
      throw const ExpertApiException(message: 'Invalid expert ID.');
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/experts/$expertId');

    _log('[EXPERT API] Fetching expert details');

    try {
      final response = await http
          .get(uri, headers: _publicHeaders())
          .timeout(_requestTimeout);

      _log('[EXPERT API] HTTP ${response.statusCode}');

      final decoded = _decode(response);

      _ensureSuccess(
        response: response,
        decoded: decoded,
        defaultMessage: 'Unable to load expert details.',
      );

      dynamic data;

      if (decoded is Map) {
        data = decoded['data'] ?? decoded;
      } else {
        data = decoded;
      }

      if (data is Map) {
        if (data['expert'] is Map) {
          data = data['expert'];
        }

        return ExpertModel.fromJson(Map<String, dynamic>.from(data));
      }

      throw const ExpertApiException(
        message: 'Invalid expert data received from server.',
      );
    } on ExpertApiException {
      rethrow;
    } on SocketException {
      throw const ExpertApiException(
        message: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      throw const ExpertApiException(
        message: 'Request timed out. Please try again.',
      );
    } catch (_) {
      _log('[EXPERT API] Failed to load expert details');

      throw const ExpertApiException(message: 'Unable to load expert details.');
    }
  }

  // ============================================================
  // 3. SEND MESSAGE TO EXPERT
  //
  // POST /api/experts/{expert_id}/messages
  // AUTHENTICATED
  // ============================================================

  Future<Map<String, dynamic>> sendMessage({
    required int expertId,
    required String message,
  }) async {
    if (expertId <= 0) {
      throw const ExpertApiException(message: 'Invalid expert ID.');
    }

    final cleanMessage = message.trim();

    if (cleanMessage.isEmpty) {
      throw const ExpertApiException(message: 'Message cannot be empty.');
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/experts/$expertId/messages');

    _log('[EXPERT API] Sending expert message');

    try {
      final response = await http
          .post(
            uri,
            headers: _authHeaders(),
            body: jsonEncode({'message': cleanMessage}),
          )
          .timeout(_requestTimeout);

      _log('[EXPERT API] HTTP ${response.statusCode}');

      final decoded = _decode(response);

      _ensureSuccess(
        response: response,
        decoded: decoded,
        defaultMessage: 'Unable to send message.',
      );

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return {'data': decoded};
    } on ExpertApiException {
      rethrow;
    } on SocketException {
      throw const ExpertApiException(
        message: 'No internet connection. Please try again.',
      );
    } on TimeoutException {
      throw const ExpertApiException(
        message: 'Message request timed out. Please try again.',
      );
    } catch (_) {
      _log('[EXPERT API] Failed to send message');

      throw const ExpertApiException(
        message: 'Unable to send message. Please try again.',
      );
    }
  }

  // ============================================================
  // 4. GET CHAT HISTORY
  //
  // GET /api/experts/{expert_id}/messages
  // AUTHENTICATED
  // ============================================================

  Future<List<dynamic>> getChatMessages(int expertId) async {
    if (expertId <= 0) {
      throw const ExpertApiException(message: 'Invalid expert ID.');
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/experts/$expertId/messages');

    _log('[EXPERT API] Fetching chat history');

    try {
      final response = await http
          .get(uri, headers: _authHeaders())
          .timeout(_requestTimeout);

      _log('[EXPERT API] HTTP ${response.statusCode}');

      final decoded = _decode(response);

      _ensureSuccess(
        response: response,
        decoded: decoded,
        defaultMessage: 'Unable to load chat history.',
      );

      dynamic data;

      if (decoded is Map) {
        data = decoded['data'] ?? decoded;
      } else {
        data = decoded;
      }

      if (data is Map && data['messages'] is List) {
        return List<dynamic>.from(data['messages']);
      }

      if (data is List) {
        return List<dynamic>.from(data);
      }

      return [];
    } on ExpertApiException {
      rethrow;
    } on SocketException {
      throw const ExpertApiException(
        message: 'No internet connection. Please try again.',
      );
    } on TimeoutException {
      throw const ExpertApiException(
        message: 'Chat history request timed out.',
      );
    } catch (_) {
      _log('[EXPERT API] Failed to load chat history');

      throw const ExpertApiException(message: 'Unable to load chat history.');
    }
  }

  // ============================================================
  // 5. CONSULTATION STATUS
  //
  // GET /api/experts/{expert_id}/consultation-status
  // AUTHENTICATED
  // ============================================================

  Future<Map<String, dynamic>> checkConsultationStatus(int expertId) async {
    if (expertId <= 0) {
      throw const ExpertApiException(message: 'Invalid expert ID.');
    }

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/experts/$expertId/consultation-status',
    );

    _log('[EXPERT API] Checking consultation status');

    try {
      final response = await http
          .get(uri, headers: _authHeaders())
          .timeout(_requestTimeout);

      _log('[EXPERT API] HTTP ${response.statusCode}');

      final decoded = _decode(response);

      _ensureSuccess(
        response: response,
        decoded: decoded,
        defaultMessage: 'Unable to check consultation status.',
      );

      if (decoded is Map) {
        final dynamic data = decoded['data'];

        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }

        return Map<String, dynamic>.from(decoded);
      }

      return {};
    } on ExpertApiException {
      rethrow;
    } on SocketException {
      throw const ExpertApiException(
        message: 'No internet connection. Please try again.',
      );
    } on TimeoutException {
      throw const ExpertApiException(message: 'Status request timed out.');
    } catch (_) {
      _log('[EXPERT API] Consultation status request failed');

      throw const ExpertApiException(
        message: 'Unable to check consultation status.',
      );
    }
  }

  // ============================================================
  // 6. SUBMIT CONSULTATION ENQUIRY
  //
  // POST /api/experts/enquiry
  // AUTHENTICATED
  // ============================================================

  Future<dynamic> consultExpert({
    required int expertId,
    required String message,
  }) async {
    if (expertId <= 0) {
      throw const ExpertApiException(message: 'Invalid expert ID.');
    }

    final cleanMessage = message.trim();

    if (cleanMessage.isEmpty) {
      throw const ExpertApiException(
        message: 'Consultation message cannot be empty.',
      );
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/experts/enquiry');

    _log('[EXPERT API] Creating consultation enquiry');

    try {
      final response = await http
          .post(
            uri,
            headers: _authHeaders(),
            body: jsonEncode({'expert_id': expertId, 'message': cleanMessage}),
          )
          .timeout(_requestTimeout);

      _log('[EXPERT API] HTTP ${response.statusCode}');

      final decoded = _decode(response);

      _ensureSuccess(
        response: response,
        decoded: decoded,
        defaultMessage: 'Unable to create consultation enquiry.',
      );

      return decoded;
    } on ExpertApiException {
      rethrow;
    } on SocketException {
      throw const ExpertApiException(
        message: 'No internet connection. Please try again.',
      );
    } on TimeoutException {
      throw const ExpertApiException(
        message: 'Consultation request timed out. Please try again.',
      );
    } catch (_) {
      _log('[EXPERT API] Consultation enquiry failed');

      throw const ExpertApiException(
        message: 'Unable to create consultation enquiry.',
      );
    }
  }

  // ============================================================
  // 7. CREATE PAYMENT ORDER
  //
  // POST /api/payment/create-order
  // AUTHENTICATED
  // ============================================================

  Future<Map<String, dynamic>> createExpertOrder({
    required int expertId,
    required num amount,
  }) async {
    if (expertId <= 0) {
      throw const ExpertApiException(message: 'Invalid expert ID.');
    }

    if (!amount.isFinite || amount <= 0) {
      throw const ExpertApiException(message: 'Invalid consultation amount.');
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/payment/create-order');

    _log('[EXPERT PAYMENT] Creating payment order');

    try {
      final response = await http
          .post(
            uri,
            headers: _authHeaders(),
            body: jsonEncode({'expert_id': expertId, 'amount': amount}),
          )
          .timeout(_requestTimeout);

      _log('[EXPERT PAYMENT] HTTP ${response.statusCode}');

      final decoded = _decode(response);

      _ensureSuccess(
        response: response,
        decoded: decoded,
        defaultMessage: 'Unable to create payment order.',
      );

      if (decoded is Map) {
        final dynamic data = decoded['data'];

        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }

        return Map<String, dynamic>.from(decoded);
      }

      throw const ExpertApiException(
        message: 'Invalid payment order response from server.',
      );
    } on ExpertApiException {
      rethrow;
    } on SocketException {
      throw const ExpertApiException(
        message: 'No internet connection. Please try again.',
      );
    } on TimeoutException {
      throw const ExpertApiException(
        message: 'Payment order request timed out.',
      );
    } catch (_) {
      _log('[EXPERT PAYMENT] Payment order creation failed');

      throw const ExpertApiException(
        message: 'Unable to create payment order.',
      );
    }
  }

  // ============================================================
  // 8. VERIFY PAYMENT
  //
  // POST /api/payment/verify
  // AUTHENTICATED
  // ============================================================

  Future<bool> verifyExpertPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required int enquiryId,
  }) async {
    if (orderId.trim().isEmpty) {
      throw const ExpertApiException(message: 'Payment order ID is missing.');
    }

    if (paymentId.trim().isEmpty) {
      throw const ExpertApiException(message: 'Payment ID is missing.');
    }

    if (signature.trim().isEmpty) {
      throw const ExpertApiException(message: 'Payment signature is missing.');
    }

    if (enquiryId <= 0) {
      throw const ExpertApiException(
        message: 'Invalid consultation enquiry ID.',
      );
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/payment/verify');

    _log('[EXPERT PAYMENT] Verifying payment');

    try {
      final response = await http
          .post(
            uri,
            headers: _authHeaders(),
            body: jsonEncode({
              'razorpay_order_id': orderId,
              'razorpay_payment_id': paymentId,
              'razorpay_signature': signature,
              'enquiry_id': enquiryId,
            }),
          )
          .timeout(_requestTimeout);

      _log('[EXPERT PAYMENT] HTTP ${response.statusCode}');

      final decoded = _decode(response);

      _ensureSuccess(
        response: response,
        decoded: decoded,
        defaultMessage: 'Unable to verify payment.',
      );

      // Require an explicit success response from the backend.
      // HTTP 200 alone does not prove payment verification.
      if (decoded is! Map || decoded['success'] != true) {
        throw ExpertApiException(
          message: _extractMessage(
            decoded,
            statusCode: response.statusCode,
            fallback: 'Payment verification failed.',
          ),
          statusCode: response.statusCode,
        );
      }

      _log('[EXPERT PAYMENT] Verification confirmed by backend');

      return true;
    } on ExpertApiException {
      rethrow;
    } on SocketException {
      throw const ExpertApiException(
        message: 'No internet connection. Please try again.',
      );
    } on TimeoutException {
      throw const ExpertApiException(
        message: 'Payment verification timed out. Please try again.',
      );
    } catch (_) {
      _log('[EXPERT PAYMENT] Payment verification request failed');

      throw const ExpertApiException(
        message: 'Unable to verify payment. Please try again.',
      );
    }
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  dynamic _decode(http.Response response) {
    final body = response.body.trim();

    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      _log('[EXPERT API] Invalid JSON response');

      throw ExpertApiException(
        message: 'Server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }
  }

  // ============================================================
  // ENSURE SUCCESS
  // ============================================================

  void _ensureSuccess({
    required http.Response response,
    required dynamic decoded,
    required String defaultMessage,
  }) {
    final bool httpSuccess =
        response.statusCode >= 200 && response.statusCode < 300;

    final bool explicitlyFailed = decoded is Map && decoded['success'] == false;

    if (httpSuccess && !explicitlyFailed) {
      return;
    }

    throw ExpertApiException(
      message: _extractMessage(
        decoded,
        statusCode: response.statusCode,
        fallback: defaultMessage,
      ),
      statusCode: response.statusCode,
    );
  }

  // ============================================================
  // ERROR EXTRACTOR
  // ============================================================

  String _extractMessage(
    dynamic decoded, {
    int? statusCode,
    String fallback = 'Something went wrong. Please try again.',
  }) {
    String? message;

    if (decoded is Map) {
      final dynamic rawMessage = decoded['message'];

      if (rawMessage != null && rawMessage.toString().trim().isNotEmpty) {
        message = rawMessage.toString().trim();
      }

      if (message == null) {
        final dynamic rawError = decoded['error'];

        if (rawError != null && rawError.toString().trim().isNotEmpty) {
          message = rawError.toString().trim();
        }
      }

      if (message == null) {
        final dynamic errors = decoded['errors'];

        if (errors is Map) {
          final List<String> messages = [];

          for (final value in errors.values) {
            if (value is List) {
              for (final item in value) {
                final text = item.toString().trim();

                if (text.isNotEmpty) {
                  messages.add(text);
                }
              }
            } else {
              final text = value.toString().trim();

              if (text.isNotEmpty) {
                messages.add(text);
              }
            }
          }

          if (messages.isNotEmpty) {
            message = messages.join('\n');
          }
        }
      }
    }

    if (message != null && message.isNotEmpty) {
      return message;
    }

    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your details.';

      case 401:
        return 'Your session has expired. Please login again.';

      case 403:
        return 'You are not allowed to perform this action.';

      case 404:
        return 'Requested resource was not found.';

      case 409:
        return 'This request conflicts with existing data.';

      case 422:
        return 'Some information is invalid. Please check and try again.';

      case 429:
        return 'Too many requests. Please wait and try again.';

      case 500:
      case 502:
      case 503:
      case 504:
        return 'Server is temporarily unavailable. Please try again later.';
    }

    return fallback;
  }
}

// ============================================================
// CUSTOM API EXCEPTION
// ============================================================

class ExpertApiException implements Exception {
  final String message;
  final int? statusCode;

  const ExpertApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}
