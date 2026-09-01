import 'package:disha_ai/features/onboarding/presentation/controllers/health_nutrition_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import 'package:disha_ai/features/water_tracker/presentation/widgets/custom_water_bottom_sheet.dart';
import 'package:disha_ai/features/water_tracker/presentation/widgets/todays_water_timeline.dart';

import '../widgets/water_header.dart';
import '../widgets/water_progress_card.dart';
import '../widgets/quick_add_water.dart';
import '../widgets/hydration_ai_card.dart';
import '../widgets/weekly_water_chart.dart';
import '../widgets/hydration_statistics.dart';
import '../widgets/reminder_card.dart';

class WaterTrackerScreen extends StatelessWidget {
  WaterTrackerScreen({super.key});

  final HealthNutritionController _healthController = Get.put(
    HealthNutritionController(),
  );

  Future<void> _onRefresh() async {
    await _healthController.fetchHealthLogs();
  }

  Future<void> _addWater(int mlToAdd) async {
    final currentSteps = _healthController.healthLog.value?.steps ?? 0;
    final currentSleep = _healthController.healthLog.value?.sleepHours ?? 7.5;
    final currentCalories =
        _healthController.healthLog.value?.caloriesConsumed ?? 1800;
    final currentBurned =
        _healthController.healthLog.value?.caloriesBurned ?? 350;
    final currentWeight = _healthController.healthLog.value?.weightKg ?? 58.0;

    final success = await _healthController.postHealthMetrics(
      steps: currentSteps,
      sleepHours: currentSleep,
      caloriesConsumed: currentCalories,
      caloriesBurned: currentBurned,
      weightKg: currentWeight,
      mood: _healthController.healthLog.value?.mood ?? "energetic",
      stressLevel: _healthController.healthLog.value?.stressLevel ?? "low",
    );

    if (success) {
      Get.snackbar(
        "Water Logged",
        "Successfully added $mlToAdd ml of water!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final bool isTablet = width >= 700 || width > height;

            if (isTablet) {
              return _buildTabletLayout(width: width, height: height);
            }

            return _buildPhoneLayout(width: width, height: height);
          },
        ),
      ),
    );
  }

  //-------------------------------------------------------------
  // Phone Layout
  //-------------------------------------------------------------

  Widget _buildPhoneLayout({required double width, required double height}) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WaterHeader(goal: 2500, current: 1800, onBack: () => Get.back()),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding(width),
                vertical: 20,
              ),
              child: Column(
                children: [
                  WaterProgressCard(
                    currentIntake: 1800,
                    dailyGoal: 2500,
                    progress: 0.72,
                    percentage: 72,
                  ),
                  const SizedBox(height: 24),
                  QuickAddWater(
                    onAdd100: () => _addWater(100),
                    onAdd250: () => _addWater(250),
                    onAdd500: () => _addWater(500),
                    onCustomTap: () {
                      Get.bottomSheet(
                        CustomWaterBottomSheet(
                          onAdd: (amount) => _addWater(amount),
                        ),
                        isScrollControlled: true,
                        backgroundColor: AppColors.background,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  HydrationAICard(
                    message:
                        "Your hydration levels are steady today. Keep sipping!",
                    hydrationScore: 85,
                  ),
                  const SizedBox(height: 24),
                  TodaysWaterTimeline(logs: const []),
                  const SizedBox(height: 24),
                  WeeklyWaterChart(),
                  const SizedBox(height: 24),
                  HydrationStatistics(
                    averageWater: 2200,
                    bestWater: 2800,
                    streak: 5,
                    score: 85,
                  ),
                  const SizedBox(height: 24),
                  ReminderCard(
                    enabled: true,
                    interval: 120,
                    onToggle: (val) {},
                    onIntervalChanged: (val) {},
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //-------------------------------------------------------------
  // Tablet Layout
  //-------------------------------------------------------------

  Widget _buildTabletLayout({required double width, required double height}) {
    final horizontalPaddingVal = width >= 1400
        ? 120.0
        : width >= 1100
        ? 80.0
        : 40.0;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPaddingVal,
                24,
                horizontalPaddingVal,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WaterHeader(
                    goal: 2500,
                    current: 1800,
                    onBack: () => Get.back(),
                  ),
                  const SizedBox(height: 30),
                  WaterProgressCard(
                    currentIntake: 1800,
                    dailyGoal: 2500,
                    progress: 0.72,
                    percentage: 72,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            QuickAddWater(
                              onAdd100: () => _addWater(100),
                              onAdd250: () => _addWater(250),
                              onAdd500: () => _addWater(500),
                              onCustomTap: () {},
                            ),
                            const SizedBox(height: 24),
                            TodaysWaterTimeline(logs: const []),
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            HydrationAICard(
                              message:
                                  "Your hydration levels are steady today. Keep sipping!",
                              hydrationScore: 85,
                            ),
                            const SizedBox(height: 24),
                            WeeklyWaterChart(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double horizontalPadding(double width) {
    if (width <= 340) return 16;
    if (width <= 380) return 20;
    if (width <= 430) return 22;
    if (width <= 600) return 24;
    if (width <= 900) return 32;
    return 40;
  }
}
