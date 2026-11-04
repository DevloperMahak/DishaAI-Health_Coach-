import 'package:disha_ai/features/onboarding/presentation/controllers/health_nutrition_controller.dart';
import 'package:disha_ai/features/payment/presentation/controllers/premium_report_controller.dart';
import 'package:disha_ai/features/progress/presentation/controller/progress_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:disha_ai/app/routes/app_routes.dart';
import 'package:disha_ai/app/theme/app_colors.dart';

import 'package:disha_ai/features/dashboard/presentation/widgets/dashboard_bottom_nav_bar.dart';

import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';

import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';

import 'package:disha_ai/features/dashboard/presentation/controllers/dashboard_controller.dart';

import 'package:disha_ai/features/authentication/presentation/controllers/auth_controller.dart';

import 'package:disha_ai/features/progress/presentation/widgets/ai_progress_insight_card.dart';
import 'package:disha_ai/features/progress/presentation/widgets/bmi_ProgressCard.dart';
import 'package:disha_ai/features/progress/presentation/widgets/daily_habits_card.dart';
import 'package:disha_ai/features/progress/presentation/widgets/overall_health_score_card.dart';
import 'package:disha_ai/features/progress/presentation/widgets/quick_health_metrics.dart';
import 'package:disha_ai/features/progress/presentation/widgets/weekly_goal_progress.dart';
import 'package:disha_ai/features/progress/presentation/widgets/weight_progress_card.dart';
import 'package:disha_ai/features/progress/presentation/widgets/weight_progress_chart.dart';
import 'package:disha_ai/features/dashboard/presentation/widgets/banner_carousel.dart';
import '../widgets/progress_header.dart';

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
  );

  final PremiumReportController _premiumReportController = Get.put(
    PremiumReportController(),
  );

  final DashboardController _dashboardController =
      Get.isRegistered<DashboardController>()
      ? Get.find<DashboardController>()
      : Get.put(DashboardController());

  final ProgressController _progressController =
      Get.isRegistered<ProgressController>()
      ? Get.find<ProgressController>()
      : Get.put(ProgressController());

  // ============================================================
  // OPTIONAL PROGRESS BANNER
  // ============================================================

  final GlobalKey<BannerCarouselState> _progressBannerKey =
      GlobalKey<BannerCarouselState>();

  bool _hasProgressBanners = false;

  // Update the layout only when banner visibility changes.
  void _onProgressBannerVisibilityChanged(bool visible) {
    if (!mounted || _hasProgressBanners == visible) return;

    setState(() {
      _hasProgressBanners = visible;
    });
  }
  // ============================================================
  // AUTH CONTROLLER
  //
  // Same controller used by Dashboard for health score fallback.
  // ============================================================

  final AuthController _authController = Get.put(AuthController());

  // ============================================================
  // STATE
  // ============================================================

  int _currentIndex = 2;

  String _selectedPeriod = "This Week";

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgressData();
    });
  }

  // ============================================================
  // LOAD ALL PROGRESS DATA
  // ============================================================

  Future<void> _loadProgressData() async {
    await Future.wait([
      // ----------------------------------------------------------
      // HEALTH PROFILE
      //
      // This is now one of the primary sources for health score.
      // ----------------------------------------------------------
      _healthProfileController.getHealthProfile(),

      // ----------------------------------------------------------
      // AI PROFILE ANALYSIS
      // ----------------------------------------------------------
      _aiController.analyzeProfile(),

      // ----------------------------------------------------------
      // NUTRITION DATA
      // ----------------------------------------------------------
      _healthNutritionController.fetchAllData(),

      // ----------------------------------------------------------
      // PREMIUM REPORTS
      // ----------------------------------------------------------
      _premiumReportController.fetchReports(),

      // ----------------------------------------------------------
      // TODAY SUMMARY
      // ----------------------------------------------------------
      _dashboardController.fetchTodaySummary(),

      // ----------------------------------------------------------
      // AUTH USER
      //
      // Used as fallback for health_score.
      // ----------------------------------------------------------
      _authController.getCurrentUser(),

      // ----------------------------------------------------------
      // MAIN PROGRESS API
      // ----------------------------------------------------------
      _progressController.fetchProgress(filter: _apiFilter(_selectedPeriod)),
    ]);

    // ------------------------------------------------------------
    // DEBUG
    // ------------------------------------------------------------

    debugPrint(
      '🔍 [Progress Debug] Health Profile: '
      '${_healthProfileController.healthProfile.value?.toJson()}',
    );

    debugPrint(
      '🔍 [Progress Debug] Current User: '
      '${_authController.currentUser.value}',
    );

    debugPrint('❤️ [Progress Debug] Health Score: $_dynamicHealthScore');

    debugPrint(
      '📊 [Progress Debug] Progress Filter: '
      '${_apiFilter(_selectedPeriod)}',
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  // ============================================================
  // REFRESH PROGRESS DATA + OPTIONAL BANNERS
  // ============================================================

  Future<void> _refreshProgress() async {
    await Future.wait<void>([
      _loadProgressData(),

      _progressBannerKey.currentState?.refreshBanners() ?? Future<void>.value(),
    ]);
  }

  // ============================================================
  // PERIOD -> API FILTER
  // ============================================================

  String _apiFilter(String period) {
    switch (period) {
      case "Today":
        return "today";

      case "This Week":
        return "week";

      case "This Month":
        return "month";

      case "This Year":
        return "year";

      default:
        return "week";
    }
  }

  // ============================================================
  // CHANGE PERIOD
  // ============================================================

  Future<void> _changePeriod(String period) async {
    setState(() {
      _selectedPeriod = period;
    });

    await _progressController.changeFilter(_apiFilter(period));
  }

  // ============================================================
  // DYNAMIC AI ANALYSIS DATA
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

  // ============================================================
  // BMI
  // ============================================================

  double get _currentBmi {
    final bmi = _analysisData?['bmi'] ?? _analysisData?['BMI'];

    if (bmi != null) {
      return double.tryParse(bmi.toString()) ?? 23.5;
    }

    return 23.5;
  }

  // ============================================================
  // BMI CATEGORY
  // ============================================================

  String get _bmiCategory {
    return _analysisData?['health_category']?.toString() ??
        _analysisData?['bmi_category']?.toString() ??
        "Healthy";
  }

  // ============================================================
  // CURRENT WEIGHT
  //
  // Progress API is the source of truth.
  // ============================================================

  double get _currentWeight {
    final weight = _progressController.currentWeight;

    if (weight > 0) {
      return weight;
    }

    final profile = _healthProfileController.healthProfile.value;

    return profile?.weightKg ?? 65.0;
  }

  // ============================================================
  // TARGET WEIGHT
  // ============================================================

  double get _targetWeight {
    final progressTarget = _progressController.targetWeight;

    if (progressTarget > 0) {
      return progressTarget;
    }

    final profile = _healthProfileController.healthProfile.value;

    return profile?.targetWeightKg ?? 58.0;
  }

  // ============================================================
  // STARTING WEIGHT
  //
  // Progress API provides the actual start weight.
  // ============================================================

  double get _startingWeight {
    final progressStart = _progressController.startingWeight;

    if (progressStart > 0) {
      return progressStart;
    }

    return _currentWeight;
  }

  // ============================================================
  // HEALTH SCORE
  //
  // SAME LOGIC AS DASHBOARD
  //
  // Priority:
  //
  // 1. Health Profile API -> healthScore
  // 2. Current User API -> health_score
  // 3. Premium Report -> healthScore
  // 4. Default -> 85
  //
  // This keeps Progress and Dashboard synchronized.
  // ============================================================

  int get _dynamicHealthScore {
    // ------------------------------------------------------------
    // 1. HEALTH PROFILE API
    // ------------------------------------------------------------

    final profile = _healthProfileController.healthProfile.value;

    if (profile != null && profile.healthScore != null) {
      return profile.healthScore!.clamp(0, 100);
    }

    // ------------------------------------------------------------
    // 2. CURRENT USER API
    // ------------------------------------------------------------

    final user = _authController.currentUser.value;

    if (user != null && user['health_score'] != null) {
      final score = int.tryParse(user['health_score'].toString());

      if (score != null) {
        return score.clamp(0, 100);
      }
    }

    // ------------------------------------------------------------
    // 3. PREMIUM REPORT FALLBACK
    //
    // We keep this as a fallback so the card doesn't become empty
    // if profile/user API temporarily doesn't contain the score.
    // ------------------------------------------------------------

    final report = _selectedPeriod == "This Week"
        ? _premiumReportController.weeklyReport.value
        : _premiumReportController.monthlyReport.value;

    if (report?.healthScore != null) {
      return report!.healthScore!.toInt().clamp(0, 100);
    }

    // ------------------------------------------------------------
    // 4. FINAL FALLBACK
    // ------------------------------------------------------------

    return 85;
  }

  // ============================================================
  // HEALTH SCORE STATUS
  // ============================================================

  String get _healthScoreStatus {
    final score = _dynamicHealthScore;

    if (score >= 90) {
      return "Excellent";
    }

    if (score >= 80) {
      return "Very Good";
    }

    if (score >= 70) {
      return "Good";
    }

    if (score >= 60) {
      return "Fair";
    }

    return "Needs Attention";
  }

  // ============================================================
  // HEALTH SCORE WEEKLY IMPROVEMENT
  // ============================================================
  //
  // Kept from your existing UI because the current Health Profile
  // API does not provide a health-score improvement value.
  //
  // Premium report can provide this in the future if required.
  // ============================================================

  int get _healthScoreImprovement {
    final report = _premiumReportController.weeklyReport.value;

    if (report != null) {
      // Keep existing UI value because the current report model
      // does not expose a dedicated improvement field.
      return 6;
    }

    return 6;
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(int index) {
    if (index == _currentIndex) {
      return;
    }

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
        Get.offNamed(AppRoutes.contactNutritionist);
        break;
    }
  }

  // ============================================================
  // RESPONSIVE HORIZONTAL PADDING
  // ============================================================

  double _horizontalPadding(double width) {
    if (width <= 360) {
      return 16;
    }

    if (width <= 430) {
      return 20;
    }

    if (width <= 700) {
      return 24;
    }

    return 30;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================
      bottomNavigationBar: DashboardBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavigationTap,
      ),

      // ==========================================================
      // BODY
      // ==========================================================
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
                        // ==================================================
                        // HEADER
                        // ==================================================
                        // ==================================================
                        // HEADER
                        // ==================================================
                        ProgressAppBar(
                          selectedPeriod: _selectedPeriod,
                          onPeriodChanged: (value) {
                            _changePeriod(value);
                          },
                        ),

                        // ==================================================
                        // OPTIONAL PROGRESS BANNER
                        //
                        // If banners exist:
                        //   Show banner with 24px spacing.
                        //
                        // If no banners exist:
                        //   No banner and no additional spacing.
                        //
                        // Existing header-to-metrics spacing remains 26px.
                        // ==================================================
                        _buildOptionalProgressBanner(),

                        const SizedBox(height: 26),

                        // ==================================================
                        // PROGRESS API LOADING / ERROR / METRICS
                        // ==================================================
                        Obx(() {
                          final progress = _progressController.progress.value;

                          final isLoading = _progressController.isLoading.value;

                          final error = _progressController.errorMessage.value;

                          // ------------------------------------------------
                          // LOADING
                          // ------------------------------------------------

                          if (isLoading && progress == null) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 35),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          // ------------------------------------------------
                          // ERROR
                          // ------------------------------------------------

                          if (progress == null &&
                              error != null &&
                              error.isNotEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      error,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // ------------------------------------------------
                          // METRICS
                          // ------------------------------------------------

                          return QuickHealthMetrics(
                            calories: _progressController.caloriesDisplay,
                            steps: _progressController.stepsDisplay,
                            sleep: _progressController.sleepDisplay,
                            water: _progressController.waterDisplay,
                          );
                        }),

                        const SizedBox(height: 24),

                        // ==================================================
                        // WEIGHT PROGRESS CARD
                        // ==================================================
                        Obx(
                          () => WeightProgressCard(
                            startingWeight: _startingWeight,
                            currentWeight: _currentWeight,
                            targetWeight: _targetWeight,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // WEIGHT PROGRESS CHART
                        // ==================================================
                        // ==========================================================
                        // WEIGHT PROGRESS CHART
                        //
                        // Uses the exact same weight values as WeightProgressCard.
                        // All values originate from the shared ProgressController.
                        // ==========================================================
                        Obx(
                          () => WeightProgressChart(
                            currentWeight: _currentWeight,
                            startingWeight: _startingWeight,
                            goalWeight: _targetWeight,
                            spots: _progressController.weightSpots,
                            labels: _progressController.chartLabels,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // BMI
                        // ==================================================
                        Obx(
                          () => BMIProgressCard(
                            bmi: _currentBmi,
                            category: _bmiCategory,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // OVERALL HEALTH SCORE
                        //
                        // NOW USES THE SAME API DATA AS DASHBOARD
                        // ==================================================
                        Obx(
                          () => OverallHealthScoreCard(
                            healthScore: _dynamicHealthScore,
                            weeklyImprovement: _healthScoreImprovement,
                            status: _healthScoreStatus,
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ==================================================
                        // AI PROGRESS INSIGHTS
                        // ==================================================
                        Obx(() {
                          final report = _selectedPeriod == "This Week"
                              ? _premiumReportController.weeklyReport.value
                              : _premiumReportController.monthlyReport.value;

                          if (report != null && report.aiInsights.isNotEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "$_selectedPeriod AI Health Insights",
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    report.aiInsights,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13.5,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return const ProgressInsightsCard();
                        }),

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
  // ============================================================
  // OPTIONAL PROGRESS BANNER
  //
  // Backend category: Progress
  //
  // Banner available:
  //   Show Meditation-style banner.
  //
  // No banner:
  //   Return zero-height content with no extra spacing.
  // ============================================================

  Widget _buildOptionalProgressBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasProgressBanners) const SizedBox(height: 24),

        BannerCarousel(
          key: _progressBannerKey,
          category: 'Progress',
          title: 'Your Wellness Journey',
          subtitle: 'Celebrate every step towards a healthier you',
          height: 175,
          autoSlideDuration: const Duration(seconds: 5),
          showSectionTitle: true,
          onVisibilityChanged: _onProgressBannerVisibilityChanged,
        ),

        if (_hasProgressBanners) const SizedBox(height: 24),
      ],
    );
  }
}
