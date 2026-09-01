class TodaySummaryModel {
  final Map<String, dynamic> data;

  TodaySummaryModel({required this.data});

  factory TodaySummaryModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      return TodaySummaryModel(data: json['data'] as Map<String, dynamic>);
    }
    if (json.containsKey('today_summary') &&
        json['today_summary'] is Map<String, dynamic>) {
      return TodaySummaryModel(
        data: json['today_summary'] as Map<String, dynamic>,
      );
    }
    return TodaySummaryModel(data: json);
  }

  String get calories {
    final calMap = _getMap('calories');
    if (calMap.isNotEmpty) {
      final consumed = calMap['consumed'] ?? calMap['current'] ?? 0;
      return consumed.toString();
    }
    return "0";
  }

  String get water {
    final waterMap = _getMap('water');
    if (waterMap.isNotEmpty) {
      final currentMl = waterMap['current_ml'] ?? waterMap['current'] ?? 0;
      final double liters =
          (double.tryParse(currentMl.toString()) ?? 0.0) / 1000;
      return liters > 0 ? liters.toStringAsFixed(1) : currentMl.toString();
    }
    return "0";
  }

  String get steps {
    final stepsMap = _getMap('steps');
    if (stepsMap.isNotEmpty) {
      final current = stepsMap['current'] ?? stepsMap['count'] ?? 0;
      return current.toString();
    }
    return "0";
  }

  String get sleep {
    final sleepMap = _getMap('sleep');
    if (sleepMap.isNotEmpty) {
      final current = sleepMap['current_hours'] ?? sleepMap['current'] ?? 0;
      return current.toString();
    }
    return "0";
  }

  Map<String, dynamic> _getMap(String key) {
    if (data[key] is Map<String, dynamic>) {
      return data[key] as Map<String, dynamic>;
    }
    if (data['today_summary'] is Map<String, dynamic>) {
      final todaySummary = data['today_summary'] as Map<String, dynamic>;
      if (todaySummary[key] is Map<String, dynamic>) {
        return todaySummary[key] as Map<String, dynamic>;
      }
    }
    return {};
  }
}
