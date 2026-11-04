import 'package:disha_ai/core/storage/step_storage.dart';
import 'package:disha_ai/features/dashboard/presentation/screens/meals/meals_home_screen.dart';
import 'package:disha_ai/features/dashboard/presentation/screens/sleep_checkin_screen.dart';
import 'package:disha_ai/features/dashboard/presentation/screens/steps_checkin_screen.dart';
import 'package:disha_ai/features/progress/presentation/controller/progress_controller.dart';
import 'package:disha_ai/features/water_tracker/presentation/screens/water_tracker_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ============================================================
// NAVIGATION SCREENS
// ============================================================

// ============================================================
// EXISTING IMPORTS
// ============================================================

import '../controllers/dashboard_controller.dart';
import 'metric_card.dart';
import 'section_header.dart';

class TodayOverviewSection extends StatelessWidget {
  const TodayOverviewSection({super.key});

  // ============================================================
  // NAVIGATION METHODS
  // ============================================================

  void _openCalories() {
    Get.to(
      () => const MealsHomeScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 250),
    );
  }

  void _openWater() {
    Get.to(
      () => WaterTrackerScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 250),
    );
  }

  void _openSteps() {
    Get.to(
      () => const StepsCheckinScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 250),
    );
  }

  void _openSleep() {
    Get.to(
      () => const SleepCheckinScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 250),
    );
  }

  // ============================================================
  // CLICKABLE METRIC CARD
  // ============================================================

  Widget _buildClickableMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required double progress,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: MetricCard(
          title: title,
          value: value,
          unit: unit,
          icon: icon,
          color: color,
          progress: progress,
        ),
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final DashboardController dashboardController =
        Get.find<DashboardController>();

    final ProgressController progressController =
        Get.isRegistered<ProgressController>()
        ? Get.find<ProgressController>()
        : Get.put(ProgressController());

    return Obx(() {
      final summary = dashboardController.todaySummary.value;

      // ============================================================
      // CALORIES
      //
      // Keep the same calorie source as ProgressScreen.
      // ProgressController -> Progress API -> calories.average
      // ============================================================

      final String calories = progressController.caloriesDisplay;

      // ============================================================
      // STEPS
      //
      // Keep existing live step tracking logic.
      // ============================================================

      final int liveSteps = StepStorage.instance.todaySteps;

      final String steps = liveSteps > 0
          ? liveSteps.toString()
          : (summary?.steps ?? "0");

      // ============================================================
      // WATER
      // ============================================================

      final String water = summary?.water ?? "0";

      // ============================================================
      // SLEEP
      // ============================================================

      final String sleep = summary?.sleep ?? "0";

      // ============================================================
      // PROGRESS CALCULATIONS
      // ============================================================

      final double calorieProgress = _calculateProgress(
        calories,
        progressController.caloriesTarget > 0
            ? progressController.caloriesTarget
            : 2000,
      );

      final double waterProgress = _calculateProgress(water, 3.0);

      final double stepProgress = _calculateProgress(steps, 10000);

      final double sleepProgress = _calculateProgress(sleep, 8.0);

      // ============================================================
      // UI
      // ============================================================

      return Column(
        children: [
          const SectionHeader(
            title: "Today's Overview",
            subtitle: "Track your daily health progress",
          ),

          const SizedBox(height: 18),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: .95,
            children: [
              // ======================================================
              // CALORIES -> MEALS HOME SCREEN
              // ======================================================
              _buildClickableMetricCard(
                title: "Calories",
                value: calories,
                unit: "kcal",
                icon: Icons.local_fire_department,
                color: Colors.orange,
                progress: calorieProgress,
                onTap: _openCalories,
              ),

              // ======================================================
              // WATER -> WATER TRACKER SCREEN
              // ======================================================
              _buildClickableMetricCard(
                title: "Water",
                value: water,
                unit: "L",
                icon: Icons.water_drop,
                color: Colors.blue,
                progress: waterProgress,
                onTap: _openWater,
              ),

              // ======================================================
              // STEPS -> STEPS CHECK-IN SCREEN
              // ======================================================
              _buildClickableMetricCard(
                title: "Steps",
                value: steps,
                unit: "",
                icon: Icons.directions_walk,
                color: Colors.green,
                progress: stepProgress,
                onTap: _openSteps,
              ),

              // ======================================================
              // SLEEP -> SLEEP CHECK-IN SCREEN
              // ======================================================
              _buildClickableMetricCard(
                title: "Sleep",
                value: sleep,
                unit: "hrs",
                icon: Icons.bedtime,
                color: Colors.deepPurple,
                progress: sleepProgress,
                onTap: _openSleep,
              ),
            ],
          ),
        ],
      );
    });
  }

  // ============================================================
  // PROGRESS CALCULATION
  // ============================================================

  double _calculateProgress(String valStr, double target) {
    final double val =
        double.tryParse(valStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    if (target <= 0) {
      return 0.0;
    }

    return (val / target).clamp(0.0, 1.0);
  }
}
