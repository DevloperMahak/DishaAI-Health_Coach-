import 'package:flutter/foundation.dart';

class SettingsModel {
  final String preferredLanguage;
  final bool pushNotifications;
  final bool microphoneAccess;
  final String unitSystem;

  SettingsModel({
    required this.preferredLanguage,
    required this.pushNotifications,
    required this.microphoneAccess,
    required this.unitSystem,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    debugPrint('⚙️ [SettingsModel] Parsing JSON: $json');

    // 💡 FIX: Safely extract the 'data' object if it exists
    final Map<String, dynamic> data =
        json.containsKey('data') && json['data'] != null ? json['data'] : json;

    return SettingsModel(
      // Now we pull from 'data' instead of 'json'
      preferredLanguage: data['preferred_language'] ?? 'en',

      // Also ensuring we use the exact keys your backend returns
      pushNotifications:
          data['hydration_reminder_enabled'] ??
          data['push_notifications'] ??
          true,
      microphoneAccess:
          data['microphone_enabled'] ?? data['microphone_access'] ?? false,
      unitSystem: data['unit_system'] ?? 'metric',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferred_language': preferredLanguage,
      'push_notifications': pushNotifications,
      'microphone_access': microphoneAccess,
      'unit_system': unitSystem,
    };
  }
}
