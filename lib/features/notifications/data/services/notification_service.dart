import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_constants.dart';
import '../../../../core/storage/auth_storage.dart';
import '../models/notification_model.dart';

class NotificationPageResult {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const NotificationPageResult({
    required this.notifications,
    required this.unreadCount,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;
}

class NotificationService {
  final AuthStorage _storage = AuthStorage.instance;

  // ============================================================
  // DEBUG LOGGER
  // ============================================================

  void _log(String message) {
    debugPrint('[NOTIFICATION API] $message');
  }

  // ============================================================
  // HEADERS
  // ============================================================

  Map<String, String> _headers() {
    final token = _storage.accessToken;

    if (token == null || token.isEmpty) {
      _log('ERROR: Authentication token not found');
      throw Exception('Authentication token not found. Please login again.');
    }

    _log('Authorization token available: true');

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // API RESPONSE LOGGER
  // ============================================================

  void _logResponse({
    required String method,
    required Uri uri,
    required http.Response response,
  }) {
    _log('$method ${uri.path}');
    _log('HTTP Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _log('API request SUCCESS');
    } else {
      _log('API request FAILED');
    }
  }

  // ============================================================
  // GET NOTIFICATIONS
  // GET /api/notifications?page=1&per_page=20
  // ============================================================

  Future<NotificationPageResult> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    final uri =
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.notifications}',
        ).replace(
          queryParameters: {
            'page': page.toString(),
            'per_page': perPage.toString(),
          },
        );

    _log('Fetching notifications. Page: $page');

    final response = await http.get(uri, headers: _headers());

    _logResponse(method: 'GET', uri: uri, response: response);

    final decoded = _decodeResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final result = _parseNotificationResponse(decoded);

      _log('Notifications received: ${result.notifications.length}');
      _log('Unread count: ${result.unreadCount}');

      return result;
    }

    _log('Error: ${_extractMessage(decoded)}');

