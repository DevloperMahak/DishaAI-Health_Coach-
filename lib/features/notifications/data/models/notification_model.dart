class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final String? timeAgo;
  final Map<String, dynamic>? extraData;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
    this.timeAgo,
    this.extraData,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final dynamic nestedData = json['data'];

    final Map<String, dynamic> data = nestedData is Map
        ? Map<String, dynamic>.from(nestedData)
        : <String, dynamic>{};

    final String body =
        json['body']?.toString() ??
        data['body']?.toString() ??
        json['message']?.toString() ??
        data['message']?.toString() ??
        '';

    final String title =
        json['title']?.toString() ??
        data['title']?.toString() ??
        'Notification';

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      title: title,
      message: body,
      isRead: _parseIsRead(json),
      createdAt: _parseDate(json['created_at']),
      timeAgo: json['time_ago']?.toString(),
      extraData: data.isEmpty ? null : data,
    );
  }

  static bool _parseIsRead(Map<String, dynamic> json) {
    final dynamic value = json['is_read'];

    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }

    // Backward compatibility if backend returns read_at.
    return json['read_at'] != null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString())?.toLocal();
  }

  NotificationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? timeAgo,
    Map<String, dynamic>? extraData,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      timeAgo: timeAgo ?? this.timeAgo,
      extraData: extraData ?? this.extraData,
    );
  }
}
