class PaymentOrderModel {
  final String orderId;
  final num amount;
  final String currency;
  final String key;

  PaymentOrderModel({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.key,
  });

  factory PaymentOrderModel.fromJson(Map<String, dynamic> json) {
    final orderId = (json['order_id'] ?? json['id'])?.toString().trim() ?? '';

    final amount = num.tryParse(json['amount']?.toString() ?? '');

    final currency = json['currency']?.toString().trim() ?? 'INR';

    final key = json['key']?.toString().trim() ?? '';

    if (orderId.isEmpty) {
      throw FormatException('Razorpay order ID missing from backend response');
    }

    if (amount == null || amount <= 0) {
      throw FormatException('Invalid Razorpay order amount');
    }

    if (key.isEmpty) {
      throw FormatException('Razorpay key missing from backend response');
    }

    return PaymentOrderModel(
      orderId: orderId,
      amount: amount,
      currency: currency,
      key: key,
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
