import 'package:flutter/foundation.dart';

/// ===============================================================
/// Water Log Model
/// ---------------------------------------------------------------
/// Used for:
/// - Today's water timeline
/// - Dashboard summary
/// - Weekly analytics
/// - AI hydration insights
/// - Backend API integration
/// ===============================================================

@immutable
class WaterLogModel {
  final String id;

  /// User ID
  final String userId;

  /// Water consumed (ml)
  final int amount;

  /// Date & Time of intake
  final DateTime loggedAt;

  /// Optional note
  final String? note;

  /// Intake source
  /// glass | bottle | custom
  final WaterSource source;

  /// Whether synced with server
  final bool isSynced;

  /// Creation time
  final DateTime createdAt;

  /// Updated time
  final DateTime updatedAt;

  const WaterLogModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.loggedAt,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.isSynced = false,
  });

  //---------------------------------------------------------------
  // Empty Model
  //---------------------------------------------------------------

  factory WaterLogModel.empty() {
    final now = DateTime.now();

    return WaterLogModel(
      id: '',
      userId: '',
      amount: 0,
      loggedAt: now,
      source: WaterSource.custom,
      createdAt: now,
      updatedAt: now,
    );
  }

  //---------------------------------------------------------------
  // CopyWith
  //---------------------------------------------------------------

  WaterLogModel copyWith({
    String? id,
    String? userId,
    int? amount,
    DateTime? loggedAt,
    String? note,
    WaterSource? source,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaterLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      loggedAt: loggedAt ?? this.loggedAt,
      note: note ?? this.note,
      source: source ?? this.source,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  //---------------------------------------------------------------
  // JSON Serialization
  //---------------------------------------------------------------

  factory WaterLogModel.fromJson(Map<String, dynamic> json) {
    return WaterLogModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      amount: json['amount'] ?? 0,
      loggedAt: DateTime.parse(json['loggedAt']),
      note: json['note'],
      source: WaterSource.values.firstWhere(
        (e) => describeEnum(e) == json['source'],
        orElse: () => WaterSource.custom,
      ),
      isSynced: json['isSynced'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "userId": userId,
      "amount": amount,
      "loggedAt": loggedAt.toIso8601String(),
      "note": note,
      "source": describeEnum(source),
      "isSynced": isSynced,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
    };
  }

  //---------------------------------------------------------------
  // Helpers
  //---------------------------------------------------------------

  bool get isToday {
    final now = DateTime.now();

    return loggedAt.year == now.year &&
        loggedAt.month == now.month &&
        loggedAt.day == now.day;
  }

  String get amountLabel => "$amount ml";

  //---------------------------------------------------------------
  // Equality
  //---------------------------------------------------------------

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

///
/// Source of water intake
///
enum WaterSource { glass, bottle, custom }
