import 'package:disha_ai/features/plan/presentation/controllers/today_progress_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class TodayProgressCard extends StatefulWidget {
  const TodayProgressCard({super.key});

  @override
  State<TodayProgressCard> createState() => _TodayProgressCardState();
}

class _TodayProgressCardState extends State<TodayProgressCard> {
  late final TodayProgressController _controller;

  @override
  void initState() {
    super.initState();

    _controller = Get.isRegistered<TodayProgressController>()
        ? Get.find<TodayProgressController>()
        : Get.put(TodayProgressController());
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bool tablet = width > 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: tablet ? width * .05 : 0),
      padding: EdgeInsets.all(tablet ? 24 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(tablet ? 18 : 14),
        border: Border.all(color: AppColors.primaryDark.withOpacity(.6)),
      ),
      child: Obx(() {
        // ------------------------------------------------------
        // LOADING
        // ------------------------------------------------------

        if (_controller.isLoading.value &&
            _controller.todayProgress.value == null) {
          return SizedBox(
            height: tablet ? 90 : 75,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // ------------------------------------------------------
        // ERROR
        // ------------------------------------------------------

        if (_controller.errorMessage.value.isNotEmpty &&
            _controller.todayProgress.value == null) {
          return _buildErrorState(tablet);
        }

        // ------------------------------------------------------
        // NORMAL CONTENT
        // ------------------------------------------------------

        final progress = _controller.progress;
        final percentage = _controller.percentageText;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Progress",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: tablet ? 22 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _controller.taskProgressText,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: tablet ? 16 : 13,
                    ),
                  ),

                  const SizedBox(height: 16),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: tablet ? 10 : 8,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _controller.pendingTasks == 0 && _controller.totalTasks > 0
                        ? "All tasks completed! 🎉"
                        : "${_controller.pendingTasks} pending",
                    style: TextStyle(
                      color:
                          _controller.pendingTasks == 0 &&
                              _controller.totalTasks > 0
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: tablet ? 13 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            SizedBox(
              height: tablet ? 90 : 75,
              width: tablet ? 90 : 75,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: tablet ? 9 : 7,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                  ),

                  Text(
                    percentage,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: tablet ? 20 : 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(bool tablet) {
    return SizedBox(
      height: tablet ? 90 : 75,
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.textSecondary),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              _controller.errorMessage.value,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: tablet ? 14 : 12,
              ),
            ),
          ),

          IconButton(
            onPressed: _controller.refreshTodayProgress,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
