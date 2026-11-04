class HealthLogModel {
  final int? id;
  final int? steps;
  final double? sleepHours;
  final int? caloriesConsumed;
  final int? caloriesBurned;
  final double? weightKg;
  final String? mood;
  final String? stressLevel;
  final int? waterAmountMl;
  final String? createdAt;

  HealthLogModel({
    this.id,
    this.steps,
    this.sleepHours,
    this.caloriesConsumed,
    this.caloriesBurned,
    this.weightKg,
    this.mood,
    this.stressLevel,
    this.waterAmountMl,
    this.createdAt,
  });

  factory HealthLogModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = json['data'] is Map ? json['data'] : json;

    return HealthLogModel(
      id: data['id'] is int
          ? data['id']
          : int.tryParse(data['id']?.toString() ?? ''),
      steps: data['steps'] is int
          ? data['steps']
          : int.tryParse(data['steps']?.toString() ?? ''),
      sleepHours: _toDouble(data['sleep_hours'] ?? data['sleepHours']),
      caloriesConsumed: data['calories_consumed'] is int
          ? data['calories_consumed']
          : int.tryParse(
              data['calories_consumed']?.toString() ??
                  data['caloriesConsumed']?.toString() ??
                  '',
            ),
      caloriesBurned: data['calories_burned'] is int
          ? data['calories_burned']
          : int.tryParse(
              data['calories_burned']?.toString() ??
                  data['caloriesBurned']?.toString() ??
                  '',
            ),
      weightKg: _toDouble(data['weight_kg'] ?? data['weightKg']),
      mood: data['mood']?.toString(),
      stressLevel:
          data['stress_level']?.toString() ?? data['stressLevel']?.toString(),
      waterAmountMl: data['amount_ml'] is int
          ? data['amount_ml']
          : int.tryParse(
              data['amount_ml']?.toString() ?? data['water']?.toString() ?? '',
            ),
      createdAt: data['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (steps != null) 'steps': steps,
      if (sleepHours != null) 'sleep_hours': sleepHours,
      if (caloriesConsumed != null) 'calories_consumed': caloriesConsumed,
      if (caloriesBurned != null) 'calories_burned': caloriesBurned,
      if (weightKg != null) 'weight_kg': weightKg,
      if (mood != null) 'mood': mood,
      if (stressLevel != null) 'stress_level': stressLevel,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class NutritionSummaryModel {
  final int? totalCalories;
  final double? totalProtein;
  final double? totalCarbs;
  final double? totalFat;
  final List<dynamic> meals;

  NutritionSummaryModel({
    this.totalCalories,
    this.totalProtein,
    this.totalCarbs,
    this.totalFat,
    this.meals = const [],
  });

  factory NutritionSummaryModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = json['data'] is Map ? json['data'] : json;

    return NutritionSummaryModel(
      totalCalories: data['total_calories'] is int
          ? data['total_calories']
          : int.tryParse(data['total_calories']?.toString() ?? '0'),
      totalProtein: HealthLogModel._toDouble(
        data['total_protein'] ?? data['protein'],
      ),
      totalCarbs: HealthLogModel._toDouble(
        data['total_carbs'] ?? data['carbs'],
      ),
      totalFat: HealthLogModel._toDouble(data['total_fat'] ?? data['fat']),
      meals: data['meals'] is List ? data['meals'] : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
      'meals': meals,
    };
  }
}

class SleepLogModel {
  final String? logDate;
  final double? sleepHours;
  final String? sleepQuality;
  final String? emoji;

  SleepLogModel({this.logDate, this.sleepHours, this.sleepQuality, this.emoji});

  factory SleepLogModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : json;

    return SleepLogModel(
      logDate: data['log_date']?.toString(),
      sleepHours: _toDouble(data['sleep_hours']),
      sleepQuality: data['sleep_quality']?.toString(),
      emoji: data['emoji']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (logDate != null) 'date': logDate,
      if (sleepHours != null) 'sleep_hours': sleepHours,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  String toString() {
    return 'SleepLogModel('
        'logDate: $logDate, '
        'sleepHours: $sleepHours, '
        'sleepQuality: $sleepQuality, '
        'emoji: $emoji'
        ')';
  }
}
