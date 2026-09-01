import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationService {
  static const String _baseUrl =
      'https://rhea-ai.acttconnect.com/api/notifications';

  // Helper to get headers with the Auth Token
  Future<Map<String, String>> _getHeaders() async {
    // TODO: Fetch your actual saved bearer token here
    const String token = 'YOUR_ACCESS_TOKEN';

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // GET /api/notifications
  // ============================================================
  Future<List<NotificationModel>> getNotifications() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(_baseUrl), headers: headers);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // Handle array wrapped in a 'data' key or direct array
      final List<dynamic> data = decoded['data'] is List
          ? decoded['data']
          : (decoded is List ? decoded : []);

      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notifications: ${response.statusCode}');
    }
  }

  // ============================================================
  // PUT /api/notifications/read
  // ============================================================
  Future<bool> markAllAsRead() async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl/read'),
      headers: headers,
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to mark notifications as read');
    }
  }

  // ============================================================
  // DELETE /api/notifications
  // ============================================================
  Future<bool> deleteNotifications() async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse(_baseUrl), headers: headers);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to delete notifications');
    }
  }
}
