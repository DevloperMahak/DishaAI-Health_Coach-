class ReviewModel {
  final int id;
  final String category;
  final String message;
  final String? attachmentUrl;
  final String status;
  final DateTime? createdAt;

  const ReviewModel({
    required this.id,
    required this.category,
    required this.message,
    required this.attachmentUrl,
    required this.status,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: _toInt(json['id']),
      category: json['category']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      attachmentUrl: _nullableString(json['attachment_url']),
      status: json['status']?.toString() ?? '',
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty || text == 'null') {
      return null;
    }

    return text;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
