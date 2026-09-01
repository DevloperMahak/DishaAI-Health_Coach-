import 'dart:convert';

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

    if (token == null) {
      return null;
    }

    final trimmedToken = token.trim();

    if (trimmedToken.isEmpty) {
      return null;
    }

    return trimmedToken;
  }

  String? get refreshToken {
    final token = _storage.read<String>(refreshTokenKey);

    if (token == null) {
      return null;
    }

    final trimmedToken = token.trim();

    if (trimmedToken.isEmpty) {
      return null;
    }

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
        body: jsonEncode({'mobile': mobile}),
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
        // Change it BACK to this:
        body: jsonEncode({'mobile': mobile.trim(), 'otp': otp.trim()}),
      );

      final data = _decodeResponse(response);

      // ========================================================
      // SUCCESS
      // ========================================================

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // ------------------------------------------------------
        // EXTRACT TOKENS
        // ------------------------------------------------------

        final receivedAccessToken = _extractAccessToken(data);

        final receivedRefreshToken = _extractRefreshToken(data);

        // ------------------------------------------------------
        // SAVE ACCESS TOKEN
        // ------------------------------------------------------

        if (receivedAccessToken != null && receivedAccessToken.isNotEmpty) {
          await _storage.write(accessTokenKey, receivedAccessToken);
        }

        // ------------------------------------------------------
        // SAVE REFRESH TOKEN
        // ------------------------------------------------------

        if (receivedRefreshToken != null && receivedRefreshToken.isNotEmpty) {
          await _storage.write(refreshTokenKey, receivedRefreshToken);
        }

        // ------------------------------------------------------
        // AUTH DEBUG
        // ------------------------------------------------------

        final accessToken = _extractAccessToken(data);
        final refreshToken = _extractRefreshToken(data);

        print('========== AUTH CHECK ==========');
        print('RECEIVED TOKEN EXISTS: ${accessToken != null}');
        print('RECEIVED TOKEN LENGTH: ${accessToken?.length ?? 0}');
        print('RECEIVED TOKEN: $accessToken');
        print('================================');

        if (accessToken != null && accessToken.isNotEmpty) {
          await _storage.write(accessTokenKey, accessToken);

          print('✅ ACCESS TOKEN SAVED');
          print('STORED TOKEN LENGTH: ${accessToken.length}');
        } else {
          print('❌ ACCESS TOKEN WAS NOT FOUND IN VERIFY OTP RESPONSE');
          print('VERIFY OTP RESPONSE DATA: $data');
        }
        final storedToken = _storage.read<String>(accessTokenKey);

        print('========== AUTH CHECK ==========');
        print(
          'RECEIVED TOKEN EXISTS: '
          '${receivedAccessToken != null}',
        );
        print(
          'RECEIVED TOKEN LENGTH: '
          '${receivedAccessToken?.length ?? 0}',
        );
        print(
          'STORED TOKEN EXISTS: '
          '${storedToken != null}',
        );
        print(
          'STORED TOKEN LENGTH: '
          '${storedToken?.length ?? 0}',
        );
        print(
          'LOGGED IN: '
          '${storedToken != null && storedToken.isNotEmpty}',
        );
        print('================================');

        // ------------------------------------------------------
        // TOKEN NOT RECEIVED
        // ------------------------------------------------------

        if (receivedAccessToken == null || receivedAccessToken.isEmpty) {
          print(
            '❌ ACCESS TOKEN WAS NOT FOUND '
            'IN VERIFY OTP RESPONSE',
          );

          print('VERIFY OTP RESPONSE DATA: $data');

          isAuthenticated.value = false;

          return {
            'success': false,
            'message':
                'Login successful, but access token was not received from server.',
            'data': data,
          };
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

        // ------------------------------------------------------
        // FINAL AUTH CHECK
        // ------------------------------------------------------

        print('========== FINAL AUTH STATE ==========');
        print(
          'ACCESS TOKEN AVAILABLE: '
          '${accessToken != null}',
        );
        print(
          'ACCESS TOKEN LENGTH: '
          '${accessToken?.length ?? 0}',
        );
        print(
          'IS LOGGED IN: '
          '$isLoggedIn',
        );
        print(
          'IS AUTHENTICATED: '
          '${isAuthenticated.value}',
        );
        print('======================================');

        return {
          'success': true,
          'message': _extractMessage(data) ?? 'OTP verified successfully',
          'data': data,
          'accessToken': receivedAccessToken,
          'refreshToken': receivedRefreshToken,
          'user': user,
        };
      }

      // ========================================================
      // OTP FAILED
      // ========================================================

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

      // IMPORTANT:
      // token is nullable, therefore we check it first.

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
  // ============================================================

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = accessToken;

      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Access token not available'};
      }

      final uri = Uri.parse('$baseUrl/auth/me');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = _decodeResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final user = _extractUser(data);

        if (user != null) {
          currentUser.value = user;

          await _storage.write(userKey, user);
        }

        return {'success': true, 'data': data, 'user': user};
      }

      return {
        'success': false,
        'message': _extractMessage(data) ?? 'Unable to fetch user',
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': _networkErrorMessage(e)};
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<bool> logout() async {
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
    } catch (_) {
      // Even if server logout fails,
      // clear local session.
    }

    await _storage.remove(accessTokenKey);
    await _storage.remove(refreshTokenKey);
    await _storage.remove(userKey);

    currentUser.value = null;
    isAuthenticated.value = false;

    print('========== LOGOUT ==========');
    print('AUTH SESSION CLEARED');
    print('================================');

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
    }

    print('========== STORED SESSION ==========');
    print(
      'TOKEN EXISTS: '
      '${token != null}',
    );
    print(
      'TOKEN LENGTH: '
      '${token?.length ?? 0}',
    );
    print(
      'LOGGED IN: '
      '${token != null && token.isNotEmpty}',
    );
    print(
      'USER EXISTS: '
      '${storedUser != null}',
    );
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
  // MESSAGE
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
  // ACCESS TOKEN
  // ============================================================

  String? _extractAccessToken(dynamic data) {
    if (data is! Map) {
      return null;
    }

    // ============================================================
    // DIRECT TOKEN
    // ============================================================

    if (data['token'] is String) {
      final token = data['token'].toString().trim();

      if (token.isNotEmpty) {
        return token;
      }
    }

    // ============================================================
    // DIRECT ACCESS TOKEN
    // ============================================================

    if (data['accessToken'] is String) {
      final token = data['accessToken'].toString().trim();

      if (token.isNotEmpty) {
        return token;
      }
    }

    if (data['access_token'] is String) {
      final token = data['access_token'].toString().trim();

      if (token.isNotEmpty) {
        return token;
      }
    }

    // ============================================================
    // NESTED DATA
    // ============================================================

    final nested = data['data'];

    if (nested is Map) {
      // Backend format:
      // data: {
      //   token: "..."
      // }

      if (nested['token'] is String) {
        final token = nested['token'].toString().trim();

        if (token.isNotEmpty) {
          return token;
        }
      }

      // data.accessToken
      if (nested['accessToken'] is String) {
        final token = nested['accessToken'].toString().trim();

        if (token.isNotEmpty) {
          return token;
        }
      }

      // data.access_token
      if (nested['access_token'] is String) {
        final token = nested['access_token'].toString().trim();

        if (token.isNotEmpty) {
          return token;
        }
      }

      // ==========================================================
      // NESTED TOKENS
      // ==========================================================

      final tokens = nested['tokens'];

      if (tokens is Map) {
        if (tokens['token'] is String) {
          final token = tokens['token'].toString().trim();

          if (token.isNotEmpty) {
            return token;
          }
        }

        if (tokens['accessToken'] is String) {
          final token = tokens['accessToken'].toString().trim();

          if (token.isNotEmpty) {
            return token;
          }
        }

        if (tokens['access_token'] is String) {
          final token = tokens['access_token'].toString().trim();

          if (token.isNotEmpty) {
            return token;
          }
        }
      }
    }

    // ============================================================
    // TOP-LEVEL TOKENS
    // ============================================================

    final tokens = data['tokens'];

    if (tokens is Map) {
      if (tokens['token'] is String) {
        final token = tokens['token'].toString().trim();

        if (token.isNotEmpty) {
          return token;
        }
      }

      if (tokens['accessToken'] is String) {
        final token = tokens['accessToken'].toString().trim();

        if (token.isNotEmpty) {
          return token;
        }
      }

      if (tokens['access_token'] is String) {
        final token = tokens['access_token'].toString().trim();

        if (token.isNotEmpty) {
          return token;
        }
      }
    }

    return null;
  }

  // ============================================================
  // REFRESH TOKEN
  // ============================================================

  String? _extractRefreshToken(dynamic data) {
    if (data is! Map) {
      return null;
    }

    // ----------------------------------------------------------
    // DIRECT
    // ----------------------------------------------------------

    if (data['refreshToken'] is String) {
      final token = data['refreshToken'].toString().trim();

      if (token.isNotEmpty) {
        return token;
      }
    }

    if (data['refresh_token'] is String) {
      final token = data['refresh_token'].toString().trim();

      if (token.isNotEmpty) {
        return token;
      }
    }

    // ----------------------------------------------------------
    // data
    // ----------------------------------------------------------

    final nested = data['data'];

    if (nested is Map) {
      if (nested['refreshToken'] is String) {
        final token = nested['refreshToken'].toString().trim();

        if (token.isNotEmpty) {
          return token;
        }
      }

      if (nested['refresh_token'] is String) {
        final token = nested['refresh_token'].toString().trim();

        if (token.isNotEmpty) {
          return token;
        }
      }

      // --------------------------------------------------------
      // data.tokens
      // --------------------------------------------------------

      final nestedTokens = nested['tokens'];

      if (nestedTokens is Map) {
        if (nestedTokens['refreshToken'] is String) {
          final token = nestedTokens['refreshToken'].toString().trim();

          if (token.isNotEmpty) {
            return token;
          }
        }

        if (nestedTokens['refresh_token'] is String) {
          final token = nestedTokens['refresh_token'].toString().trim();

          if (token.isNotEmpty) {
            return token;
          }
        }
      }
    }

    // ----------------------------------------------------------
    // tokens
    // ----------------------------------------------------------

    final tokens = data['tokens'];

    if (tokens is Map) {
      if (tokens['refreshToken'] is String) {
        final token = tokens['refreshToken'].toString().trim();

        if (token.isNotEmpty) {
          return token;
        }
      }

      if (tokens['refresh_token'] is String) {
        final token = tokens['refresh_token'].toString().trim();

        if (token.isNotEmpty) {
          return token;
        }
      }
    }

    return null;
  }

  // ============================================================
  // USER
  // ============================================================

  Map<String, dynamic>? _extractUser(dynamic data) {
    if (data is! Map) {
      return null;
    }

    if (data['user'] is Map) {
      return Map<String, dynamic>.from(data['user']);
    }

    final nested = data['data'];

    if (nested is Map) {
      if (nested['user'] is Map) {
        return Map<String, dynamic>.from(nested['user']);
      }
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
