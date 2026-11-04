import 'dart:async';
import 'dart:io';

import 'package:disha_ai/app/routes/app_routes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../features/notifications/data/services/notification_service.dart';
import '../../features/notifications/presentation/controllers/notification_controller.dart';
import 'local_notification_service.dart';

/// Handles Firebase Cloud Messaging (FCM) on the Flutter side.
class FcmNotificationService {
  FcmNotificationService._();

  static final FcmNotificationService instance = FcmNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final NotificationService _notificationService = NotificationService();

  final GetStorage _storage = GetStorage();

  static const String _fcmTokenKey = 'fcm_device_token';

  bool _initialized = false;
  bool _initializing = false;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _notificationTapSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  // ============================================================
  // DEBUG LOGGER
  // ============================================================

  void _log(String message) {
    debugPrint('[RHEAAI FCM] $message');
  }

  // ============================================================
  // INITIALIZE FCM
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      _log('FCM already initialized. Skipping duplicate setup.');
      return;
    }

    if (_initializing) {
      _log('FCM initialization already in progress.');
      return;
    }

    _initializing = true;

    _log('==========================================');
    _log('FCM INITIALIZATION STARTED');

    try {
      // --------------------------------------------------------
      // 1. REQUEST NOTIFICATION PERMISSION
      // --------------------------------------------------------

      _log('Requesting notification permission...');

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      _log('Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _log('WARNING: Notification permission denied.');
      }

      // --------------------------------------------------------
      // 2. REGISTER FOREGROUND MESSAGE LISTENER EARLY
      // --------------------------------------------------------

      // Register before token/API requests so incoming messages
      // are not missed while waiting for backend registration.

      if (_foregroundSubscription == null) {
        _log('Registering foreground message listener...');

        _foregroundSubscription = FirebaseMessaging.onMessage.listen(
          _handleForegroundMessage,
          onError: (error) {
            _log('FOREGROUND MESSAGE LISTENER ERROR: $error');
          },
        );
      }

      // --------------------------------------------------------
      // 3. REGISTER NOTIFICATION TAP LISTENER
      // --------------------------------------------------------

      if (_notificationTapSubscription == null) {
        _log('Registering notification tap listener...');

        _notificationTapSubscription = FirebaseMessaging.onMessageOpenedApp
            .listen(
              _handleNotificationTap,
              onError: (error) {
                _log('NOTIFICATION TAP LISTENER ERROR: $error');
              },
            );
      }

      // --------------------------------------------------------
      // 4. LISTEN FOR FCM TOKEN REFRESH
      // --------------------------------------------------------

      if (_tokenRefreshSubscription == null) {
        _log('Registering FCM token refresh listener...');

        _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
          (newToken) async {
            _log('FCM TOKEN REFRESH EVENT RECEIVED');

            if (newToken.isEmpty) {
              _log('ERROR: Refreshed FCM token is empty.');
              return;
            }

            _log('New FCM token received.');
            _log('Token length: ${newToken.length}');

            await _saveTokenLocally(newToken);

            final registered = await _registerTokenWithBackend(newToken);

            if (registered) {
              _log('Refreshed token registered successfully.');
            } else {
              _log('WARNING: Refreshed token registration failed.');
            }
          },
          onError: (error) {
            _log('TOKEN REFRESH LISTENER ERROR: $error');
          },
        );
      }

      // --------------------------------------------------------
      // 5. GET CURRENT TOKEN
      // --------------------------------------------------------

      // 5. GET CURRENT TOKEN
      // Generate and cache the token, but register with Laravel
      // only after the user has authenticated.

      _log('Getting current Firebase device token...');

      await _getAndRegisterCurrentToken(registerWithBackend: false);

      // --------------------------------------------------------
      // 6. CHECK TERMINATED STATE NOTIFICATION
      // --------------------------------------------------------

      _log('Checking for initial notification message...');

      final initialMessage = await _messaging.getInitialMessage();

      if (initialMessage != null) {
        _log('App opened from terminated state by notification.');

        _handleNotificationTap(initialMessage);
      } else {
        _log('No initial notification message.');
      }

      // --------------------------------------------------------
      // INITIALIZATION COMPLETE
      // --------------------------------------------------------

      _initialized = true;

      _log('FCM INITIALIZATION COMPLETED');
      _log('Foreground listener: ACTIVE');
      _log('Token refresh listener: ACTIVE');
      _log('Notification tap listener: ACTIVE');
      _log('==========================================');
    } catch (e, stackTrace) {
      _log('FCM INITIALIZATION FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _initializing = false;
    }
  }

  // ============================================================
  // GET CURRENT FCM TOKEN
  // ============================================================
  Future<void> _getAndRegisterCurrentToken({
    bool registerWithBackend = true,
  }) async {
    try {
      _log('Requesting FCM registration token from Firebase...');

      final token = await _messaging.getToken();

      if (token == null || token.isEmpty) {
        _log('ERROR: Firebase returned null/empty FCM token.');
        return;
      }

      // Never print the actual token.
      _log('FCM TOKEN GENERATED SUCCESSFULLY');
      _log('Token length: ${token.length}');

      await _saveTokenLocally(token);

      if (registerWithBackend) {
        final registered = await _registerTokenWithBackend(token);

        _log(
          registered
              ? 'Initial FCM backend registration successful.'
              : 'Initial FCM backend registration unsuccessful.',
        );
      } else {
        _log('FCM token cached. Backend registration deferred until login.');
      }
    } catch (e, stackTrace) {
      _log('FAILED TO GET FCM TOKEN: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // SAVE TOKEN LOCALLY
  // ============================================================

  Future<void> _saveTokenLocally(String token) async {
    try {
      await _storage.write(_fcmTokenKey, token);
      _log('FCM token saved in local storage.');
    } catch (e) {
      _log('FAILED TO SAVE FCM TOKEN LOCALLY: $e');
    }
  }

  Future<void> logCurrentUserAndFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();

      final user = GetStorage().read('current_user');

      final userId = user is Map
          ? user['id']?.toString() ?? user['_id']?.toString()
          : null;

      final tokenLast15 = (token != null && token.length >= 15)
          ? token.substring(token.length - 15)
          : token;

      debugPrint('========== RHEAAI FCM DEBUG ==========');
      debugPrint('[RHEAAI FCM] Logged-in User ID: ${userId ?? "NOT FOUND"}');
      debugPrint('[RHEAAI FCM] Token available: ${token != null}');
      debugPrint(
        '[RHEAAI FCM] Token last 15 characters: ${tokenLast15 ?? "NOT FOUND"}',
      );
      debugPrint('======================================');
    } catch (e) {
      debugPrint('[RHEAAI FCM] DEBUG ERROR: $e');
    }
  }

  // ============================================================
  // GET CACHED TOKEN
  // ============================================================

  String? getCachedToken() {
    try {
      final token = _storage.read<String>(_fcmTokenKey);

      if (token == null || token.isEmpty) {
        _log('No cached FCM token found.');
        return null;
      }

      _log('Cached FCM token found.');
      _log('Cached token length: ${token.length}');

      return token;
    } catch (e) {
      _log('FAILED TO READ CACHED FCM TOKEN: $e');
      return null;
    }
  }

  // ============================================================
  // REGISTER TOKEN WITH BACKEND
  // ============================================================

  Future<bool> _registerTokenWithBackend(String token) async {
    try {
      if (token.trim().isEmpty) {
        _log('ERROR: Cannot register empty FCM token.');
        return false;
      }

      final platform = Platform.isAndroid ? 'android' : 'ios';

      _log('------------------------------------------');
      _log('BACKEND FCM REGISTRATION STARTED');
      _log('Platform: $platform');
      _log('Token available: true');
      _log('Token length: ${token.length}');
      _log('Calling Laravel device-token API...');

      final success = await _notificationService.registerDeviceToken(
        token: token,
        platform: platform,
      );

      if (success) {
        _log('BACKEND FCM REGISTRATION SUCCESS');
        _log('Device is connected to Laravel.');
      } else {
        _log('BACKEND FCM REGISTRATION FAILED');
      }

      _log('------------------------------------------');

      return success;
    } catch (e, stackTrace) {
      _log('BACKEND FCM REGISTRATION ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ============================================================
  // PUBLIC TOKEN REGISTRATION
  // CALL AFTER SUCCESSFUL LOGIN
  // ============================================================

  Future<bool> registerCurrentTokenWithBackend() async {
    try {
      _log('LOGIN FCM REGISTRATION STARTED');

      String? token = getCachedToken();

      if (token == null || token.isEmpty) {
        _log('Cached token unavailable. Requesting Firebase token...');

        token = await _messaging.getToken();

        if (token != null && token.isNotEmpty) {
          await _saveTokenLocally(token);
        }
      }

      if (token == null || token.isEmpty) {
        _log('ERROR: No FCM token available for registration.');
        return false;
      }

      final success = await _registerTokenWithBackend(token);

      if (success) {
        _log('LOGIN FCM REGISTRATION SUCCESS');
      } else {
        _log('LOGIN FCM REGISTRATION FAILED');
      }

      return success;
    } catch (e, stackTrace) {
      _log('CURRENT TOKEN REGISTRATION ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ============================================================
  // REMOVE DEVICE TOKEN ON LOGOUT
  // ============================================================

  Future<bool> unregisterCurrentTokenFromBackend() async {
    try {
      _log('FCM LOGOUT CLEANUP STARTED');

      final token = getCachedToken();

      if (token == null || token.isEmpty) {
        _log('No cached FCM token to remove.');
        return true;
      }

      _log('Removing device token from Laravel...');

      final success = await _notificationService.removeDeviceToken(
        token: token,
      );

      if (!success) {
        _log('FCM DEVICE UNREGISTER FAILED.');
        return false;
      }

      await _storage.remove(_fcmTokenKey);

      _log('FCM DEVICE UNREGISTERED SUCCESSFULLY');
      _log('Local FCM token removed.');

      return true;
    } catch (e, stackTrace) {
      _log('FCM LOGOUT CLEANUP FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ============================================================
  // GET OR CREATE NOTIFICATION CONTROLLER
  // ============================================================

  NotificationController? _getNotificationController() {
    try {
      if (Get.isRegistered<NotificationController>()) {
        return Get.find<NotificationController>();
      }

      // Create the controller when an incoming FCM message
      // arrives before the notification screen has been opened.
      return Get.put(NotificationController());
    } catch (e) {
      _log('Could not obtain NotificationController: $e');
      return null;
    }
  }

  // ============================================================
  // FOREGROUND FCM MESSAGE
  // ============================================================

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _log('==========================================');
    _log('FOREGROUND FCM MESSAGE RECEIVED');

    _log('Message ID: ${message.messageId}');
    _log('Title: ${message.notification?.title}');
    _log('Body: ${message.notification?.body}');
    _log('Data: ${message.data}');

    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'RheaAI Notification';

    final body =
        message.notification?.body ??
        message.data['body']?.toString() ??
        'You have a new notification.';

    final payload = message.data['notification_id']?.toString();

    try {
      // --------------------------------------------------------
      // STEP 1: SHOW FLOATING LOCAL NOTIFICATION
      // --------------------------------------------------------

      _log('Preparing foreground local notification...');

      final controller = _getNotificationController();

      if (controller != null) {
        await controller.showIncomingNotification(
          title: title,
          body: body,
          payload: payload,
        );
      } else {
        await LocalNotificationService.instance.showFcmNotification(
          title: title,
          body: body,
          payload: payload,
        );
      }

      _log('FOREGROUND LOCAL NOTIFICATION DISPLAY REQUESTED');

      // --------------------------------------------------------
      // STEP 2: REFRESH IN-APP NOTIFICATION INBOX
      // --------------------------------------------------------

      if (controller != null) {
        _log('Refreshing notification inbox from backend...');

        await controller.refreshNotifications();

        _log('NOTIFICATION INBOX REFRESHED SUCCESSFULLY');
      } else {
        _log('Notification inbox refresh skipped.');
      }
    } catch (e, stackTrace) {
      _log('FOREGROUND NOTIFICATION ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    _log('==========================================');
  }

  // ============================================================
  // NOTIFICATION TAP NAVIGATION
  // ============================================================

  void _handleNotificationTap(RemoteMessage message) {
    _log('==========================================');
    _log('FCM NOTIFICATION TAPPED');

    _log('Message ID: ${message.messageId}');
    _log('Notification data: ${message.data}');

    final data = message.data;

    final action = data['action']?.toString();
    final screen = data['screen']?.toString();

    final reminderId = data['reminder_id']?.toString();

    if (reminderId != null && reminderId.isNotEmpty) {
      _log('Reminder ID: $reminderId');
    }

    _log('Action: $action');
    _log('Screen: $screen');

    String route;

    // ----------------------------------------------------------
    // ACTION MAPPING
    // ----------------------------------------------------------

    switch (action) {
      case 'open_notifications':
        route = AppRoutes.notifications;
        break;

      case 'open_water':
        route = AppRoutes.waterTracker;
        break;

      case 'open_checkin':
        route = AppRoutes.healthDashboard;
        break;

      default:
        // ------------------------------------------------------
        // SCREEN FALLBACK
        // ------------------------------------------------------

        switch (screen) {
          case 'notifications':
            route = AppRoutes.notifications;
            break;

          case 'water':
            route = AppRoutes.waterTracker;
            break;

          case 'health':
            route = AppRoutes.healthDashboard;
            break;

          default:
            route = AppRoutes.notifications;
        }
    }

    _log('Resolved navigation route: $route');

    // ----------------------------------------------------------
    // NAVIGATION AFTER APP FRAME
    // ----------------------------------------------------------

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (Get.currentRoute != route) {
          _log('Navigating to $route');

          Get.toNamed(route);
        } else {
          _log('Already on requested route: $route');
        }
      } catch (e) {
        _log('NOTIFICATION NAVIGATION FAILED: $e');
      }
    });

    _log('==========================================');
  }
}
