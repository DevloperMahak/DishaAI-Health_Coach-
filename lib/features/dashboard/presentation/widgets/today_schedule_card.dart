import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:disha_ai/features/dashboard/presentation/controllers/task_controller.dart';
import '../../../../app/theme/app_colors.dart';
import 'schedule_item.dart';
import 'section_header.dart';

class TodayScheduleCard extends StatelessWidget {
  TodayScheduleCard({super.key});

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
                "Task added successfully!",
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: SectionHeader(
                  title: "Today's Schedule",
                  subtitle: "Stay on track with your plan",
                ),
              ),
              IconButton(
                onPressed: () => _showAddTaskDialog(context),
                icon: const Icon(
                  Icons.add_circle_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                tooltip: "Add Custom Task",
              ),
            ],
          ),
          const SizedBox(height: 12),

          // OBSERVER WIDGET FOR API TASKS LIST
          Obx(() {
            if (_taskController.isLoading.value &&
                _taskController.tasks.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (_taskController.tasks.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                child: const Text(
                  "No tasks scheduled for today. Add one above! ✨",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
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

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Dismissible(
                    key: Key(task.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
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
                    child: ScheduleItem(
                      title: task
                          .title, // task.title ab safely resolved hai model se
                      time: "Today",
                      icon: Icons.task_alt_rounded,
                      color: task.isCompleted
                          ? Colors.green
                          : AppColors.primary,
                      completed: task.isCompleted,
                      onTap: () {
                        _taskController.toggleTaskComplete(task.id);
                      },
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
}
