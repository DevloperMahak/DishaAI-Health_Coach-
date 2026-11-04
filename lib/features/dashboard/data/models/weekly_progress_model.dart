class WeeklyProgressModel {
  final String weekStart;
  final String weekEnd;
  final WeeklyProgressSummary summary;
  final List<WeeklyDayProgress> dailyProgress;

  const WeeklyProgressModel({
    required this.weekStart,
    required this.weekEnd,
    required this.summary,
    required this.dailyProgress,
  });

  factory WeeklyProgressModel.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'];

    final dailyJson = json['daily_progress'];

    return WeeklyProgressModel(
      weekStart: json['week_start']?.toString() ?? '',
      weekEnd: json['week_end']?.toString() ?? '',
      summary: WeeklyProgressSummary.fromJson(
        summaryJson is Map
            ? Map<String, dynamic>.from(summaryJson)
            : <String, dynamic>{},
      ),
      dailyProgress: dailyJson is List
          ? dailyJson
                .whereType<Map>()
                .map(
                  (item) => WeeklyDayProgress.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  WeeklyDayProgress? get today {
    for (final day in dailyProgress) {
      if (day.isToday) return day;
    }
    return null;
  }
}

class WeeklyProgressSummary {
  final double averageCalories;
  final double targetCalories;
  final double totalCalories;
  final double averageProteinG;
  final double averageCarbsG;
  final double averageFatG;
  final int daysLogged;

  const WeeklyProgressSummary({
    required this.averageCalories,
    required this.targetCalories,
    required this.totalCalories,
    required this.averageProteinG,
    required this.averageCarbsG,
    required this.averageFatG,
    required this.daysLogged,
  });

  factory WeeklyProgressSummary.fromJson(Map<String, dynamic> json) {
    return WeeklyProgressSummary(
      averageCalories: _toDouble(json['average_calories']),
      targetCalories: _toDouble(json['target_calories']),
      totalCalories: _toDouble(json['total_calories']),
      averageProteinG: _toDouble(json['average_protein_g']),
      averageCarbsG: _toDouble(json['average_carbs_g']),
      averageFatG: _toDouble(json['average_fat_g']),
      daysLogged: _toInt(json['days_logged']),
    );
  }
}

class WeeklyDayProgress {
  final String date;
  final String day;
  final bool isToday;

  final double calories;
  final double targetCalories;
  final double caloriePercentage;

  final double proteinG;
  final double carbsG;
  final double fatG;

  final int steps;
  final int targetSteps;
  final double stepsPercentage;

  final double sleepHours;
  final double targetSleepHours;
  final double sleepPercentage;

  final double waterMl;
  final double targetWaterMl;
  final double waterPercentage;

  const WeeklyDayProgress({
    required this.date,
    required this.day,
    required this.isToday,
    required this.calories,
    required this.targetCalories,
    required this.caloriePercentage,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.steps,
    required this.targetSteps,
    required this.stepsPercentage,
    required this.sleepHours,
    required this.targetSleepHours,
    required this.sleepPercentage,
    required this.waterMl,
    required this.targetWaterMl,
    required this.waterPercentage,
  });

  factory WeeklyDayProgress.fromJson(Map<String, dynamic> json) {
    return WeeklyDayProgress(
      date: json['date']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      isToday: json['is_today'] == true,

      calories: _toDouble(json['calories']),
      targetCalories: _toDouble(json['target_calories']),
      caloriePercentage: _toDouble(json['calorie_percentage']),

      proteinG: _toDouble(json['protein_g']),
      carbsG: _toDouble(json['carbs_g']),
      fatG: _toDouble(json['fat_g']),

      steps: _toInt(json['steps']),
      targetSteps: _toInt(json['target_steps']),
      stepsPercentage: _toDouble(json['steps_percentage']),

      sleepHours: _toDouble(json['sleep_hours']),
      targetSleepHours: _toDouble(json['target_sleep_hours']),
      sleepPercentage: _toDouble(json['sleep_percentage']),

      waterMl: _toDouble(json['water_ml']),
      targetWaterMl: _toDouble(json['target_water_ml']),
      waterPercentage: _toDouble(json['water_percentage']),
    );
  }

  double get calorieProgress {
    return (caloriePercentage / 100).clamp(0.0, 1.0);
  }

  double get stepsProgress {
    return (stepsPercentage / 100).clamp(0.0, 1.0);
  }

  double get sleepProgress {
    return (sleepPercentage / 100).clamp(0.0, 1.0);
  }

  double get waterProgress {
    return (waterPercentage / 100).clamp(0.0, 1.0);
  }

  String get shortDay {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'M';
      case 'tuesday':
        return 'T';
      case 'wednesday':
        return 'W';
      case 'thursday':
        return 'T';
      case 'friday':
        return 'F';
      case 'saturday':
        return 'S';
      case 'sunday':
        return 'S';
      default:
        return day.isNotEmpty ? day.substring(0, 1).toUpperCase() : '';
    }
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();

  return double.tryParse(value.toString()) ?? 0.0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString()) ?? 0;
}
