import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/weekly_progress_controller.dart';
import '../../data/models/weekly_progress_model.dart';
import 'section_header.dart';
import 'weekly_bar.dart';

class WeeklyProgressCard extends StatefulWidget {
  const WeeklyProgressCard({super.key});

  @override
  State<WeeklyProgressCard> createState() => _WeeklyProgressCardState();
}

class _WeeklyProgressCardState extends State<WeeklyProgressCard> {
  late final WeeklyProgressController _controller;

  @override
  void initState() {
    super.initState();

    _controller = Get.isRegistered<WeeklyProgressController>()
        ? Get.find<WeeklyProgressController>()
        : Get.put(WeeklyProgressController());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(
          title: "Weekly Progress",
          subtitle: "Last 7 days activity",
        ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(.15)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Obx(() {
            if (_controller.isLoading.value && _controller.days.isEmpty) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (_controller.errorMessage.value.isNotEmpty &&
                _controller.days.isEmpty) {
              return _buildErrorState();
            }

            if (_controller.days.isEmpty) {
              return _buildEmptyState();
            }

            return _buildContent();
          }),
        ),
      ],
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return Column(
      children: [
        //--------------------------------------------------------
        // TOP STATS
        //--------------------------------------------------------
        Row(
          children: [
            Expanded(
              child: _Stat(
                title: "Calories",
                value: _formatCalories(_controller.selectedCalories),
                color: Colors.orange,
                icon: Icons.local_fire_department_rounded,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _Stat(
                title: "Steps",
                value: _formatSteps(_controller.selectedSteps),
                color: Colors.green,
                icon: Icons.directions_walk_rounded,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _Stat(
                title: "Water",
                value: _formatWater(_controller.selectedWaterMl),
                color: Colors.blue,
                icon: Icons.water_drop_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        //--------------------------------------------------------
        // SELECTED DAY INFO
        //--------------------------------------------------------
        if (_controller.selectedDay.value != null)
          Text(
            _selectedDateLabel(_controller.selectedDay.value!),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),

        const SizedBox(height: 22),

        //--------------------------------------------------------
        // CHART
        //--------------------------------------------------------
        SizedBox(height: 145, child: _buildWeeklyChart()),
      ],
    );
  }

  // ============================================================
  // WEEKLY CHART
  // ============================================================

  Widget _buildWeeklyChart() {
    final days = _controller.days;

    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(days.length, (index) {
        final day = days[index];

        final bool selected = _controller.selectedDay.value?.date == day.date;

        // ==========================================================
        // SAFELY NORMALIZE CALORIE PROGRESS
        // ==========================================================

        double barValue = day.calorieProgress;

        if (!barValue.isFinite) {
          barValue = 0.0;
        }

        barValue = barValue.clamp(0.0, 1.0);

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _controller.selectDay(day);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: WeeklyBar(
                day: day.shortDay,
                value: barValue,
                color: Colors.orange,
                selected: selected,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: AppColors.textSecondary,
            ),

            const SizedBox(height: 12),

            Text(
              _controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 14),

            TextButton.icon(
              onPressed: _controller.refreshWeeklyProgress,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return const SizedBox(
      height: 220,
      child: Center(
        child: Text(
          "No weekly progress data available",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ),
    );
  }

  // ============================================================
  // FORMATTING
  // ============================================================

  String _formatCalories(double calories) {
    if (calories >= 1000) {
      return '${(calories / 1000).toStringAsFixed(1)}k';
    }

    return calories.round().toString();
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }

    return steps.toString();
  }

  String _formatWater(double waterMl) {
    final liters = waterMl / 1000;

    if (liters >= 10) {
      return '${liters.toStringAsFixed(0)}L';
    }

    if (liters == liters.roundToDouble()) {
      return '${liters.toInt()}L';
    }

    return '${liters.toStringAsFixed(1)}L';
  }

  String _selectedDateLabel(WeeklyDayProgress day) {
    if (day.isToday) {
      return "Today • ${day.date}";
    }

    return "${day.day} • ${day.date}";
  }
}

// ================================================================
// STAT WIDGET
// ================================================================

class _Stat extends StatelessWidget {
  const _Stat({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(.15),
          child: Icon(icon, color: color, size: 18),
        ),

        const SizedBox(height: 10),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          title,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
