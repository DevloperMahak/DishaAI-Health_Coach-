import 'package:dio/dio.dart';

import '../datasources/auth_remote_datasource.dart';

class AuthRepository {
  AuthRepository({AuthRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource();

  final AuthRemoteDataSource _remoteDataSource;

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<Response<dynamic>> sendOtp({required String mobile}) {
    return _remoteDataSource.sendOtp(mobile: mobile);
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<Response<dynamic>> verifyOtp({
    required String mobile,
    required String otp,
  }) {
    return _remoteDataSource.verifyOtp(mobile: mobile, otp: otp);
  }

  // ============================================================
  // REFRESH TOKEN
  // ============================================================

  Future<Response<dynamic>> refreshToken() {
    return _remoteDataSource.refreshToken();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<Response<dynamic>> logout() {
    return _remoteDataSource.logout();
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  Future<Response<dynamic>> getCurrentUser() {
    return _remoteDataSource.getCurrentUser();
  }
}
