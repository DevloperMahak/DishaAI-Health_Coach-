class MasterDataResponse {
  final bool? success;
  final MasterDataModel? data;

  MasterDataResponse({this.success, this.data});

  factory MasterDataResponse.fromJson(Map<String, dynamic> json) {
    return MasterDataResponse(
      success: json['success'],
      data: json['data'] != null
          ? MasterDataModel.fromJson(json['data'])
          : null,
    );
  }
}

class MasterDataModel {
  final List<GoalItem> goals;
  final List<ConditionItem> conditions;
  final List<TaskItem> tasks;

  MasterDataModel({
    this.goals = const [],
    this.conditions = const [],
    this.tasks = const [],
  });

  factory MasterDataModel.fromJson(Map<String, dynamic> json) {
    return MasterDataModel(
      goals:
          (json['goals'] as List?)?.map((e) => GoalItem.fromJson(e)).toList() ??
          [],
      conditions:
          (json['conditions'] as List?)
              ?.map((e) => ConditionItem.fromJson(e))
              .toList() ??
          [],
      tasks:
          (json['tasks'] as List?)?.map((e) => TaskItem.fromJson(e)).toList() ??
          [],
    );
  }
}

class GoalItem {
  final int? id;
  final String? name;
  final String? slug;
  final String? description;
  final String? icon;

  GoalItem({this.id, this.name, this.slug, this.description, this.icon});

  factory GoalItem.fromJson(Map<String, dynamic> json) {
    return GoalItem(
      id: json['id'],
      name: json['name']?.toString(),
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      icon: json['icon']?.toString(),
    );
  }
}

class ConditionItem {
  final int? id;
  final String? name;
  final String? slug;
  final String? description;

  ConditionItem({this.id, this.name, this.slug, this.description});

  factory ConditionItem.fromJson(Map<String, dynamic> json) {
    return ConditionItem(
      id: json['id'],
      name: json['name']?.toString(),
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

class TaskItem {
  final int? id;
  final String? title;
  final String? description;

  TaskItem({this.id, this.title, this.description});

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'],
      title: json['title']?.toString(),
      description: json['description']?.toString(),
    );
  }
}
