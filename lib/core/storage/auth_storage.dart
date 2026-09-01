import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class AuthStorage {
  AuthStorage._();

  static final AuthStorage instance = AuthStorage._();

  final GetStorage _storage = GetStorage();

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'current_user';

  // ============================================================
  // ACCESS TOKEN
  // ============================================================

  String? get accessToken {
    return _storage.read<String>(accessTokenKey);
  }

  Future<void> saveAccessToken(String token) async {
    await _storage.write(accessTokenKey, token);
  }

  // ============================================================
  // REFRESH TOKEN
  // ============================================================

  String? get refreshToken {
    return _storage.read<String>(refreshTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(refreshTokenKey, token);
  }

  // ============================================================
  // USER
  // ============================================================

  Map<String, dynamic>? get currentUser {
    final value = _storage.read(userKey);

    if (value == null) {
      return null;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is String) {
      try {
        return Map<String, dynamic>.from(jsonDecode(value));
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  Future<void> saveCurrentUser(Map<String, dynamic> user) async {
    await _storage.write(userKey, user);
  }

  // ============================================================
  // AUTH STATE
  // ============================================================

  bool get isLoggedIn {
    final token = accessToken;

    return token != null && token.isNotEmpty;
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<void> clear() async {
    await _storage.remove(accessTokenKey);
    await _storage.remove(refreshTokenKey);
    await _storage.remove(userKey);
  }
}
