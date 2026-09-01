import 'package:disha_ai/features/onboarding/presentation/controllers/health_nutrition_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:disha_ai/app/routes/app_routes.dart';
import 'package:disha_ai/app/theme/app_colors.dart';
import 'package:disha_ai/features/dashboard/presentation/widgets/dashboard_bottom_nav_bar.dart';
import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:disha_ai/features/progress/presentation/widgets/ai_progress_insight_card.dart';
import 'package:disha_ai/features/progress/presentation/widgets/bmi_ProgressCard.dart';
import 'package:disha_ai/features/progress/presentation/widgets/daily_habits_card.dart';
import 'package:disha_ai/features/progress/presentation/widgets/overall_health_score_card.dart';
import 'package:disha_ai/features/progress/presentation/widgets/quick_health_metrics.dart';
import 'package:disha_ai/features/progress/presentation/widgets/weekly_goal_progress.dart';
import 'package:disha_ai/features/progress/presentation/widgets/weight_progress_card.dart';
import 'package:disha_ai/features/progress/presentation/widgets/weight_progress_chart.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/progress_header.dart';
import '../widgets/achievement_section.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================
  final AiController _aiController = Get.put(AiController());
  final HealthProfileController _healthProfileController = Get.put(
    HealthProfileController(),
  );
  final HealthNutritionController _healthNutritionController = Get.put(
    HealthNutritionController(),
  ); // <--- Initialized

  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgressData();
    });
  }

  Future<void> _loadProgressData() async {
    await Future.wait([
      _healthProfileController.getHealthProfile(),
      _aiController.analyzeProfile(),
      _healthNutritionController
          .fetchAllData(), // <--- Fetches live health logs and nutrition
    ]);
  }

  Future<void> _refreshProgress() async {
    await _loadProgressData();
  }

  // ============================================================
  // DYNAMIC PARSERS FROM API
  // ============================================================

  Map<String, dynamic>? get _analysisData {
    final rawData = _aiController.profileAnalysis.value?.data;
    if (rawData is Map<String, dynamic>) {
      if (rawData['analysis'] is Map<String, dynamic>) {
        return rawData['analysis'] as Map<String, dynamic>;
      }
      return rawData;
    }
    return null;
  }

  double get _currentBmi {
    final bmi = _analysisData?['bmi'] ?? _analysisData?['BMI'];
    if (bmi != null) return double.tryParse(bmi.toString()) ?? 23.5;
    return 23.5;
  }

  String get _bmiCategory {
    return _analysisData?['health_category']?.toString() ??
        _analysisData?['bmi_category']?.toString() ??
        "Healthy";
  }

  double get _currentWeight {
    // Prioritize live health logs weight if available, else fallback to profile
    final logWeight = _healthNutritionController.healthLog.value?.weightKg;
    if (logWeight != null && logWeight > 0) return logWeight;

    final profile = _healthProfileController.healthProfile.value;
    return profile?.weightKg ?? 65.0;
  }

  double get _targetWeight {
    final profile = _healthProfileController.healthProfile.value;
    return profile?.targetWeightKg ?? 58.0;
  }

  double get _startingWeight {
    return _currentWeight + 4.0;
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Get.offNamed(AppRoutes.dashboard);
        break;
      case 1:
        Get.offNamed(AppRoutes.myPlan);
        break;
      case 2:
        Get.offNamed(AppRoutes.progress);
        break;
      case 3:
        Get.offNamed(AppRoutes.aiCoach);
        break;
      case 4:
        Get.offNamed(AppRoutes.profile);
        break;
    }
  }

  double _horizontalPadding(double width) {
    if (width <= 360) return 16;
    if (width <= 430) return 20;
    if (width <= 700) return 24;
    return 30;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: DashboardBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavigationTap,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final padding = _horizontalPadding(width);

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: _refreshProgress,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(padding, 18, padding, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // TOP BAR
                        ProgressAppBar(
                          selectedPeriod: "This Week",
                          onPeriodChanged: (value) {},
                        ),

                        const SizedBox(height: 26),

                        const QuickHealthMetrics(),

                        const SizedBox(height: 24),

                        // DYNAMIC WEIGHT PROGRESS CARD
                        Obx(
                          () => WeightProgressCard(
                            startingWeight: _startingWeight,
                            currentWeight: _currentWeight,
                            targetWeight: _targetWeight,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // WEIGHT PROGRESS CHART
                        Obx(
                          () => WeightProgressChart(
                            currentWeight: _currentWeight,
                            goalWeight: _targetWeight,
                            spots: [
                              FlSpot(0, _startingWeight),
                              FlSpot(1, _startingWeight - 0.8),
                              FlSpot(2, _startingWeight - 1.5),
                              FlSpot(3, _startingWeight - 2.2),
                              FlSpot(4, _currentWeight + 1.2),
                              FlSpot(5, _currentWeight + 0.5),
                              FlSpot(6, _currentWeight),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // DYNAMIC BMI PROGRESS CARD
                        Obx(
                          () => BMIProgressCard(
                            bmi: _currentBmi,
                            category: _bmiCategory,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // OVERALL HEALTH SCORE CARD
                        const OverallHealthScoreCard(
                          healthScore: 87,
                          weeklyImprovement: 6,
                          status: "Excellent",
                        ),

                        const SizedBox(height: 22),

                        // WEEKLY GOALS (Connected via controller data if needed)
                        WeeklyGoalProgress(
                          goals: const [
                            WeeklyGoalModel(
                              title: "Workout",
                              icon: Icons.fitness_center_rounded,
                              current: 5,
                              target: 7,
                            ),
                            WeeklyGoalModel(
                              title: "Water Intake",
                              icon: Icons.water_drop_rounded,
                              current: 18,
                              target: 21,
                            ),
                            WeeklyGoalModel(
                              title: "Sleep",
                              icon: Icons.bedtime_rounded,
                              current: 6,
                              target: 7,
                            ),
                            WeeklyGoalModel(
                              title: "Steps",
                              icon: Icons.directions_walk_rounded,
                              current: 62000,
                              target: 70000,
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        const DailyHabitsCard(),

                        const SizedBox(height: 22),

                        const AchievementSection(),

                        const SizedBox(height: 22),

                        const ProgressInsightsCard(),

                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
