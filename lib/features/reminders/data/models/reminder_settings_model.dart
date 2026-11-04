class ReminderSettingsModel {
  final bool remindersEnabled;
  final bool aiRemindersEnabled;
  final String frequency;
  final int defaultSnoozeMinutes;
  final String sound;
  final bool vibration;
  final String timezone;
  final bool autoDetectTimezone;
  final bool weekendMode;
  final bool quietHoursEnabled;
  final String quietStart;
  final String quietEnd;
  final List<String> channels;
  final Map<String, bool> categories;
  final bool goalBasedReminders;

  const ReminderSettingsModel({
    required this.remindersEnabled,
    required this.aiRemindersEnabled,
    required this.frequency,
    required this.defaultSnoozeMinutes,
    required this.sound,
    required this.vibration,
    required this.timezone,
    required this.autoDetectTimezone,
    required this.weekendMode,
    required this.quietHoursEnabled,
    required this.quietStart,
    required this.quietEnd,
    required this.channels,
    required this.categories,
    required this.goalBasedReminders,
  });

  factory ReminderSettingsModel.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];

    final Map<String, bool> parsedCategories = <String, bool>{};

    if (rawCategories is Map) {
      rawCategories.forEach((dynamic key, dynamic value) {
        parsedCategories[key.toString()] = value == true;
      });
    }

    final rawChannels = json['channels'];

    final List<String> parsedChannels = rawChannels is List
        ? rawChannels.map((dynamic item) => item.toString()).toList()
        : <String>['push', 'in_app'];

    return ReminderSettingsModel(
      remindersEnabled: json['reminders_enabled'] == true,
      aiRemindersEnabled: json['ai_reminders_enabled'] == true,
      frequency: json['frequency']?.toString() ?? 'normal',
      defaultSnoozeMinutes:
          int.tryParse(json['default_snooze_minutes']?.toString() ?? '') ?? 15,
      sound: json['sound']?.toString() ?? 'gentle_bell',
      vibration: json['vibration'] != false,
      timezone: json['timezone']?.toString() ?? 'Asia/Kolkata',
      autoDetectTimezone: json['auto_detect_timezone'] != false,
      weekendMode: json['weekend_mode'] == true,
      quietHoursEnabled: json['quiet_hours_enabled'] == true,
      quietStart: json['quiet_start']?.toString() ?? '22:00',
      quietEnd: json['quiet_end']?.toString() ?? '07:00',
      channels: parsedChannels,
      categories: parsedCategories,
      goalBasedReminders: json['goal_based_reminders'] != false,
    );
  }

  ReminderSettingsModel copyWith({
    bool? remindersEnabled,
    bool? aiRemindersEnabled,
    String? frequency,
    int? defaultSnoozeMinutes,
    String? sound,
    bool? vibration,
    String? timezone,
    bool? autoDetectTimezone,
    bool? weekendMode,
    bool? quietHoursEnabled,
    String? quietStart,
    String? quietEnd,
    List<String>? channels,
    Map<String, bool>? categories,
    bool? goalBasedReminders,
  }) {
    return ReminderSettingsModel(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      aiRemindersEnabled: aiRemindersEnabled ?? this.aiRemindersEnabled,
      frequency: frequency ?? this.frequency,
      defaultSnoozeMinutes: defaultSnoozeMinutes ?? this.defaultSnoozeMinutes,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      timezone: timezone ?? this.timezone,
      autoDetectTimezone: autoDetectTimezone ?? this.autoDetectTimezone,
      weekendMode: weekendMode ?? this.weekendMode,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStart: quietStart ?? this.quietStart,
      quietEnd: quietEnd ?? this.quietEnd,
      channels: channels ?? this.channels,
      categories: categories ?? this.categories,
      goalBasedReminders: goalBasedReminders ?? this.goalBasedReminders,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'reminders_enabled': remindersEnabled,
      'ai_reminders_enabled': aiRemindersEnabled,
      'frequency': frequency,
      'default_snooze_minutes': defaultSnoozeMinutes,
      'sound': sound,
      'vibration': vibration,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_start': quietStart,
      'quiet_end': quietEnd,
      'channels': channels,
      'categories': categories,
    };
  }
}
