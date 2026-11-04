import 'package:flutter/foundation.dart';

/// ===============================================================
/// Water Log Model
/// ---------------------------------------------------------------
/// Represents a single water intake entry returned by:
///
/// GET  /api/water-log
/// POST /api/water-log -> data.entry
///
/// API example:
/// {
///   "id": 14,
///   "amount_ml": 500,
///   "time": "11:30 AM",
///   "logged_at": "2026-09-29T11:30:00.000000Z"
/// }
/// ===============================================================

@immutable
class WaterLogModel {
  final String id;
  final int amount;
  final DateTime loggedAt;
  final String time;

  const WaterLogModel({
    required this.id,
    required this.amount,
    required this.loggedAt,
    required this.time,
  });

  /// Empty model
  factory WaterLogModel.empty() {
    return WaterLogModel(id: '', amount: 0, loggedAt: DateTime.now(), time: '');
  }

  /// =============================================================
  /// API JSON
  /// =============================================================

  factory WaterLogModel.fromJson(Map<String, dynamic> json) {
    final rawLoggedAt = json['logged_at'];

    DateTime loggedAt;

    if (rawLoggedAt != null && rawLoggedAt.toString().trim().isNotEmpty) {
      loggedAt = DateTime.tryParse(rawLoggedAt.toString()) ?? DateTime.now();
    } else {
      loggedAt = DateTime.now();
    }

    return WaterLogModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      amount: _toInt(json['amount_ml'] ?? json['amount']),
      loggedAt: loggedAt,
      time: json['time']?.toString() ?? '',
    );
  }

  /// =============================================================
  /// JSON
  /// =============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount_ml': amount,
      'time': time,
      'logged_at': loggedAt.toIso8601String(),
    };
  }

  /// =============================================================
  /// Helpers
  /// =============================================================

  bool get isToday {
    final now = DateTime.now();

    return loggedAt.year == now.year &&
        loggedAt.month == now.month &&
        loggedAt.day == now.day;
  }

  String get amountLabel => '$amount ml';

  WaterLogModel copyWith({
    String? id,
    int? amount,
    DateTime? loggedAt,
    String? time,
  }) {
    return WaterLogModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      loggedAt: loggedAt ?? this.loggedAt,
      time: time ?? this.time,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WaterLogModel &&
            runtimeType == other.runtimeType &&
            id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// ===============================================================
/// Daily Water Summary
/// ---------------------------------------------------------------
/// Returned from:
/// GET /api/water-log
/// POST /api/water-log -> data
/// DELETE /api/water-log/{id} -> data
/// ===============================================================

@immutable
class WaterDailySummary {
  final String date;
  final int consumedMl;
  final int targetMl;
  final int remainingMl;
  final double progressPercentage;
  final String unit;
  final List<WaterLogModel> logs;

  const WaterDailySummary({
    required this.date,
    required this.consumedMl,
    required this.targetMl,
    required this.remainingMl,
    required this.progressPercentage,
    required this.unit,
    this.logs = const [],
  });

  factory WaterDailySummary.empty() {
    return const WaterDailySummary(
      date: '',
      consumedMl: 0,
      targetMl: 2500,
      remainingMl: 2500,
      progressPercentage: 0,
      unit: 'ml',
      logs: [],
    );
  }

  factory WaterDailySummary.fromJson(Map<String, dynamic> json) {
    final rawLogs = json['logs'];

    final logs = <WaterLogModel>[];

    if (rawLogs is List) {
      for (final item in rawLogs) {
        if (item is Map) {
          logs.add(WaterLogModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return WaterDailySummary(
      date: json['date']?.toString() ?? '',
      consumedMl: _toInt(json['consumed_ml']),
      targetMl: _toInt(json['target_ml']),
      remainingMl: _toInt(json['remaining_ml']),
      progressPercentage: _toDouble(json['progress_percentage']),
      unit: json['unit']?.toString() ?? 'ml',
      logs: logs,
    );
  }

  WaterDailySummary copyWith({
    String? date,
    int? consumedMl,
    int? targetMl,
    int? remainingMl,
    double? progressPercentage,
    String? unit,
    List<WaterLogModel>? logs,
  }) {
    return WaterDailySummary(
      date: date ?? this.date,
      consumedMl: consumedMl ?? this.consumedMl,
      targetMl: targetMl ?? this.targetMl,
      remainingMl: remainingMl ?? this.remainingMl,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      unit: unit ?? this.unit,
      logs: logs ?? this.logs,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
