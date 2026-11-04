import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/reminders/data/models/reminder_model.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const String _channelId = 'rhea_ai_reminders_v2';

  static const String _channelName = 'RheaAI Reminders';

  static const String _channelDescription =
      'Notifications for health reminders';

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    debugPrint('🔔 Initializing LocalNotificationService...');

    // ----------------------------------------------------------
    // TIMEZONE DATABASE
    // ----------------------------------------------------------

    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();

      final String timezoneName = timezoneInfo.identifier;

      debugPrint('🌍 Device timezone: $timezoneName');

      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (e) {
      debugPrint('⚠️ Could not detect device timezone: $e');

      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {
        debugPrint('⚠️ Could not set Asia/Kolkata timezone.');
      }
    }

    // ----------------------------------------------------------
    // ANDROID INITIALIZATION
    // ----------------------------------------------------------

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // ----------------------------------------------------------
    // ANDROID PERMISSIONS + CHANNEL
    // ----------------------------------------------------------

    if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // --------------------------------------------------------
      // ANDROID 13+ NOTIFICATION PERMISSION
      // --------------------------------------------------------

      final notificationPermission = await androidImplementation
          ?.requestNotificationsPermission();

      debugPrint(
        '🔔 Notification permission: '
        '$notificationPermission',
      );

      // --------------------------------------------------------
      // EXACT ALARM PERMISSION
      // --------------------------------------------------------

      try {
        final canScheduleExact = await androidImplementation
            ?.canScheduleExactNotifications();

        debugPrint(
          '⏰ Can schedule exact notifications: '
          '$canScheduleExact',
        );

        if (canScheduleExact != true) {
          debugPrint(
            '⚠️ Exact alarm permission is not granted. '
            'Requesting permission...',
          );

          final exactAlarmPermission = await androidImplementation
              ?.requestExactAlarmsPermission();

          debugPrint(
            '⏰ Exact alarm permission result: '
            '$exactAlarmPermission',
          );
        }
      } catch (e) {
        debugPrint('⚠️ Could not request exact alarm permission: $e');
      }

      // --------------------------------------------------------
      // NOTIFICATION CHANNEL
      // --------------------------------------------------------

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation?.createNotificationChannel(channel);

      debugPrint('🔔 Notification channel created: $_channelId');
    }

    _initialized = true;

    debugPrint('✅ LocalNotificationService initialized');
  }

  // ============================================================
  // TEST IMMEDIATE NOTIFICATION
  // ============================================================

  Future<void> showTestNotification() async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      autoCancel: true,
      onlyAlertOnce: false,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: 999999,
      title: 'RheaAI Reminder',
      body: 'Notification sound test 🔔',
      notificationDetails: details,
    );

    debugPrint('🔔 Test notification displayed');
  }

  // ============================================================
  // FCM FOREGROUND NOTIFICATION
  // ============================================================

  Future<void> showFcmNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      autoCancel: true,
      onlyAlertOnce: false,
    );

    const details = NotificationDetails(android: androidDetails);

    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      2147483647,
    );

    await _notifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );

    debugPrint('🔔 FCM notification shown locally');
  }

  // ============================================================
  // SCHEDULE REMINDER
  // ============================================================

  Future<void> scheduleReminder(ReminderModel reminder) async {
    await initialize();

    if (!reminder.isActive) {
      debugPrint(
        '⏭️ Reminder ${reminder.reminderId} '
        'is not active.',
      );
      return;
    }

    if (reminder.time == null || reminder.time!.trim().isEmpty) {
      debugPrint(
        '⏭️ Reminder ${reminder.reminderId} '
        'has no fixed time.',
      );
      return;
    }

    final reminderId = _notificationId(reminder.reminderId);

    // Cancel any old schedule first.
    await cancelReminder(reminder);

    final parsedTime = _parseTime(reminder.time!);

    if (parsedTime == null) {
      debugPrint(
        '❌ Invalid reminder time: '
        '${reminder.time}',
      );
      return;
    }

    // ----------------------------------------------------------
    // RECURRING REMINDER
    // ----------------------------------------------------------

    if (reminder.type == 'recurring' && reminder.days.isNotEmpty) {
      await _scheduleRecurringReminder(
        reminder: reminder,
        notificationId: reminderId,
        hour: parsedTime.hour,
        minute: parsedTime.minute,
      );

      return;
    }

    // ----------------------------------------------------------
    // FIXED-TIME REMINDER
    // ----------------------------------------------------------

    if (reminder.type == 'fixed_time') {
      await _scheduleFixedReminder(
        reminder: reminder,
        notificationId: reminderId,
        hour: parsedTime.hour,
        minute: parsedTime.minute,
      );

      return;
    }

    debugPrint(
      '⏭️ Reminder type ${reminder.type} '
      'is not handled by local fixed-time '
      'scheduling yet.',
    );
  }

  // ============================================================
  // FIXED TIME
  // ============================================================

  Future<void> _scheduleFixedReminder({
    required ReminderModel reminder,
    required int notificationId,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _schedule(
      reminder: reminder,
      notificationId: notificationId,
      scheduledDate: scheduledDate,
    );

    debugPrint(
      '📅 Fixed reminder scheduled: '
      '${reminder.title} at $scheduledDate',
    );

    await debugPendingNotifications();
  }

  // ============================================================
  // RECURRING
  // ============================================================

  Future<void> _scheduleRecurringReminder({
    required ReminderModel reminder,
    required int notificationId,
    required int hour,
    required int minute,
  }) async {
    final weekdayMap = <String, int>{
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };

    final now = tz.TZDateTime.now(tz.local);

    for (var index = 0; index < reminder.days.length; index++) {
      final day = reminder.days[index].toLowerCase().trim();

      final weekday = weekdayMap[day];

      if (weekday == null) {
        debugPrint('⚠️ Invalid recurring day: $day');
        continue;
      }

      final nextDate = _nextDateForWeekday(
        now: now,
        weekday: weekday,
        hour: hour,
        minute: minute,
      );

      final id = notificationId + index;

      await _schedule(
        reminder: reminder,
        notificationId: id,
        scheduledDate: nextDate,
        matchComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      debugPrint(
        '📅 Recurring reminder scheduled: '
        '${reminder.title} → $day $nextDate',
      );
    }

    await debugPendingNotifications();
  }

  // ============================================================
  // NEXT WEEKDAY
  // ============================================================

  tz.TZDateTime _nextDateForWeekday({
    required tz.TZDateTime now,
    required int weekday,
    required int hour,
    required int minute,
  }) {
    var date = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    var difference = weekday - now.weekday;

    if (difference < 0) {
      difference += 7;
    }

    date = date.add(Duration(days: difference));

    if (difference == 0 && !date.isAfter(now)) {
      date = date.add(const Duration(days: 7));
    }

    return date;
  }

  // ============================================================
  // LOW LEVEL SCHEDULE
  // ============================================================

  Future<void> _schedule({
    required ReminderModel reminder,
    required int notificationId,
    required tz.TZDateTime scheduledDate,
    DateTimeComponents? matchComponents,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: _importanceForPriority(reminder.priority),
      priority: _priorityForPriority(reminder.priority),
      playSound: true,
      enableVibration: true,
      autoCancel: true,
      onlyAlertOnce: false,
    );

    final details = NotificationDetails(android: androidDetails);

    debugPrint(
      '⏰ Scheduling notification: '
      'id=$notificationId '
      'date=$scheduledDate '
      'title=${reminder.title}',
    );

    try {
      await _notifications.zonedSchedule(
        id: notificationId,
        title: reminder.title.isNotEmpty ? reminder.title : 'RheaAI Reminder',
        body: reminder.message.isNotEmpty
            ? reminder.message
            : 'You have a reminder.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
        payload: reminder.reminderId,
      );

      debugPrint(
        '✅ Notification scheduled successfully: '
        'id=$notificationId',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to schedule notification: $e');

      debugPrint('❌ StackTrace: $stackTrace');
    }
  }

  // ============================================================
  // DEBUG PENDING NOTIFICATIONS
  // ============================================================

  Future<void> debugPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();

      debugPrint('========== PENDING NOTIFICATIONS ==========');

      debugPrint('COUNT: ${pending.length}');

      if (pending.isEmpty) {
        debugPrint('⚠️ No pending local notifications found.');
      }

      for (final notification in pending) {
        debugPrint(
          'ID: ${notification.id} | '
          'TITLE: ${notification.title} | '
          'BODY: ${notification.body} | '
          'PAYLOAD: ${notification.payload}',
        );
      }

      debugPrint('===========================================');
    } catch (e) {
      debugPrint('❌ Could not read pending notifications: $e');
    }
  }

  // ============================================================
  // CANCEL REMINDER
  // ============================================================

  Future<void> cancelReminder(ReminderModel reminder) async {
    final baseId = _notificationId(reminder.reminderId);

    await _notifications.cancel(id: baseId);

    for (var i = 0; i < 20; i++) {
      await _notifications.cancel(id: baseId + i);
    }

    debugPrint(
      '🗑️ Local notification cancelled: '
      '${reminder.reminderId}',
    );
  }

  // ============================================================
  // CANCEL ALL
  // ============================================================

  Future<void> cancelAll() async {
    await _notifications.cancelAll();

    debugPrint('🗑️ All local notifications cancelled');
  }

  // ============================================================
  // NOTIFICATION ID
  // ============================================================

  int _notificationId(String reminderId) {
    var hash = 0;

    for (final codeUnit in reminderId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }

    return hash % 2000000000;
  }

  // ============================================================
  // TIME PARSER
  // ============================================================

  TimeOfDay? _parseTime(String value) {
    final parts = value.trim().split(':');

    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);

    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  // ============================================================
  // IMPORTANCE
  // ============================================================

  Importance _importanceForPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Importance.max;

      case 'high':
        return Importance.high;

      case 'low':
        return Importance.low;

      default:
        return Importance.high;
    }
  }

  // ============================================================
  // PRIORITY
  // ============================================================

  Priority _priorityForPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Priority.max;

      case 'high':
        return Priority.high;

      case 'low':
        return Priority.low;

      default:
        return Priority.high;
    }
  }

  // ============================================================
  // TEST SCHEDULED NOTIFICATION - 1 MINUTE
  // ============================================================

  Future<void> scheduleTestNotificationInOneMinute() async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);

    final scheduledDate = now.add(const Duration(minutes: 1));

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      autoCancel: true,
      onlyAlertOnce: false,
    );

    const details = NotificationDetails(android: androidDetails);

    debugPrint('==========================================');
    debugPrint('🧪 SCHEDULED NOTIFICATION TEST');
    debugPrint('🧪 NOW: $now');
    debugPrint('🧪 TEST SCHEDULE: $scheduledDate');
    debugPrint('==========================================');

    try {
      await _notifications.zonedSchedule(
        id: 888888,
        title: 'RheaAI Scheduled Test',
        body: 'This is a scheduled notification test.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'scheduled_test',
      );

      debugPrint('✅ TEST notification scheduled successfully');

      await debugPendingNotifications();
    } catch (e, stackTrace) {
      debugPrint('❌ TEST scheduling failed: $e');

      debugPrint('❌ StackTrace: $stackTrace');
    }
  }
  // ============================================================
  // NOTIFICATION TAP
  // ============================================================

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint(
      '🔔 Notification tapped: '
      '${response.payload}',
    );
  }
}
