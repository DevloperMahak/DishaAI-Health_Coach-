class DashboardModel {
  final Map<String, dynamic> data;

  DashboardModel({required this.data});

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(data: json);
  }
}
