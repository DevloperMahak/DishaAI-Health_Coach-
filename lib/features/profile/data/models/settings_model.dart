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

    final Map<String, dynamic> data =
        json.containsKey('data') && json['data'] != null ? json['data'] : json;

    return SettingsModel(
      preferredLanguage: data['preferred_language'] ?? 'en',
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
      'hydration_reminder_enabled': pushNotifications,
      'microphone_access': microphoneAccess,
      'microphone_enabled': microphoneAccess,
      'unit_system': unitSystem,
    };
  }
}
