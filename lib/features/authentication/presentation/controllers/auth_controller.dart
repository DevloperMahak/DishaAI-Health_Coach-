import 'dart:convert';

import 'package:disha_ai/core/notifications/fcm_notification_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class AuthController extends GetxController {
  // ============================================================
  // BASE URL
  // ============================================================

  static const String baseUrl = 'https://rhea-ai.acttconnect.com/api';

  // ============================================================
  // STORAGE
  // ============================================================

  final GetStorage _storage = GetStorage();

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'current_user';

  // ============================================================
  // OBSERVABLE STATE
  // ============================================================

  final RxBool isLoading = false.obs;

  final RxBool isAuthenticated = false.obs;

  final Rxn<Map<String, dynamic>> currentUser = Rxn<Map<String, dynamic>>();

  // ============================================================
  // TOKEN GETTERS
  // ============================================================

  String? get accessToken {
    final token = _storage.read<String>(accessTokenKey);

    if (token == null) return null;

    final trimmedToken = token.trim();

    if (trimmedToken.isEmpty) return null;

    return trimmedToken;
  }

  String? get refreshToken {
    final token = _storage.read<String>(refreshTokenKey);

    if (token == null) return null;

    final trimmedToken = token.trim();

    if (trimmedToken.isEmpty) return null;

    return trimmedToken;
  }

  // ============================================================
  // AUTH STATUS
  // ============================================================

  bool get isLoggedIn {
    final token = accessToken;

    return token != null && token.isNotEmpty;
  }

  // ============================================================
  // FCM TOKEN REGISTRATION
  // ============================================================

  /// Registers the current Firebase device token with Laravel.
  ///
  /// This method must be called only after an authenticated
  /// access token has been saved.
  ///
  /// FCM failure must never interrupt the authentication flow.
  Future<void> _registerFcmTokenSafely() async {
    try {
      print('📡 Registering FCM device token...');

      final success = await FcmNotificationService.instance
          .registerCurrentTokenWithBackend();

      if (success) {
        print('✅ FCM device token registered successfully');
      } else {
        print('⚠️ FCM device token registration unsuccessful');
      }
    } catch (e) {
      print('⚠️ FCM registration error: $e');
    }
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<Map<String, dynamic>> sendOtp({required String mobile}) async {
    try {
      isLoading.value = true;

      final uri = Uri.parse('$baseUrl/auth/send-otp');

      final response = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'mobile': mobile.trim()}),
      );

      final data = _decodeResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': _extractMessage(data) ?? 'OTP sent successfully',
          'data': data,
        };
      }

      return {
        'success': false,
        'message':
            _extractMessage(data) ?? 'Unable to send OTP. Please try again.',
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': _networkErrorMessage(e)};
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<Map<String, dynamic>> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      isLoading.value = true;

      final uri = Uri.parse('$baseUrl/auth/verify-otp');

      final response = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'mobile': mobile.trim(), 'otp': otp.trim()}),
      );

      final data = _decodeResponse(response);

      // --------------------------------------------------------
      // OTP SUCCESS
      // --------------------------------------------------------

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // ------------------------------------------------------
        // EXTRACT TOKENS
        // ------------------------------------------------------

        final receivedAccessToken = _extractAccessToken(data);

        final receivedRefreshToken = _extractRefreshToken(data);

        // ------------------------------------------------------
        // VALIDATE ACCESS TOKEN
        // ------------------------------------------------------

        if (receivedAccessToken == null || receivedAccessToken.isEmpty) {
          isAuthenticated.value = false;

          return {
            'success': false,
            'message':
                'Login successful, but access token was not received from server.',
            'data': data,
          };
        }

        // ------------------------------------------------------
        // SAVE ACCESS TOKEN
        // ------------------------------------------------------

        await _storage.write(accessTokenKey, receivedAccessToken);

        // ------------------------------------------------------
        // SAVE REFRESH TOKEN
        // ------------------------------------------------------

        if (receivedRefreshToken != null && receivedRefreshToken.isNotEmpty) {
          await _storage.write(refreshTokenKey, receivedRefreshToken);
        }

        // ------------------------------------------------------
        // EXTRACT USER
        // ------------------------------------------------------

        final user = _extractUser(data);

        if (user != null) {
          currentUser.value = user;

          await _storage.write(userKey, user);
        }

        // ------------------------------------------------------
        // UPDATE AUTH STATE
        // ------------------------------------------------------

        isAuthenticated.value = true;

        print('========== AUTH SUCCESS ==========');
        print('ACCESS TOKEN SAVED: true');
        print('USER AVAILABLE: ${user != null}');
        print('IS AUTHENTICATED: ${isAuthenticated.value}');
        print('==================================');

        // ------------------------------------------------------
        // REGISTER FCM AFTER SUCCESSFUL LOGIN
        // ------------------------------------------------------

        // Access token is already saved.
        // Backend device-token registration can now authenticate.

        await _registerFcmTokenSafely();

        // ------------------------------------------------------
        // RETURN SUCCESS
        // ------------------------------------------------------

        return {
          'success': true,
          'message': _extractMessage(data) ?? 'OTP verified successfully',
          'data': data,
          'accessToken': receivedAccessToken,
          'refreshToken': receivedRefreshToken,
          'user': user,
        };
      }

      // --------------------------------------------------------
      // OTP FAILED
      // --------------------------------------------------------

      return {
        'success': false,
        'message': _extractMessage(data) ?? 'Invalid OTP. Please try again.',
        'data': data,
      };
    } catch (e) {
      print('VERIFY OTP ERROR: $e');

      return {'success': false, 'message': _networkErrorMessage(e)};
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // REFRESH ACCESS TOKEN
  // ============================================================

  Future<Map<String, dynamic>> refreshAccessToken() async {
    try {
      final token = accessToken;

      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Access token not available'};
      }

      final uri = Uri.parse('$baseUrl/auth/refresh-token');

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = _decodeResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final newAccessToken = _extractAccessToken(data);

        final newRefreshToken = _extractRefreshToken(data);

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await _storage.write(accessTokenKey, newAccessToken);
        }

        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await _storage.write(refreshTokenKey, newRefreshToken);
        }

        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'message': _extractMessage(data) ?? 'Session refresh failed',
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': _networkErrorMessage(e)};
    }
  }

  // ============================================================
  // GET CURRENT USER
  // GET /auth/me
  // ============================================================

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = accessToken;

      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Access token not available'};
      }

      final uri = Uri.parse('$baseUrl/auth/me');

      print('========== GET CURRENT USER ==========');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = _decodeResponse(response);

      print('STATUS: ${response.statusCode}');

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data is Map &&
          data['success'] == true) {
        final user = _extractUser(data);

        if (user == null) {
          return {
            'success': false,
            'message': 'User data missing from server response',
            'data': data,
          };
        }

        // ------------------------------------------------------
        // UPDATE CURRENT USER
        // ------------------------------------------------------

        currentUser.value = user;

        await _storage.write(userKey, user);

        // ------------------------------------------------------
        // UPDATE AUTH STATE
        // ------------------------------------------------------

        isAuthenticated.value = true;

        // ------------------------------------------------------
        // REGISTER FCM FOR RESTORED SESSION
        // ------------------------------------------------------

        // This handles users who reopen the app with an
        // existing authenticated session without logging in again.

        await _registerFcmTokenSafely();

        // ------------------------------------------------------
        // ONBOARDING STATUS
        // ------------------------------------------------------

        final onboardingCompleted =
            user['onboarding_completed'] == true ||
            user['onboarding_completed'] == 1 ||
            user['onboarding_completed']?.toString().toLowerCase() == 'true';

        print('✅ CURRENT USER FETCHED');
        print('ONBOARDING COMPLETED: $onboardingCompleted');
        print('======================================');

        return {
          'success': true,
          'data': data,
          'user': user,
          'onboarding_completed': onboardingCompleted,
        };
      }

      return {
        'success': false,
        'message': _extractMessage(data) ?? 'Unable to fetch user',
        'data': data,
      };
    } catch (e) {
      print('❌ GET CURRENT USER ERROR: $e');

      return {'success': false, 'message': _networkErrorMessage(e)};
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<bool> logout() async {
    // ----------------------------------------------------------
    // 1. UNREGISTER FCM TOKEN BEFORE CLEARING ACCESS TOKEN
    // ----------------------------------------------------------

    try {
      print('📡 Removing FCM device token...');

      await FcmNotificationService.instance.unregisterCurrentTokenFromBackend();

      print('✅ FCM logout cleanup completed');
    } catch (e) {
      // FCM failure must never block logout.
      print('⚠️ FCM logout cleanup failed: $e');
    }

    // ----------------------------------------------------------
    // 2. LOGOUT FROM BACKEND
    // ----------------------------------------------------------

    try {
      final token = accessToken;

      if (token != null && token.isNotEmpty) {
        final uri = Uri.parse('$baseUrl/auth/logout');

        await http.post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      // Continue local logout even if backend is unavailable.
      print('⚠️ Backend logout failed: $e');
    }

    // ----------------------------------------------------------
    // 3. CLEAR LOCAL SESSION
    // ----------------------------------------------------------

    await _storage.remove(accessTokenKey);
    await _storage.remove(refreshTokenKey);
    await _storage.remove(userKey);

    currentUser.value = null;
    isAuthenticated.value = false;

    print('========== LOGOUT ==========');
    print('AUTH SESSION CLEARED');
    print('============================');

    return true;
  }

  // ============================================================
  // LOAD STORED SESSION
  // ============================================================

  void loadStoredSession() {
    final token = accessToken;

    final storedUser = _storage.read(userKey);

    if (token != null && token.isNotEmpty) {
      isAuthenticated.value = true;
    } else {
      isAuthenticated.value = false;
    }

    if (storedUser is Map) {
      currentUser.value = Map<String, dynamic>.from(storedUser);
    } else {
      currentUser.value = null;
    }

    print('========== STORED SESSION ==========');
    print('TOKEN EXISTS: ${token != null}');
    print('LOGGED IN: ${isAuthenticated.value}');
    print('USER EXISTS: ${storedUser != null}');
    print('====================================');
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  dynamic _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return {'message': response.body};
    }
  }

  // ============================================================
  // EXTRACT MESSAGE
  // ============================================================

  String? _extractMessage(dynamic data) {
    if (data is! Map) {
      return null;
    }

    final message = data['message'];

    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    final error = data['error'];

    if (error is String && error.trim().isNotEmpty) {
      return error;
    }

    return null;
  }

  // ============================================================
  // EXTRACT ACCESS TOKEN
  // ============================================================

  String? _extractAccessToken(dynamic data) {
    if (data is! Map) {
      return null;
    }

    // ----------------------------------------------------------
    // TOP-LEVEL TOKEN FIELDS
    // ----------------------------------------------------------

    final directToken = _firstNonEmptyString([
      data['token'],
      data['accessToken'],
      data['access_token'],
    ]);

    if (directToken != null) {
      return directToken;
    }

    // ----------------------------------------------------------
    // NESTED DATA
    // ----------------------------------------------------------

    final nested = data['data'];

    if (nested is Map) {
      final nestedToken = _firstNonEmptyString([
        nested['token'],
        nested['accessToken'],
        nested['access_token'],
      ]);

      if (nestedToken != null) {
        return nestedToken;
      }

      // --------------------------------------------------------
      // NESTED DATA.TOKENS
      // --------------------------------------------------------

      final nestedTokens = nested['tokens'];

      if (nestedTokens is Map) {
        final token = _firstNonEmptyString([
          nestedTokens['token'],
          nestedTokens['accessToken'],
          nestedTokens['access_token'],
        ]);

        if (token != null) {
          return token;
        }
      }
    }

    // ----------------------------------------------------------
    // TOP-LEVEL TOKENS
    // ----------------------------------------------------------

    final tokens = data['tokens'];

    if (tokens is Map) {
      final token = _firstNonEmptyString([
        tokens['token'],
        tokens['accessToken'],
        tokens['access_token'],
      ]);

      if (token != null) {
        return token;
      }
    }

    return null;
  }

  // ============================================================
  // EXTRACT REFRESH TOKEN
  // ============================================================

  String? _extractRefreshToken(dynamic data) {
    if (data is! Map) {
      return null;
    }

    // ----------------------------------------------------------
    // TOP-LEVEL REFRESH TOKEN
    // ----------------------------------------------------------

    final directToken = _firstNonEmptyString([
      data['refreshToken'],
      data['refresh_token'],
    ]);

    if (directToken != null) {
      return directToken;
    }

    // ----------------------------------------------------------
    // NESTED DATA
    // ----------------------------------------------------------

    final nested = data['data'];

    if (nested is Map) {
      final nestedToken = _firstNonEmptyString([
        nested['refreshToken'],
        nested['refresh_token'],
      ]);

      if (nestedToken != null) {
        return nestedToken;
      }

      // --------------------------------------------------------
      // NESTED DATA.TOKENS
      // --------------------------------------------------------

      final nestedTokens = nested['tokens'];

      if (nestedTokens is Map) {
        final token = _firstNonEmptyString([
          nestedTokens['refreshToken'],
          nestedTokens['refresh_token'],
        ]);

        if (token != null) {
          return token;
        }
      }
    }

    // ----------------------------------------------------------
    // TOP-LEVEL TOKENS
    // ----------------------------------------------------------

    final tokens = data['tokens'];

    if (tokens is Map) {
      final token = _firstNonEmptyString([
        tokens['refreshToken'],
        tokens['refresh_token'],
      ]);

      if (token != null) {
        return token;
      }
    }

    return null;
  }

  // ============================================================
  // HELPER: FIRST NON-EMPTY STRING
  // ============================================================

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value is String) {
        final trimmed = value.trim();

        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }

    return null;
  }

  // ============================================================
  // EXTRACT USER
  // ============================================================

  Map<String, dynamic>? _extractUser(dynamic data) {
    if (data is! Map) {
      return null;
    }

    if (data['user'] is Map) {
      return Map<String, dynamic>.from(data['user']);
    }

    final nested = data['data'];

    if (nested is Map && nested['user'] is Map) {
      return Map<String, dynamic>.from(nested['user']);
    }

    return null;
  }

  // ============================================================
  // NETWORK ERROR
  // ============================================================

  String _networkErrorMessage(dynamic error) {
    final message = error.toString();

    if (message.contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    }

    if (message.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }
}
