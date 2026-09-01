class TaskModel {
  final int id;
  final String title;
  final String? description;
  final String? type;
  final bool isCompleted;
  final DateTime? createdAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.type,
    required this.isCompleted,
    this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    String resolvedTitle = '';
    String? resolvedDesc;
    String? resolvedType;

    // 1. Pre-defined task with nested 'task' object
    if (json['task'] is Map) {
      final taskObj = json['task'] as Map;
      resolvedTitle = taskObj['title']?.toString() ?? '';
      resolvedDesc = taskObj['description']?.toString();
      resolvedType = taskObj['type']?.toString();
    }
    // 2. Custom created task with 'custom_title'
    else if (json['custom_title'] != null &&
        json['custom_title'].toString().trim().isNotEmpty) {
      resolvedTitle = json['custom_title'].toString();
      resolvedDesc = "Custom Daily Task";
      resolvedType = "custom";
    }
    // 3. Fallback to normal title
    else if (json['title'] != null) {
      resolvedTitle = json['title'].toString();
    }

    return TaskModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      title: resolvedTitle.isNotEmpty ? resolvedTitle : "Untitled Task",
      description: resolvedDesc,
      type: resolvedType,
      isCompleted:
          json['is_completed'] == true ||
          json['isCompleted'] == true ||
          json['completed'] == true ||
          json['is_completed'].toString() == '1',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
    };
  }

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
