import 'package:dio/dio.dart';
import 'package:disha_ai/core/network/api_client.dart';
import 'package:disha_ai/core/network/api_constants.dart';
import '../models/task_model.dart';

class TaskService {
  final Dio _dio = ApiClient.instance.dio;

  // GET /api/tasks (Handles nested data -> tasks structure)
  Future<List<TaskModel>> getTasks() async {
    try {
      final response = await _dio.get(ApiConstants.tasks);
      final data = response.data;
      List<dynamic> list = [];

      if (data is Map) {
        if (data['data'] is Map && data['data']['tasks'] is List) {
          list = data['data']['tasks'];
        } else if (data['tasks'] is List) {
          list = data['tasks'];
        } else if (data['data'] is List) {
          list = data['data'];
        }
      } else if (data is List) {
        list = data;
      }

      return list.map((e) => TaskModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load tasks');
    }
  }

  // POST /api/tasks
  Future<TaskModel> createTask(String title) async {
    try {
      final response = await _dio.post(
        ApiConstants.tasks,
        data: {'title': title},
      );

      final decoded = response.data;
      final itemData = decoded is Map && decoded['data'] != null
          ? (decoded['data'] is Map && decoded['data']['task'] != null
                ? decoded['data']['task']
                : decoded['data'])
          : decoded;

      return TaskModel.fromJson(itemData);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create task');
    }
  }

  // PUT /api/tasks/{id}/complete
  Future<void> toggleTaskComplete(int id) async {
    try {
      await _dio.put('${ApiConstants.tasks}/$id/complete');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update task status',
      );
    }
  }

  // DELETE /api/tasks/{id}
  Future<void> deleteTask(int id) async {
    try {
      await _dio.delete('${ApiConstants.tasks}/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete task');
    }
  }
}
