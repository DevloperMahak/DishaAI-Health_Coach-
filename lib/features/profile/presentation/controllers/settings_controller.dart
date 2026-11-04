import 'dart:ui';
import 'package:disha_ai/features/profile/data/models/settings_model.dart';
import 'package:disha_ai/features/profile/data/services/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsController extends GetxController {
  final SettingsService _service = SettingsService();

  final Rxn<SettingsModel> settings = Rxn<SettingsModel>();
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSettings();
  }

  // Fetch App Settings
  Future<void> fetchSettings() async {
    debugPrint('▶️ [SettingsController] Fetching settings from API...');
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _service.getSettings();
      settings.value = result;
      debugPrint(
        '✅ [SettingsController] Fetch success. Lang: ${result.preferredLanguage}',
      );

      // Instantly apply the user's preferred language to the UI on load
      _applyLocalization(result.preferredLanguage);
    } catch (e) {
      debugPrint('❌ [SettingsController] Fetch failed: $e');
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  // Update App Settings
  Future<bool> updateSettings({
    String? preferredLanguage,
    bool? pushNotifications,
    bool? microphoneAccess,
    String? unitSystem,
  }) async {
    debugPrint('▶️ [SettingsController] Updating settings triggered!');

    final current = settings.value;
    final lang = preferredLanguage ?? current?.preferredLanguage ?? 'en';
    final push = pushNotifications ?? current?.pushNotifications ?? true;
    final mic = microphoneAccess ?? current?.microphoneAccess ?? false;
    final unit = unitSystem ?? current?.unitSystem ?? 'metric';

    debugPrint('  ↳ Attempting to set language to: $lang');

    // 💡 CRITICAL FIX: Change language instantly BEFORE the API call!
    // This guarantees the UI translates even if your backend API crashes.
    _applyLocalization(lang);

    try {
      isUpdating.value = true;
      errorMessage.value = '';

      debugPrint(
        '⏳ [SettingsController] Calling SettingsService.updateSettings...',
      );
      final updated = await _service.updateSettings(
        preferredLanguage: lang,
        pushNotifications: push,
        microphoneAccess: mic,
        unitSystem: unit,
      );

      debugPrint('✅ [SettingsController] API successfully updated settings!');
      settings.value = updated;
      return true;
    } catch (e) {
      debugPrint('🚨 [SettingsController] Catch Block Hit! API Update Failed!');
      debugPrint('  ↳ Error Details: $e');
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // ==========================================
  // DYNAMIC LOCALIZATION HELPER
  // ==========================================
  void _applyLocalization(String langCode) {
    debugPrint('🌍 [Localization] Changing App Language to: $langCode');

    // Save to local storage for the next app launch
    final box = GetStorage();
    box.write('preferred_language', langCode);

    Locale newLocale;
    switch (langCode) {
      case 'hi':
        newLocale = const Locale('hi', 'IN');
        break;
      case 'es':
        newLocale = const Locale('es', 'ES');
        break;
      case 'en':
      default:
        newLocale = const Locale('en', 'US');
    }

    // GetX handles the global UI rebuild automatically
    Get.updateLocale(newLocale);
    debugPrint('🌍 [Localization] Get.updateLocale fired with $newLocale');
  }

  // Call this from your MicrophoneAccessScreen's "Allow" button
  Future<bool> requestAndSaveMicrophoneAccess() async {
    final status = await Permission.microphone.request();
    final isGranted = status.isGranted;

    if (settings.value != null) {
      await updateSettings(
        preferredLanguage: settings.value!.preferredLanguage,
        pushNotifications: settings.value!.pushNotifications,
        microphoneAccess: isGranted,
        unitSystem: settings.value!.unitSystem,
      );
    }
    return isGranted;
  }
}
