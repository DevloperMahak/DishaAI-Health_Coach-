class PaymentOrderModel {
  final String orderId;
  final num amount;
  final String currency;
  final String key; // <-- Added key field

  PaymentOrderModel({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.key,
  });

  factory PaymentOrderModel.fromJson(Map<String, dynamic> json) {
    return PaymentOrderModel(
      orderId: json['order_id']?.toString() ?? json['id']?.toString() ?? '',
      amount: num.tryParse(json['amount']?.toString() ?? '3') ?? 3,
      currency: json['currency']?.toString() ?? 'INR',
      key:
          json['key']?.toString() ??
          'rzp_test_TXVMk5jbyx2sAL', // Fallback key if not provided by backend
    );
  }
}

class HealthReportModel {
  final num healthScore;
  final String averageSleep;
  final String waterIntake;
  final String aiInsights;
  final String period;

  HealthReportModel({
    required this.healthScore,
    required this.averageSleep,
    required this.waterIntake,
    required this.aiInsights,
    required this.period,
  });

  factory HealthReportModel.fromJson(Map<String, dynamic> json) {
    return HealthReportModel(
      healthScore: num.tryParse(json['health_score']?.toString() ?? '0') ?? 0,
      averageSleep: json['average_sleep']?.toString() ?? '7 hrs',
      waterIntake: json['water_intake']?.toString() ?? '2.5 L',
      aiInsights:
          json['ai_insights']?.toString() ??
          'Keep maintaining a balanced lifestyle and hydration.',
      period: json['period']?.toString() ?? 'Summary',
    );
  }
}
