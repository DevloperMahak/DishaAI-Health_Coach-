import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/reminder_model.dart';
import '../../data/services/reminder_service.dart';
import '../../../../core/notifications/local_notification_service.dart';

class ReminderController extends GetxController {
  ReminderController({required ReminderService service}) : _service = service;

  final ReminderService _service;

  final RxList<ReminderModel> reminders = <ReminderModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  final RxString selectedModule = ''.obs;
  final RxString selectedStatus = 'active'.obs;

  final LocalNotificationService _localNotifications =
      LocalNotificationService.instance;

  @override
  void onInit() {
    super.onInit();
    fetchReminders();
  }

  // ============================================================
  // FETCH REMINDERS
  // ============================================================

  Future<void> fetchReminders({String? module, String? status}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _service.getReminders(
        module: module ?? _nullableValue(selectedModule.value),
        status: status ?? selectedStatus.value,
      );

      reminders.assignAll(result);

      // ----------------------------------------------------------
      // Restore/sync local notifications.
      //
      // This is important because Android can still have scheduled
      // notifications, but when the app starts we also want the
      // current backend reminder state to be reflected locally.
      // ----------------------------------------------------------

      await _syncLocalNotifications(result);
    } catch (e) {
      errorMessage.value = _cleanError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // CREATE REMINDER
  // ============================================================

  Future<bool> createReminder({
    required String module,
    required String type,
    String? title,
    String? message,
    String priority = 'normal',
    String? time,
    List<String>? days,
    int? intervalMinutes,
    String? goalId,
    String? timezone,
  }) async {
    isSaving.value = true;

    try {
      final reminder = await _service.createReminder(
        module: module,
        type: type,
        title: title,
        message: message,
        priority: priority,
        time: time,
        days: days,
        intervalMinutes: intervalMinutes,
        goalId: goalId,
        timezone: timezone,
      );

      reminders.insert(0, reminder);

      // ----------------------------------------------------------
      // Schedule Android local notification
      // ----------------------------------------------------------

      await _scheduleLocalNotification(reminder);

      return true;
    } catch (e) {
      _showError(_cleanError(e));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================
  // UPDATE REMINDER
  // ============================================================

  Future<bool> updateReminder({
    required String reminderId,
    String? module,
    String? type,
    String? title,
    String? message,
    String? priority,
    String? time,
    List<String>? days,
    int? intervalMinutes,
    String? goalId,
    String? timezone,
  }) async {
    isSaving.value = true;

    try {
      final updated = await _service.updateReminder(
        reminderId: reminderId,
        module: module,
        type: type,
        title: title,
        message: message,
        priority: priority,
        time: time,
        days: days,
        intervalMinutes: intervalMinutes,
        goalId: goalId,
        timezone: timezone,
      );

      final index = reminders.indexWhere(
        (ReminderModel item) => item.reminderId == reminderId,
      );

      if (index != -1) {
        reminders[index] = updated;
        reminders.refresh();
      }

      // ----------------------------------------------------------
      // scheduleReminder() automatically cancels the old local
      // notification before creating the new schedule.
      // ----------------------------------------------------------

      await _scheduleLocalNotification(updated);

      return true;
    } catch (e) {
      _showError(_cleanError(e));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================
  // PAUSE
  // ============================================================

  Future<void> pause(ReminderModel reminder) async {
    try {
      await _service.pauseReminder(reminder.reminderId);

      // Cancel local notification only after API succeeds.
      await _cancelLocalNotification(reminder);

      await fetchReminders();
    } catch (e) {
      _showError(_cleanError(e));
    }
  }

  // ============================================================
  // RESUME
  // ============================================================

  Future<void> resume(ReminderModel reminder) async {
    try {
      await _service.resumeReminder(reminder.reminderId);

      // fetchReminders() will receive the updated active
      // reminder and schedule it again.
      await fetchReminders();
    } catch (e) {
      _showError(_cleanError(e));
    }
  }

  // ============================================================
  // COMPLETE
  // ============================================================

  Future<void> complete(ReminderModel reminder) async {
    try {
      await _service.completeReminder(reminder.reminderId);

      await _cancelLocalNotification(reminder);

      await fetchReminders();
    } catch (e) {
      _showError(_cleanError(e));
    }
  }

  // ============================================================
  // SKIP
  // ============================================================

  Future<void> skip(ReminderModel reminder) async {
    try {
      await _service.skipReminder(reminder.reminderId);

      await _cancelLocalNotification(reminder);

      await fetchReminders();
    } catch (e) {
      _showError(_cleanError(e));
    }
  }

  // ============================================================
  // SNOOZE
  // ============================================================

  Future<void> snooze(ReminderModel reminder, int minutes) async {
    try {
      await _service.snoozeReminder(reminder.reminderId, minutes);

      // The backend may change the reminder's schedule/status.
      // Fetching it again ensures we schedule the latest version.
      await fetchReminders();
    } catch (e) {
      _showError(_cleanError(e));
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> delete(ReminderModel reminder) async {
    try {
      await _service.deleteReminder(reminder.reminderId);

      // Remove Android scheduled notification.
      await _cancelLocalNotification(reminder);

      reminders.removeWhere(
        (ReminderModel item) => item.reminderId == reminder.reminderId,
      );
    } catch (e) {
      _showError(_cleanError(e));
    }
  }

  // ============================================================
  // AI SCHEDULE
  // ============================================================

  Future<Map<String, dynamic>?> generateAiSchedule(String module) async {
    try {
      return await _service.generateAiSchedule(module);
    } catch (e) {
      _showError(_cleanError(e));
      return null;
    }
  }

  // ============================================================
  // AI PERSONALIZATION
  // ============================================================

  Future<Map<String, dynamic>?> personalizeAiReminder(String module) async {
    try {
      return await _service.personalizeAiReminder(module);
    } catch (e) {
      _showError(_cleanError(e));
      return null;
    }
  }

  // ============================================================
  // LOCAL NOTIFICATION HELPERS
  // ============================================================

  Future<void> _scheduleLocalNotification(ReminderModel reminder) async {
    try {
      await _localNotifications.scheduleReminder(reminder);

      debugPrint(
        '🔔 Local notification synced: '
        '${reminder.reminderId}',
      );
    } catch (e) {
      debugPrint('❌ Failed to schedule local notification: $e');
    }
  }

  Future<void> _cancelLocalNotification(ReminderModel reminder) async {
    try {
      await _localNotifications.cancelReminder(reminder);

      debugPrint(
        '🗑️ Local notification removed: '
        '${reminder.reminderId}',
      );
    } catch (e) {
      debugPrint('❌ Failed to cancel local notification: $e');
    }
  }

  // ============================================================
  // SYNC LOCAL NOTIFICATIONS
  // ============================================================

  Future<void> _syncLocalNotifications(List<ReminderModel> result) async {
    for (final reminder in result) {
      try {
        if (reminder.isActive) {
          await _scheduleLocalNotification(reminder);
        } else {
          await _cancelLocalNotification(reminder);
        }
      } catch (e) {
        debugPrint(
          '❌ Failed to sync reminder '
          '${reminder.reminderId}: $e',
        );
      }
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String? _nullableValue(String value) {
    return value.trim().isEmpty ? null : value;
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  void _showError(String message) {
    Get.snackbar(
      'Reminder',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
    );
  }
}
