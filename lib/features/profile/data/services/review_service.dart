import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_constants.dart';
import '../../../../core/storage/auth_storage.dart';
import '../models/review_model.dart';

class ReviewService {
  Future<ReviewModel> submitReview({
    required String category,
    required String message,
    File? attachment,
    int? rating,
    String? appVersion,
    String? platform,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reviews}');

    final token = await _getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Authentication token is missing. Please log in again.');
    }

    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields['category'] = category;
    request.fields['message'] = message;

    if (rating != null) {
      request.fields['rating'] = rating.toString();
    }

    if (appVersion != null && appVersion.trim().isNotEmpty) {
      request.fields['app_version'] = appVersion.trim();
    }

    if (platform != null && platform.trim().isNotEmpty) {
      request.fields['platform'] = platform.trim();
    }

    if (attachment != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'attachment',
          attachment.path,
          filename: attachment.path.split(Platform.pathSeparator).last,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final decoded = _decodeResponse(response);

    if (response.statusCode == 201 ||
        (response.statusCode >= 200 && response.statusCode < 300)) {
      return _parseReviewResponse(decoded);
    }

    throw Exception(
      _extractErrorMessage(decoded) ??
          'Failed to submit your review. Please try again.',
    );
  }

  Future<String?> _getAccessToken() async {
    return AuthStorage.instance.accessToken;
  }

  ReviewModel _parseReviewResponse(dynamic decoded) {
    if (decoded is! Map) {
      throw Exception('Invalid review response from server.');
    }

    final root = Map<String, dynamic>.from(decoded);
    final data = root['data'];

    if (data is! Map) {
      throw Exception('Invalid review data returned by server.');
    }

    return ReviewModel.fromJson(Map<String, dynamic>.from(data));
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return <String, dynamic>{'message': response.body};
    }
  }

  String? _extractErrorMessage(dynamic decoded) {
    if (decoded is! Map) {
      return null;
    }

    final message = decoded['message']?.toString();

    if (message != null && message.trim().isNotEmpty) {
      return message;
    }

    final error = decoded['error']?.toString();

    if (error != null && error.trim().isNotEmpty) {
      return error;
    }

    return null;
  }
}
