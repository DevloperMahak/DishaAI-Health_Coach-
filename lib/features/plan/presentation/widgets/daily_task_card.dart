import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:disha_ai/features/dashboard/presentation/controllers/task_controller.dart';
import '../../../../app/theme/app_colors.dart';

class DailyTaskCard extends StatelessWidget {
  DailyTaskCard({super.key});

  final TaskController _taskController = Get.put(TaskController());

  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();

    Get.defaultDialog(
      title: "Add Custom Task",
      titleStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: AppColors.surface,
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: titleController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: "e.g. Evening Walk 20 Mins",
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
            filled: true,
            fillColor: AppColors.background,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () async {
          if (titleController.text.trim().isNotEmpty) {
            final success = await _taskController.createTask(
              titleController.text.trim(),
            );
            Get.back();
            if (success) {
              Get.snackbar(
                "Success",
                "Task created successfully!",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.surface,
                colorText: AppColors.textPrimary,
              );
            }
          }
        },
        child: const Text(
          "Add Task",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text(
          "Cancel",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  IconData _getTaskIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'water':
        return Icons.water_drop_rounded;
      case 'workout':
        return Icons.fitness_center_rounded;
      case 'meal':
        return Icons.restaurant_rounded;
      case 'sleep':
        return Icons.bedtime_rounded;
      case 'custom':
        return Icons.star_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool tablet = width > 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: tablet ? width * .05 : 0),
      padding: EdgeInsets.all(tablet ? 22 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(tablet ? 18 : 14),
        border: Border.all(color: AppColors.primaryDark.withOpacity(.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Tasks",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: tablet ? 22 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showAddTaskDialog(context),
                    icon: const Icon(
                      Icons.add_circle_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    tooltip: "Add Task",
                  ),
                  const SizedBox(width: 4),
                  Obx(() {
                    if (_taskController.isLoading.value) {
                      return const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // LIVE API TASKS OBSERVER
          Obx(() {
            if (_taskController.tasks.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                child: Text(
                  "No tasks scheduled for today. Add one above! ✨",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: tablet ? 15 : 13,
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _taskController.tasks.length,
              itemBuilder: (context, index) {
                final task = _taskController.tasks[index];
                final String subtitleText = task.description ?? "Custom Task";

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Dismissible(
                    key: Key('${task.id}_$index'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onDismissed: (_) {
                      _taskController.deleteTask(task.id);
                      Get.snackbar(
                        "Task Deleted",
                        "Removed successfully.",
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    child: _taskItem(
                      title: task.title,
                      subtitle: subtitleText,
                      icon: _getTaskIcon(task.type),
                      done: task.isCompleted,
                      onTap: () {
                        _taskController.toggleTaskComplete(task.id);
                      },
                      tablet: tablet,
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _taskItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool done,
    required VoidCallback onTap,
    required bool tablet,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              height: tablet ? 48 : 42,
              width: tablet ? 48 : 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(.15),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: tablet ? 26 : 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: tablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: tablet ? 14 : 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              color: done ? AppColors.primary : AppColors.textSecondary,
              size: tablet ? 26 : 22,
            ),
          ],
        ),
      ),
    );
  }
}
