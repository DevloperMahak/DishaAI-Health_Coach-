import 'package:disha_ai/features/reminders/data/services/local_alarm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:disha_ai/app/bindings/app_binding.dart';
import 'package:disha_ai/app/routes/app_pages.dart';
import 'package:disha_ai/core/app_translations.dart';
import 'package:disha_ai/core/notifications/fcm_notification_service.dart';
import 'package:disha_ai/core/notifications/local_notification_service.dart';
import 'package:disha_ai/firebase_options.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // FIREBASE INITIALIZATION
  // ============================================================

  // ============================================================
  // FIREBASE INITIALIZATION
  // ============================================================

  try {
    debugPrint('[FIREBASE] Starting initialization...');

    if (Firebase.apps.isEmpty) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android: Use the native configuration from
        // android/app/google-services.json
        await Firebase.initializeApp();
      } else {
        // Other platforms: Use FlutterFire configuration.
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    }

    final firebaseApp = Firebase.app();

    debugPrint('[FIREBASE] INITIALIZED SUCCESSFULLY');
    debugPrint('[FIREBASE] App name: ${firebaseApp.name}');
    debugPrint('[FIREBASE] Project ID: ${firebaseApp.options.projectId}');
    debugPrint('[FIREBASE] App ID: ${firebaseApp.options.appId}');
  } catch (e, stackTrace) {
    debugPrint('[FIREBASE] INITIALIZATION FAILED: $e');
    debugPrintStack(stackTrace: stackTrace);
    rethrow;
  }

  // ============================================================
  // GET STORAGE
  // ============================================================

  await GetStorage.init();

  // ============================================================
  // LOCAL ALARM SERVICE
  // ============================================================

  await LocalAlarmService.instance.initialize();

  // ============================================================
  // EXISTING LOCAL NOTIFICATION SERVICE
  // ============================================================

  await LocalNotificationService.instance.initialize();

  // ============================================================
  // FIREBASE CLOUD MESSAGING
  // ============================================================

  await FcmNotificationService.instance.initialize();

  // ============================================================
  // LANGUAGE
  // ============================================================

  final box = GetStorage();

  final String savedLang = box.read('preferred_language') ?? 'en';

  Locale initialLocale;

  switch (savedLang) {
    case 'hi':
      initialLocale = const Locale('hi', 'IN');
      break;

    default:
      initialLocale = const Locale('en', 'US');
  }

  // ============================================================
  // START APP
  // ============================================================

  runApp(DishaAIApp(initialLocale: initialLocale));
}

class DishaAIApp extends StatelessWidget {
  final Locale initialLocale;

  const DishaAIApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'RheaAI',

      initialBinding: AppBinding(),

      translations: AppTranslations(),

      locale: initialLocale,

      fallbackLocale: AppTranslations.fallbackLocale,

      theme: ThemeData.dark(),

      debugShowCheckedModeBanner: false,

      initialRoute: AppPages.initial,

      getPages: AppPages.pages,
    );
  }
}
