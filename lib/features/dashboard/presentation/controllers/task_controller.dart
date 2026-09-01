import 'package:get/get.dart';
import '../../data/models/task_model.dart';
import '../../data/services/task_service.dart';

class TaskController extends GetxController {
  final TaskService _service = TaskService();

  final RxList<TaskModel> tasks = <TaskModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  // Fetch Tasks Checklist
  Future<void> fetchTasks() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _service.getTasks();
      tasks.assignAll(result);
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  // Create Custom Task
  Future<bool> createTask(String title) async {
    if (title.trim().isEmpty) return false;
    try {
      isLoading.value = true;
      final newTask = await _service.createTask(title.trim());

      // Prevent duplicate entries
      if (!tasks.any((t) => t.id == newTask.id)) {
        tasks.insert(0, newTask);
      }
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle Task Completion
  Future<void> toggleTaskComplete(int id) async {
    final index = tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final original = tasks[index];
      tasks[index] = original.copyWith(isCompleted: !original.isCompleted);
      tasks.refresh();

      try {
        await _service.toggleTaskComplete(id);
      } catch (e) {
        tasks[index] = original;
        tasks.refresh();
        errorMessage.value = 'Failed to update task status';
      }
    }
  }

  // Delete Task Item
  Future<bool> deleteTask(int id) async {
    try {
      await _service.deleteTask(id);
      tasks.removeWhere((t) => t.id == id);
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }
}
