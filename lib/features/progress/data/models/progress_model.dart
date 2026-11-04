class ProgressModel {
  final String filter;
  final String startDate;
  final String endDate;

  final ProgressMetric calories;
  final ProgressMetric steps;
  final SleepMetric sleep;
  final WaterMetric water;
  final WeightMetric weight;

  final List<ProgressChartPoint> chart;

  const ProgressModel({
    required this.filter,
    required this.startDate,
    required this.endDate,
    required this.calories,
    required this.steps,
    required this.sleep,
    required this.water,
    required this.weight,
    required this.chart,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      filter: json['filter']?.toString() ?? 'today',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      calories: ProgressMetric.fromJson(_map(json['calories'])),
      steps: ProgressMetric.fromJson(_map(json['steps'])),
      sleep: SleepMetric.fromJson(_map(json['sleep'])),
      water: WaterMetric.fromJson(_map(json['water'])),
      weight: WeightMetric.fromJson(_map(json['weight'])),
      chart: (json['chart'] is List)
          ? (json['chart'] as List)
                .whereType<Map>()
                .map(
                  (item) => ProgressChartPoint.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : [],
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }
}

// ============================================================
// CALORIES / STEPS
// ============================================================

class ProgressMetric {
  final double total;
  final double average;
  final double target;
  final double goalPercentage;
  final int daysLogged;

  const ProgressMetric({
    required this.total,
    required this.average,
    required this.target,
    required this.goalPercentage,
    required this.daysLogged,
  });

  factory ProgressMetric.fromJson(Map<String, dynamic> json) {
    return ProgressMetric(
      total: _toDouble(json['total']),
      average: _toDouble(json['average']),
      target: _toDouble(json['target']),
      goalPercentage: _toDouble(json['goal_percentage']),
      daysLogged: _toInt(json['days_logged']),
    );
  }
}

// ============================================================
// SLEEP
// ============================================================

class SleepMetric {
  final double totalHours;
  final double averageHours;
  final double targetHours;
  final double goalPercentage;
  final int daysLogged;

  const SleepMetric({
    required this.totalHours,
    required this.averageHours,
    required this.targetHours,
    required this.goalPercentage,
    required this.daysLogged,
  });

  factory SleepMetric.fromJson(Map<String, dynamic> json) {
    return SleepMetric(
      totalHours: _toDouble(json['total_hours']),
      averageHours: _toDouble(json['average_hours']),
      targetHours: _toDouble(json['target_hours']),
      goalPercentage: _toDouble(json['goal_percentage']),
      daysLogged: _toInt(json['days_logged']),
    );
  }
}

// ============================================================
// WATER
// ============================================================

class WaterMetric {
  final double totalMl;
  final double averageMl;
  final double targetMl;
  final double goalPercentage;
  final int daysLogged;

  const WaterMetric({
    required this.totalMl,
    required this.averageMl,
    required this.targetMl,
    required this.goalPercentage,
    required this.daysLogged,
  });

  factory WaterMetric.fromJson(Map<String, dynamic> json) {
    return WaterMetric(
      totalMl: _toDouble(json['total_ml']),
      averageMl: _toDouble(json['average_ml']),
      targetMl: _toDouble(json['target_ml']),
      goalPercentage: _toDouble(json['goal_percentage']),
      daysLogged: _toInt(json['days_logged']),
    );
  }
}

// ============================================================
// WEIGHT
// ============================================================

// ============================================================
// WEIGHT
// ============================================================

class WeightMetric {
  final double startKg;
  final double currentKg;
  final double changeKg;
  final double targetKg;
  final String unit;

  const WeightMetric({
    required this.startKg,
    required this.currentKg,
    required this.changeKg,
    required this.targetKg,
    required this.unit,
  });

  factory WeightMetric.fromJson(Map<String, dynamic> json) {
    // Support both backend field naming conventions.
    final double starting = _toDouble(
      json['starting_weight'] ?? json['starting_kg'] ?? json['start_kg'],
    );

    final double current = _toDouble(
      json['current_weight'] ?? json['current_kg'],
    );

    final double target = _toDouble(json['target_weight'] ?? json['target_kg']);

    return WeightMetric(
      startKg: starting,
      currentKg: current,
      targetKg: target,

      // Prefer API value when available.
      // Otherwise calculate from current and starting weight.
      changeKg: json['change_kg'] != null
          ? _toDouble(json['change_kg'])
          : current - starting,

      unit: json['unit']?.toString() ?? 'kg',
    );
  }
}
// ============================================================
// CHART POINT
// ============================================================

class ProgressChartPoint {
  final String label;
  final String date;
  final double calories;
  final double steps;
  final double sleepHours;
  final double waterMl;
  final double weightKg;

  const ProgressChartPoint({
    required this.label,
    required this.date,
    required this.calories,
    required this.steps,
    required this.sleepHours,
    required this.waterMl,
    required this.weightKg,
  });

  factory ProgressChartPoint.fromJson(Map<String, dynamic> json) {
    return ProgressChartPoint(
      label: json['label']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      calories: _toDouble(json['calories']),
      steps: _toDouble(json['steps']),
      sleepHours: _toDouble(json['sleep_hours']),
      waterMl: _toDouble(json['water_ml']),
      weightKg: _toDouble(json['weight_kg']),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

double _toDouble(dynamic value) {
  if (value == null) return 0.0;

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0.0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
}
