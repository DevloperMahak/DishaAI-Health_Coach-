class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic>? extraData;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
    this.extraData,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Handle Laravel's default nested 'data' object if present
    final dataNode = json['data'] is Map<String, dynamic> ? json['data'] : json;

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: dataNode['title']?.toString() ?? 'Notification',
      message:
          dataNode['message']?.toString() ?? dataNode['body']?.toString() ?? '',
      // If read_at is null, it hasn't been read
      isRead: json['read_at'] != null || json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      extraData: dataNode,
    );
  }
}
