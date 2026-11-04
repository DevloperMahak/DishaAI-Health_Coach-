import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/today_progress_model.dart';

class TodayProgressService {
  final Dio _dio = ApiClient.instance.dio;

  Future<TodayProgressModel> getTodayProgress({String? date}) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (date != null && date.trim().isNotEmpty) {
        queryParameters['date'] = date.trim();
      }

      final response = await _dio.get(
        ApiConstants.todayProgress,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      final decoded = response.data;

      Map<String, dynamic> data = {};

      if (decoded is Map) {
        if (decoded['data'] is Map) {
          data = Map<String, dynamic>.from(decoded['data'] as Map);
        } else {
          data = Map<String, dynamic>.from(decoded);
        }
      }

      return TodayProgressModel.fromJson(data);
    } on DioException catch (e) {
      final responseData = e.response?.data;

      String message = 'Failed to load today progress';

      if (responseData is Map) {
        message =
            responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            message;
      }

      throw Exception(message);
    }
  }
}
