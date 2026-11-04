import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/reminder_settings_model.dart';
import '../../data/services/reminder_service.dart';

class ReminderSettingsController extends GetxController {
  ReminderSettingsController({required ReminderService service})
    : _service = service;

  final ReminderService _service;

  final Rxn<ReminderSettingsModel> settings = Rxn<ReminderSettingsModel>();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSettings();
  }

  // ============================================================
  // FETCH SETTINGS
  // ============================================================

  Future<void> fetchSettings() async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _service.getSettings();

      settings.value = result;
      errorMessage.value = '';
    } catch (e) {
      final message = _cleanError(e);

      errorMessage.value = message;

      _showError(message);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // UPDATE SETTINGS
  // ============================================================

  Future<bool> updateReminderSettings({
    bool? remindersEnabled,
    bool? aiRemindersEnabled,
    String? frequency,
    int? defaultSnoozeMinutes,
    String? sound,
    bool? vibration,
    bool? quietHoursEnabled,
    String? quietStart,
    String? quietEnd,
    List<String>? channels,
    Map<String, bool>? categories,
  }) async {
    if (isSaving.value) {
      return false;
    }

    isSaving.value = true;

    try {
      final changes = <String, dynamic>{};

      if (remindersEnabled != null) {
        changes['reminders_enabled'] = remindersEnabled;
      }

      if (aiRemindersEnabled != null) {
        changes['ai_reminders_enabled'] = aiRemindersEnabled;
      }

      if (frequency != null) {
        changes['frequency'] = frequency;
      }

      if (defaultSnoozeMinutes != null) {
        changes['default_snooze_minutes'] = defaultSnoozeMinutes;
      }

      if (sound != null) {
        changes['sound'] = sound;
      }

      if (vibration != null) {
        changes['vibration'] = vibration;
      }

      if (quietHoursEnabled != null) {
        changes['quiet_hours_enabled'] = quietHoursEnabled;
      }

      if (quietStart != null) {
        changes['quiet_start'] = quietStart;
      }

      if (quietEnd != null) {
        changes['quiet_end'] = quietEnd;
      }

      if (channels != null) {
        changes['channels'] = channels;
      }

      if (categories != null) {
        changes['categories'] = categories;
      }

      if (changes.isEmpty) {
        return true;
      }

      final updated = await _service.updateSettings(changes);

      settings.value = updated;
      errorMessage.value = '';

      return true;
    } catch (e) {
      final message = _cleanError(e);

      _showError(message);

      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================
  // MASTER
  // ============================================================

  Future<void> toggleMaster(bool value) async {
    final current = settings.value;

    if (current == null) return;

    settings.value = current.copyWith(remindersEnabled: value);

    final success = await updateReminderSettings(remindersEnabled: value);

    if (!success) {
      settings.value = current;
    }
  }

  // ============================================================
  // AI
  // ============================================================

  Future<void> toggleAi(bool value) async {
    final current = settings.value;

    if (current == null) return;

    settings.value = current.copyWith(aiRemindersEnabled: value);

    final success = await updateReminderSettings(aiRemindersEnabled: value);

    if (!success) {
      settings.value = current;
    }
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  Future<void> toggleCategory(String category, bool value) async {
    final current = settings.value;

    if (current == null) return;

    final categories = Map<String, bool>.from(current.categories);

    categories[category] = value;

    settings.value = current.copyWith(categories: categories);

    final success = await updateReminderSettings(categories: categories);

    if (!success) {
      settings.value = current;
    }
  }

  // ============================================================
  // PUSH
  // ============================================================

  Future<void> togglePushChannel(bool value) async {
    final current = settings.value;

    if (current == null) return;

    final channels = List<String>.from(current.channels);

    if (value) {
      if (!channels.contains('push')) {
        channels.add('push');
      }
    } else {
      channels.remove('push');
    }

    settings.value = current.copyWith(channels: channels);

    final success = await updateReminderSettings(channels: channels);

    if (!success) {
      settings.value = current;
    }
  }

  // ============================================================
  // IN-APP
  // ============================================================

  Future<void> toggleInAppChannel(bool value) async {
    final current = settings.value;

    if (current == null) return;

    final channels = List<String>.from(current.channels);

    if (value) {
      if (!channels.contains('in_app')) {
        channels.add('in_app');
      }
    } else {
      channels.remove('in_app');
    }

    settings.value = current.copyWith(channels: channels);

    final success = await updateReminderSettings(channels: channels);

    if (!success) {
      settings.value = current;
    }
  }

  // ============================================================
  // SOUND
  // ============================================================

  Future<void> changeSound(String value) async {
    final current = settings.value;

    if (current == null) return;

    settings.value = current.copyWith(sound: value);

    final success = await updateReminderSettings(sound: value);

    if (!success) {
      settings.value = current;
    }
  }

  // ============================================================
  // VIBRATION
  // ============================================================

  Future<void> toggleVibration(bool value) async {
    final current = settings.value;

    if (current == null) return;

    settings.value = current.copyWith(vibration: value);

    final success = await updateReminderSettings(vibration: value);

    if (!success) {
      settings.value = current;
    }
  }

  // ============================================================
  // QUIET HOURS
  // ============================================================

  Future<void> toggleQuietHours(bool value) async {
    final current = settings.value;

    if (current == null) return;

    settings.value = current.copyWith(quietHoursEnabled: value);

    final success = await updateReminderSettings(quietHoursEnabled: value);

    if (!success) {
      settings.value = current;
    }
  }

  Future<void> changeQuietHours({String? start, String? end}) async {
    final current = settings.value;

    if (current == null) return;

    settings.value = current.copyWith(
      quietStart: start ?? current.quietStart,
      quietEnd: end ?? current.quietEnd,
    );

    final success = await updateReminderSettings(
      quietStart: start,
      quietEnd: end,
    );

    if (!success) {
      settings.value = current;
    }
  }

  // ============================================================
  // SNOOZE
  // ============================================================

  Future<void> changeDefaultSnooze(int minutes) async {
    final current = settings.value;

    if (current == null) return;

    settings.value = current.copyWith(defaultSnoozeMinutes: minutes);

    final success = await updateReminderSettings(defaultSnoozeMinutes: minutes);

    if (!success) {
      settings.value = current;
    }
  }

  // ============================================================
  // FREQUENCY
  // ============================================================

  Future<void> changeFrequency(String value) async {
    final current = settings.value;

    if (current == null) return;

    settings.value = current.copyWith(frequency: value);

    final success = await updateReminderSettings(frequency: value);

    if (!success) {
      settings.value = current;
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshSettings() async {
    await fetchSettings();
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  void _showError(String message) {
    Get.snackbar(
      'Reminder Settings',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
    );
  }
}
