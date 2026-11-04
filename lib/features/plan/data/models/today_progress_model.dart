class TodayProgressModel {
  final String date;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final double progressPercentage;

  const TodayProgressModel({
    required this.date,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.progressPercentage,
  });

  factory TodayProgressModel.fromJson(Map<String, dynamic> json) {
    return TodayProgressModel(
      date: json['date']?.toString() ?? '',
      totalTasks: _toInt(json['total_tasks']),
      completedTasks: _toInt(json['completed_tasks']),
      pendingTasks: _toInt(json['pending_tasks']),
      progressPercentage: _toDouble(json['progress_percentage']),
    );
  }

  double get progress {
    return (progressPercentage / 100).clamp(0.0, 1.0);
  }

  String get percentageText {
    if (progressPercentage == progressPercentage.roundToDouble()) {
      return '${progressPercentage.toInt()}%';
    }

    return '${progressPercentage.toStringAsFixed(1)}%';
  }

  String get taskProgressText {
    return '$completedTasks / $totalTasks Tasks Completed';
  }
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

double _toDouble(dynamic value) {
  if (value == null) return 0.0;

  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0.0;
}
