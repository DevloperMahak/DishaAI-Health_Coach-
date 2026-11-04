import 'dart:async';
import 'dart:io';

import 'package:disha_ai/features/reminders/data/models/reminder_model.dart';
import 'package:disha_ai/features/reminders/data/models/reminder_settings_model.dart';
import 'package:disha_ai/features/reminders/data/services/reminder_service.dart';
import 'package:disha_ai/features/reminders/presentation/screens/alarm_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalAlarmService {
  LocalAlarmService._();

  static final LocalAlarmService instance = LocalAlarmService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final ReminderService _reminderService = ReminderService();

  bool _initialized = false;
  bool _appReady = false;
  bool _openingAlarm = false;

  String? _pendingAlarmPayload;
  ReminderSettingsModel? _settings;

  // Timers are only a foreground supplement. Android scheduled
  // notifications remain responsible for background/locked delivery.
  final Map<int, Timer> _foregroundAlarmTimers = {};

  // Bump the channel ID when you need Android to create a fresh
  // channel with the configured sound and vibration.
  static const String _channelId = 'rhea_ai_alarm_v6';
  static const String _channelName = 'RheaAI Alarms';
  static const String _channelDescription =
      'Sound and full-screen health reminder alarms';

  // ------------------------------------------------------------
  // INITIALIZE
  // ------------------------------------------------------------

  Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('🔔 LocalAlarmService: initializing');

    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final timezoneName = timezoneInfo.identifier;

      tz.setLocalLocation(tz.getLocation(timezoneName));

      debugPrint('🌍 Alarm timezone: $timezoneName');
    } catch (e) {
      debugPrint('⚠️ Timezone detection failed: $e');

      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (fallbackError) {
        debugPrint('⚠️ Timezone fallback failed: $fallbackError');
      }
    }

    // Load settings before creating the Android channel so the
    // initial channel sound reflects the current setting.
    try {
      _settings = await _reminderService.getSettings();
      debugPrint(
        '⚙️ Reminder settings loaded. '
        'Enabled=${_settings?.remindersEnabled}, '
        'Sound=${_settings?.sound}, '
        'Vibration=${_settings?.vibration}',
      );
    } catch (e) {
      debugPrint('⚠️ Could not load alarm settings during init: $e');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // When Android starts the app from a full-screen notification,
    // preserve its payload until the app has finished routing.
    try {
      final launchDetails = await _notifications
          .getNotificationAppLaunchDetails();

      if (launchDetails?.didNotificationLaunchApp == true) {
        final payload = launchDetails?.notificationResponse?.payload?.trim();

        if (payload != null && payload.isNotEmpty) {
          _pendingAlarmPayload = payload;
          debugPrint('📥 Alarm launch payload recovered: $payload');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Could not read alarm launch details: $e');
    }

    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Android 13+ notification permission.
      try {
        final granted = await android?.requestNotificationsPermission();
        debugPrint('🔔 Notification permission result: $granted');
      } catch (e) {
        debugPrint('⚠️ Notification permission request failed: $e');
      }

      // Exact alarm permission.
      try {
        final canScheduleExact = await android?.canScheduleExactNotifications();

        debugPrint('⏰ Exact alarm allowed: $canScheduleExact');

        if (canScheduleExact != true) {
          final result = await android?.requestExactAlarmsPermission();
          debugPrint('⏰ Exact alarm permission request result: $result');
        }
      } catch (e) {
        debugPrint('⚠️ Exact alarm permission check failed: $e');
      }

      // Android 14+ full-screen intent permission.
      try {
        final result = await android?.requestFullScreenIntentPermission();
        debugPrint('📱 Full-screen permission request result: $result');
      } catch (e) {
        debugPrint('⚠️ Full-screen permission request failed: $e');
      }

      final soundEnabled = _soundEnabled(_settings);
      final channelSound = soundEnabled
          ? _notificationSound(_settings?.sound)
          : null;

      final channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: soundEnabled,
        sound: channelSound,
        enableVibration: _settings?.vibration ?? true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      await android?.createNotificationChannel(channel);

      debugPrint(
        '🔔 Alarm channel ready: $_channelId; '
        'soundEnabled=$soundEnabled; '
        'sound=${_settings?.sound}; '
        'vibration=${_settings?.vibration ?? true}',
      );
    }

    _initialized = true;
    debugPrint('✅ LocalAlarmService initialized');
  }

  // ------------------------------------------------------------
  // APP READY / PENDING ALARM
  // ------------------------------------------------------------

  Future<void> markAppReady() async {
    _appReady = true;
    debugPrint('🟢 LocalAlarmService: app ready');

    await _processPendingAlarm();
  }

  Future<void> _processPendingAlarm() async {
    final payload = _pendingAlarmPayload?.trim();

    if (payload == null || payload.isEmpty) {
      debugPrint('ℹ️ No pending alarm payload');
      return;
    }

    if (_openingAlarm) {
      debugPrint('⏳ Alarm opening already in progress');
      return;
    }

    debugPrint('📥 Processing pending alarm: $payload');

    // Allow the initial route and GetX navigator to settle.
    for (var attempt = 1; attempt <= 10; attempt++) {
      if (!_appReady) return;

      if (Get.context != null && Get.key.currentState != null) {
        break;
      }

      debugPrint(
        '⏳ Waiting for GetX navigator '
        '(attempt $attempt/10)',
      );

      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (Get.context == null || Get.key.currentState == null) {
      debugPrint(
        '❌ Navigator unavailable after retries. '
        'Pending alarm retained.',
      );
      return;
    }

    // Clear the payload only when we're ready to attempt opening it.
    _pendingAlarmPayload = null;

    await _openAlarmScreen(payload);

    // If opening failed, _openAlarmScreen restores the payload.
    // Don't rely on another notification callback to retry it.
    if (_pendingAlarmPayload != null) {
      debugPrint(
        '⚠️ Alarm remains pending. '
        'Call markAppReady() again after navigation is ready.',
      );
    }
  }

  // ------------------------------------------------------------
  // SETTINGS
  // ------------------------------------------------------------

  Future<ReminderSettingsModel?> loadSettings() async {
    await initialize();

    try {
      _settings = await _reminderService.getSettings();
      return _settings;
    } catch (e) {
      debugPrint('⚠️ Loading reminder settings failed: $e');
      return _settings;
    }
  }

  // ------------------------------------------------------------
  // SYNC ACTIVE REMINDERS
  // ------------------------------------------------------------

  Future<void> syncActiveAlarms() async {
    await initialize();

    try {
      final settings = await loadSettings();

      if (settings != null && !settings.remindersEnabled) {
        debugPrint('⏸️ Reminders disabled in settings');
        await cancelAll();
        return;
      }

      final reminders = await _reminderService.getReminders(
        status: 'active',
        page: 1,
        perPage: 100,
      );

      debugPrint('📥 Active reminders received: ${reminders.length}');

      await cancelAll();

      for (final reminder in reminders) {
        try {
          await scheduleReminder(reminder);
        } catch (e, stackTrace) {
          debugPrint('❌ Failed to schedule ${reminder.reminderId}: $e');
          debugPrint('$stackTrace');
        }
      }

      await debugPendingNotifications();
    } catch (e, stackTrace) {
      debugPrint('❌ Active alarm sync failed: $e');
      debugPrint('$stackTrace');
    }
  }

  // ------------------------------------------------------------
  // SCHEDULE REMINDER
  // ------------------------------------------------------------

  Future<void> scheduleReminder(ReminderModel reminder) async {
    await initialize();

    if (!reminder.isActive) {
      debugPrint('⏭️ Skipping inactive reminder: ${reminder.reminderId}');
      return;
    }

    final settings = _settings ?? await loadSettings();

    if (settings != null && !settings.remindersEnabled) {
      debugPrint('⏭️ Reminders disabled; not scheduling');
      return;
    }

    final time = reminder.time?.trim();

    if (time == null || time.isEmpty) {
      debugPrint('⏭️ Reminder has no time: ${reminder.reminderId}');
      return;
    }

    final parsedTime = _parseTime(time);

    if (parsedTime == null) {
      debugPrint('❌ Invalid reminder time: $time');
      return;
    }

    await cancelReminder(reminder.reminderId);

    if (_isInsideQuietHoursForNextSchedule(
      hour: parsedTime.hour,
      minute: parsedTime.minute,
      settings: settings,
      priority: reminder.priority,
    )) {
      debugPrint(
        '🌙 Reminder skipped because its scheduled time is in quiet hours: '
        '${reminder.reminderId}',
      );
      return;
    }

    if (reminder.type == 'recurring' && reminder.days.isNotEmpty) {
      await _scheduleRecurringReminder(
        reminder: reminder,
        hour: parsedTime.hour,
        minute: parsedTime.minute,
      );
      return;
    }

    if (reminder.type == 'fixed_time') {
      await _scheduleFixedReminder(
        reminder: reminder,
        hour: parsedTime.hour,
        minute: parsedTime.minute,
      );
      return;
    }

    if (reminder.type == 'interval') {
      await _scheduleIntervalReminder(reminder: reminder);
      return;
    }

    debugPrint('⚠️ Unsupported reminder type: ${reminder.type}');
  }

  // ------------------------------------------------------------
  // FIXED TIME
  // ------------------------------------------------------------

  Future<void> _scheduleFixedReminder({
    required ReminderModel reminder,
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

    final id = _notificationId(reminder.reminderId);

    await _scheduleNotification(
      reminder: reminder,
      notificationId: id,
      scheduledDate: scheduledDate,
    );

    debugPrint('📅 Fixed alarm scheduled: ${reminder.title} at $scheduledDate');
  }

  // ------------------------------------------------------------
  // RECURRING
  // ------------------------------------------------------------

  Future<void> _scheduleRecurringReminder({
    required ReminderModel reminder,
    required int hour,
    required int minute,
  }) async {
    const weekdayMap = <String, int>{
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };

    final now = tz.TZDateTime.now(tz.local);
    final baseId = _notificationId(reminder.reminderId);

    for (var index = 0; index < reminder.days.length; index++) {
      final day = reminder.days[index].trim().toLowerCase();
      final weekday = weekdayMap[day];

      if (weekday == null) {
        debugPrint('⚠️ Invalid recurring weekday: $day');
        continue;
      }

      final nextDate = _nextDateForWeekday(
        now: now,
        weekday: weekday,
        hour: hour,
        minute: minute,
      );

      final notificationId = baseId + index;

      await _scheduleNotification(
        reminder: reminder,
        notificationId: notificationId,
        scheduledDate: nextDate,
        matchComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      debugPrint(
        '📅 Recurring alarm scheduled: ${reminder.title}; '
        'day=$day; date=$nextDate; id=$notificationId',
      );
    }
  }

  // ------------------------------------------------------------
  // INTERVAL
  // ------------------------------------------------------------

  Future<void> _scheduleIntervalReminder({
    required ReminderModel reminder,
  }) async {
    final interval = reminder.intervalMinutes;

    if (interval == null || interval <= 0) {
      debugPrint('⚠️ Invalid interval for ${reminder.reminderId}');
      return;
    }

    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(minutes: interval));

    await _scheduleNotification(
      reminder: reminder,
      notificationId: _notificationId(reminder.reminderId),
      scheduledDate: scheduledDate,
    );

    debugPrint('⏱️ Interval alarm scheduled for $scheduledDate');
  }

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

  // ------------------------------------------------------------
  // CREATE SCHEDULED NOTIFICATION
  // ------------------------------------------------------------

  Future<void> _scheduleNotification({
    required ReminderModel reminder,
    required int notificationId,
    required tz.TZDateTime scheduledDate,
    DateTimeComponents? matchComponents,
  }) async {
    final settings = _settings ?? await loadSettings();

    final soundEnabled = _soundEnabled(settings);
    final vibrationEnabled = settings?.vibration ?? true;
    final sound = soundEnabled ? _notificationSound(settings?.sound) : null;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,

      // Android uses this for alarm-style notification presentation.
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      importance: Importance.max,
      priority: Priority.max,

      playSound: soundEnabled,
      sound: sound,
      enableVibration: vibrationEnabled,
      audioAttributesUsage: AudioAttributesUsage.alarm,

      // Keep it visible until the user interacts with it.
      autoCancel: false,
      ongoing: true,
      onlyAlertOnce: false,
      showWhen: true,
    );

    final details = NotificationDetails(android: androidDetails);

    debugPrint(
      '⏰ Scheduling alarm: '
      'id=$notificationId, '
      'reminder=${reminder.reminderId}, '
      'time=$scheduledDate, '
      'fullScreen=true, '
      'soundEnabled=$soundEnabled, '
      'vibration=$vibrationEnabled',
    );

    await _notifications.zonedSchedule(
      id: notificationId,
      title: reminder.title.trim().isNotEmpty
          ? reminder.title.trim()
          : 'RheaAI Reminder',
      body: reminder.message.trim().isNotEmpty
          ? reminder.message.trim()
          : 'You have a reminder.',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchComponents,
      payload: reminder.reminderId,
    );

    // Supplemental behavior only when Flutter is alive and foregrounded.
    _scheduleForegroundAlarmTimer(
      reminder: reminder,
      notificationId: notificationId,
      scheduledDate: scheduledDate,
      matchComponents: matchComponents,
    );

    debugPrint('✅ Android notification registered: id=$notificationId');
  }

  // ------------------------------------------------------------
  // FOREGROUND TIMER
  // ------------------------------------------------------------

  void _scheduleForegroundAlarmTimer({
    required ReminderModel reminder,
    required int notificationId,
    required tz.TZDateTime scheduledDate,
    DateTimeComponents? matchComponents,
  }) {
    _foregroundAlarmTimers[notificationId]?.cancel();

    final now = tz.TZDateTime.now(tz.local);
    var duration = scheduledDate.difference(now);

    if (duration.isNegative) {
      duration = Duration.zero;
    }

    debugPrint(
      '🕐 Foreground timer set: id=$notificationId, '
      'in ${duration.inSeconds}s',
    );

    _foregroundAlarmTimers[notificationId] = Timer(duration, () async {
      _foregroundAlarmTimers.remove(notificationId);

      debugPrint(
        '⏰ Foreground timer fired: '
        'id=$notificationId, '
        'state=${WidgetsBinding.instance.lifecycleState}',
      );

      final isForeground =
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

      if (isForeground && _appReady) {
        await _openAlarmScreen(reminder.reminderId);
      } else if (!_appReady) {
        _pendingAlarmPayload = reminder.reminderId;
      }

      // Android owns background/locked delivery. Do not attempt to
      // force Flutter navigation while the app is backgrounded.
      if (matchComponents == DateTimeComponents.dayOfWeekAndTime) {
        final nextDate = scheduledDate.add(const Duration(days: 7));

        _scheduleForegroundAlarmTimer(
          reminder: reminder,
          notificationId: notificationId,
          scheduledDate: nextDate,
          matchComponents: matchComponents,
        );
      }
    });
  }

  // ------------------------------------------------------------
  // NOTIFICATION RESPONSE / FULL-SCREEN LAUNCH
  // ------------------------------------------------------------

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload?.trim();

    debugPrint(
      '📲 Notification response received: '
      'action=${response.actionId}; payload=$payload',
    );

    if (payload == null || payload.isEmpty) {
      debugPrint('⚠️ Notification response had no reminder payload');
      return;
    }

    if (!_appReady) {
      _pendingAlarmPayload = payload;
      debugPrint('⏳ App not ready; alarm payload queued');
      return;
    }

    unawaited(_openAlarmScreen(payload));
  }

  // ------------------------------------------------------------
  // OPEN ALARM SCREEN
  // ------------------------------------------------------------

  Future<void> _openAlarmScreen(String reminderId) async {
    if (_openingAlarm) {
      debugPrint('⏭️ Another alarm screen is already opening');
      return;
    }

    _openingAlarm = true;

    try {
      if (!_appReady) {
        _pendingAlarmPayload = reminderId;
        return;
      }

      if (Get.context == null || Get.key.currentState == null) {
        debugPrint('⏳ GetX navigator is not ready; alarm queued');
        _pendingAlarmPayload = reminderId;
        return;
      }

      final currentRoute = Get.currentRoute;

      if (currentRoute.contains('AlarmScreen')) {
        debugPrint('⏭️ AlarmScreen is already open');
        return;
      }

      debugPrint('🔎 Fetching reminder details for $reminderId');

      final reminder = await _reminderService.getReminder(reminderId);

      // The navigator might not be ready after the network request.
      if (Get.context == null || Get.key.currentState == null) {
        _pendingAlarmPayload = reminderId;
        debugPrint('⏳ Navigator unavailable after fetch; alarm queued');
        return;
      }

      debugPrint('🖥️ Opening AlarmScreen for $reminderId');

      await Get.to(
        () => AlarmScreen(reminder: reminder),
        fullscreenDialog: true,
        preventDuplicates: true,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Could not open AlarmScreen: $e');
      debugPrint('$stackTrace');
      _pendingAlarmPayload = reminderId;
    } finally {
      _openingAlarm = false;
    }
  }

  // ------------------------------------------------------------
  // CANCEL
  // ------------------------------------------------------------

  Future<void> cancelReminder(String reminderId) async {
    await initialize();

    final baseId = _notificationId(reminderId);

    for (var index = 0; index < 20; index++) {
      final id = baseId + index;
      _foregroundAlarmTimers[id]?.cancel();
      _foregroundAlarmTimers.remove(id);

      await _notifications.cancel(id: id);
    }

    final snoozeId = baseId + 500;
    _foregroundAlarmTimers[snoozeId]?.cancel();
    _foregroundAlarmTimers.remove(snoozeId);

    await _notifications.cancel(id: snoozeId);

    debugPrint('🗑️ Cancelled local alarms for $reminderId');
  }

  Future<void> cancelAll() async {
    await initialize();

    for (final timer in _foregroundAlarmTimers.values) {
      timer.cancel();
    }

    _foregroundAlarmTimers.clear();

    await _notifications.cancelAll();

    debugPrint('🗑️ All local alarms cancelled');
  }

  Future<void> rescheduleReminder(ReminderModel reminder) async {
    await cancelReminder(reminder.reminderId);
    await scheduleReminder(reminder);
  }

  // ------------------------------------------------------------
  // SNOOZE
  // ------------------------------------------------------------

  Future<void> scheduleSnooze({
    required ReminderModel reminder,
    required int minutes,
  }) async {
    await initialize();

    if (minutes <= 0) {
      throw ArgumentError.value(minutes, 'minutes', 'Must be positive');
    }

    final id = _notificationId(reminder.reminderId) + 500;

    _foregroundAlarmTimers[id]?.cancel();
    _foregroundAlarmTimers.remove(id);
    await _notifications.cancel(id: id);

    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(minutes: minutes));

    await _scheduleNotification(
      reminder: reminder,
      notificationId: id,
      scheduledDate: scheduledDate,
    );

    debugPrint(
      '😴 Snooze scheduled: reminder=${reminder.reminderId}, '
      'minutes=$minutes, date=$scheduledDate',
    );
  }

  // ------------------------------------------------------------
  // COMPLETE
  // ------------------------------------------------------------

  Future<void> completeReminder(String reminderId) async {
    await _reminderService.completeReminder(reminderId);
    await cancelReminder(reminderId);

    debugPrint('✅ Reminder completed and local alarms cancelled');
  }

  // ------------------------------------------------------------
  // PENDING NOTIFICATIONS DEBUG
  // ------------------------------------------------------------

  Future<void> debugPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();

      debugPrint('========== PENDING RHEAAI ALARMS ==========');
      debugPrint('COUNT: ${pending.length}');

      for (final item in pending) {
        debugPrint(
          'ID=${item.id} | '
          'TITLE=${item.title} | '
          'PAYLOAD=${item.payload}',
        );
      }

      debugPrint('===========================================');
    } catch (e) {
      debugPrint('❌ Could not read pending alarms: $e');
    }
  }

  // ------------------------------------------------------------
  // SOUND
  // ------------------------------------------------------------

  bool _soundEnabled(ReminderSettingsModel? settings) {
    if (settings == null) return true;

    final selected = settings.sound.trim().toLowerCase();

    return selected.isNotEmpty &&
        selected != 'silent' &&
        selected != 'none' &&
        selected != 'off';
  }

  RawResourceAndroidNotificationSound _notificationSound(String? value) {
    final name = (value ?? 'gentle_bell').trim().toLowerCase();

    // Only use resource names that actually exist in
    // android/app/src/main/res/raw/.
    const availableSounds = <String>{
      'gentle_bell',
      'water_drop',
      'chime',
      'meditation_tone',
    };

    final resourceName = availableSounds.contains(name) ? name : 'gentle_bell';

    return RawResourceAndroidNotificationSound(resourceName);
  }

  // ------------------------------------------------------------
  // QUIET HOURS
  // ------------------------------------------------------------

  bool _isInsideQuietHoursForNextSchedule({
    required int hour,
    required int minute,
    required ReminderSettingsModel? settings,
    required String priority,
  }) {
    if (settings == null || !settings.quietHoursEnabled) {
      return false;
    }

    if (priority.toLowerCase() == 'urgent') {
      return false;
    }

    final start = _parseMinutes(settings.quietStart);
    final end = _parseMinutes(settings.quietEnd);

    if (start == null || end == null || start == end) {
      return false;
    }

    final scheduledMinute = hour * 60 + minute;

    if (start < end) {
      return scheduledMinute >= start && scheduledMinute < end;
    }

    // Quiet hours cross midnight.
    return scheduledMinute >= start || scheduledMinute < end;
  }

  // ------------------------------------------------------------
  // TIME PARSING
  // ------------------------------------------------------------

  TimeOfDay? _parseTime(String value) {
    final parts = value.trim().split(':');

    if (parts.length < 2) return null;

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

  int? _parseMinutes(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final parts = value.trim().split(':');

    if (parts.length < 2) return null;

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

    return hour * 60 + minute;
  }

  // ------------------------------------------------------------
  // NOTIFICATION ID
  // ------------------------------------------------------------

  int _notificationId(String reminderId) {
    var hash = 0;

    for (final codeUnit in reminderId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }

    // Leave room for recurring-day offsets and snooze IDs.
    return hash % 1800000000;
  }
}