    throw Exception(
      _extractMessage(decoded) ?? 'Failed to load notifications.',
    );
  }

  // ============================================================
  // MARK NOTIFICATION AS READ
  // POST /api/notifications/{id}/read
  // ============================================================

  Future<bool> markAsRead(String notificationId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}'
      '${ApiConstants.notifications}/'
      '$notificationId/read',
    );

    _log('Marking notification as read');

    final response = await http.post(uri, headers: _headers());

    _logResponse(method: 'POST', uri: uri, response: response);

    final decoded = _decodeResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _log('Notification marked as read');
      return true;
    }

    throw Exception(
      _extractMessage(decoded) ?? 'Failed to mark notification as read.',
    );
  }

  // ============================================================
  // MARK ALL NOTIFICATIONS AS READ
  // POST /api/notifications/read-all
  // ============================================================

  Future<bool> markAllAsRead() async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}'
      '${ApiConstants.notificationReadAll}',
    );

    _log('Marking all notifications as read');

    final response = await http.post(uri, headers: _headers());

    _logResponse(method: 'POST', uri: uri, response: response);

    final decoded = _decodeResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _log('All notifications marked as read');
      return true;
    }

    throw Exception(
      _extractMessage(decoded) ?? 'Failed to mark all notifications as read.',
    );
  }

  // ============================================================
  // DELETE NOTIFICATION
  // DELETE /api/notifications/{id}
  // ============================================================

  Future<bool> deleteNotification(String notificationId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}'
      '${ApiConstants.notifications}/'
      '$notificationId',
    );

    _log('Deleting notification');

    final response = await http.delete(uri, headers: _headers());

    _logResponse(method: 'DELETE', uri: uri, response: response);

    final decoded = _decodeResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _log('Notification deleted successfully');
      return true;
    }

    throw Exception(
      _extractMessage(decoded) ?? 'Failed to delete notification.',
    );
  }

  // ============================================================
  // REGISTER FCM DEVICE TOKEN
  // POST /api/device-token
  // ============================================================

  Future<bool> registerDeviceToken({
    required String token,
    String platform = 'android',
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}'
      '${ApiConstants.deviceToken}',
    );

    if (token.trim().isEmpty) {
      _log('ERROR: Cannot register empty FCM token');
      throw Exception('FCM device token is empty.');
    }

    _log('==========================================');
    _log('FCM DEVICE REGISTRATION STARTED');
    _log('API: POST ${uri.path}');
    _log('Platform: $platform');
    _log('FCM token available: true');
    _log('FCM token length: ${token.length}');

    try {
      final response = await http.post(
        uri,
        headers: _headers(),
        body: jsonEncode({'token': token, 'platform': platform}),
      );

      _logResponse(method: 'POST', uri: uri, response: response);

      final decoded = _decodeResponse(response);
      _log('Registration response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log('FCM DEVICE REGISTRATION SUCCESS');
        _log('Device is registered with Laravel');
        _log('==========================================');

        return true;
      }

      _log('FCM DEVICE REGISTRATION FAILED');
      _log('Server message: ${_extractMessage(decoded)}');
      _log('==========================================');

      throw Exception(
        _extractMessage(decoded) ?? 'Failed to register device token.',
      );
    } catch (e) {
      _log('FCM registration exception: $e');
      rethrow;
    }
  }

  // ============================================================
  // REMOVE FCM DEVICE TOKEN
  // DELETE /api/device-token
  // ============================================================

  Future<bool> removeDeviceToken({required String token}) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}'
      '${ApiConstants.deviceToken}',
    );

    if (token.trim().isEmpty) {
      _log('ERROR: Cannot remove empty FCM token');
      throw Exception('FCM device token is empty.');
    }

    _log('==========================================');
    _log('FCM DEVICE UNREGISTER STARTED');
    _log('API: DELETE ${uri.path}');
    _log('FCM token available: true');

    try {
      final response = await http.delete(
        uri,
        headers: _headers(),
        body: jsonEncode({'token': token}),
      );

      _logResponse(method: 'DELETE', uri: uri, response: response);

      final decoded = _decodeResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log('FCM DEVICE UNREGISTER SUCCESS');
        _log('==========================================');

        return true;
      }

      _log('FCM DEVICE UNREGISTER FAILED');
      _log('Server message: ${_extractMessage(decoded)}');
      _log('==========================================');

      throw Exception(
        _extractMessage(decoded) ?? 'Failed to remove device token.',
      );
    } catch (e) {
      _log('FCM unregister exception: $e');
      rethrow;
    }
  }

  // ============================================================
  // RESPONSE DECODING
  // ============================================================

  dynamic _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      _log('Invalid JSON response. HTTP: ${response.statusCode}');

      throw Exception('Invalid server response (${response.statusCode}).');
    }
  }

  // ============================================================
  // PARSE NOTIFICATION RESPONSE
  // ============================================================

  NotificationPageResult _parseNotificationResponse(dynamic decoded) {
    if (decoded is! Map) {
      throw Exception('Invalid notifications response.');
    }

    final Map<String, dynamic> root = Map<String, dynamic>.from(decoded);

    final dynamic rawData = root['data'];

    if (rawData is! Map) {
      return const NotificationPageResult(
        notifications: [],
        unreadCount: 0,
        currentPage: 1,
        perPage: 20,
        total: 0,
        lastPage: 1,
      );
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);

    final dynamic rawNotifications = data['notifications'];

    final List<NotificationModel> notifications = [];

    if (rawNotifications is List) {
      for (final item in rawNotifications) {
        if (item is Map) {
          notifications.add(
            NotificationModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final dynamic rawPagination = data['pagination'];

    final Map<String, dynamic> pagination = rawPagination is Map
        ? Map<String, dynamic>.from(rawPagination)
        : <String, dynamic>{};

    return NotificationPageResult(
      notifications: notifications,
      unreadCount: _toInt(data['unread_count']),
      currentPage: _toInt(pagination['current_page'], fallback: 1),
      perPage: _toInt(pagination['per_page'], fallback: 20),
      total: _toInt(pagination['total']),
      lastPage: _toInt(pagination['last_page'], fallback: 1),
    );
  }

  // ============================================================
  // INTEGER CONVERSION
  // ============================================================

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  // ============================================================
  // EXTRACT MESSAGE
  // ============================================================

  String? _extractMessage(dynamic decoded) {
    if (decoded is Map) {
      return decoded['message']?.toString() ?? decoded['error']?.toString();
    }

    return null;
  }
}
