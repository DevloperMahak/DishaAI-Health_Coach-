import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<Response<dynamic>> sendOtp({required String mobile}) async {
    return await _dio.post(ApiConstants.sendOtp, data: {'mobile': mobile});
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<Response<dynamic>> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    return await _dio.post(
      ApiConstants.verifyOtp,
      data: {'mobile': mobile, 'otp': otp},
    );
  }

  // ============================================================
  // REFRESH TOKEN
  // ============================================================

  Future<Response<dynamic>> refreshToken() async {
    return await _dio.post(ApiConstants.refreshToken);
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<Response<dynamic>> logout() async {
    return await _dio.post(ApiConstants.logout);
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  Future<Response<dynamic>> getCurrentUser() async {
    return await _dio.get(ApiConstants.currentUser);
  }
}
