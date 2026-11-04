class ReminderModel {
  final String reminderId;
  final String module;
  final String title;
  final String message;
  final String type;
  final String priority;
  final String status;
  final String? timezone;
  final String? time;
  final List<String> days;
  final int? intervalMinutes;
  final String? goalId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? snoozedUntil;

  const ReminderModel({
    required this.reminderId,
    required this.module,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.status,
    this.timezone,
    this.time,
    this.days = const [],
    this.intervalMinutes,
    this.goalId,
    this.createdAt,
    this.updatedAt,
    this.snoozedUntil,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];

    final List<String> parsedDays = rawDays is List
        ? rawDays.map((dynamic item) => item.toString()).toList()
        : <String>[];

    return ReminderModel(
      reminderId:
          json['reminder_id']?.toString() ?? json['id']?.toString() ?? '',
      module: json['module']?.toString() ?? 'custom',
      title: json['title']?.toString() ?? 'Reminder',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'fixed_time',
      priority: json['priority']?.toString() ?? 'normal',
      status: json['status']?.toString() ?? 'active',
      timezone: json['timezone']?.toString(),
      time: json['time']?.toString(),
      days: parsedDays,
      intervalMinutes: _toInt(json['interval_minutes']),
      goalId: json['goal_id']?.toString(),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
      snoozedUntil: _toDateTime(json['snoozed_until']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  bool get isActive => status == 'active';

  bool get isPaused => status == 'paused';

  bool get isCompleted => status == 'completed';

  bool get isSnoozed => status == 'snoozed';

  String get displayModule {
    switch (module) {
      case 'hydration':
        return 'Hydration';
      case 'sleep':
        return 'Sleep';
      case 'exercise':
        return 'Exercise';
      case 'meditation':
        return 'Meditation';
      case 'medication':
        return 'Medication';
      case 'nutrition':
        return 'Nutrition';
      case 'goal':
        return 'Goals';
      case 'habit':
        return 'Habits';
      case 'custom':
        return 'Custom';
      default:
        return module
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (String word) => word.isEmpty
                  ? word
                  : word[0].toUpperCase() + word.substring(1),
            )
            .join(' ');
    }
  }

  String get scheduleText {
    switch (type) {
      case 'interval':
        if (intervalMinutes == null) {
          return 'Interval reminder';
        }

        if (intervalMinutes! < 60) {
          return 'Every $intervalMinutes minutes';
        }

        final hours = intervalMinutes! ~/ 60;
        final minutes = intervalMinutes! % 60;

        if (minutes == 0) {
          return hours == 1 ? 'Every hour' : 'Every $hours hours';
        }

        return 'Every ${hours}h ${minutes}m';

      case 'recurring':
        if (days.isEmpty && time == null) {
          return 'Recurring';
        }

        final dayText = days.join(' • ');
        final timeText = time ?? '';

        if (dayText.isEmpty) {
          return timeText;
        }

        if (timeText.isEmpty) {
          return dayText;
        }

        return '$dayText · $timeText';

      case 'fixed_time':
        return time ?? 'Scheduled time';

      case 'ai_smart':
        return 'AI optimized';

      case 'goal_based':
        return 'Based on your goal';

      default:
        return 'Scheduled reminder';
    }
  }
}
