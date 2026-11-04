import 'package:disha_ai/features/plan/presentation/controllers/today_progress_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:disha_ai/app/routes/app_routes.dart';
import 'package:disha_ai/app/theme/app_colors.dart';
import 'package:disha_ai/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:disha_ai/features/dashboard/presentation/widgets/dashboard_bottom_nav_bar.dart';
import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'package:disha_ai/features/water_tracker/presentation/controllers/water_tracker_controller.dart';

import '../widgets/plan_header.dart';
import '../widgets/today_progress_card.dart';
import '../widgets/ai_message_card.dart';
import '../widgets/daily_task_card.dart';
import '../widgets/water_tracker_card.dart';
import '../widgets/meal_plan_card.dart';
import '../widgets/streak_card.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final AiController _aiController = Get.isRegistered<AiController>()
      ? Get.find<AiController>()
      : Get.put(AiController());

  final AuthController _authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  final WaterTrackerController _waterController =
      Get.isRegistered<WaterTrackerController>()
      ? Get.find<WaterTrackerController>()
      : Get.put(WaterTrackerController());

  final TodayProgressController _todayProgressController =
      Get.isRegistered<TodayProgressController>()
      ? Get.find<TodayProgressController>()
      : Get.put(TodayProgressController());

  late final bool _isFromOnboarding;

  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;

    _isFromOnboarding = args is Map && args['isFromOnboarding'] == true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlanData();
    });
  }

  // ---------------------------------------------------------------------------
  // LOAD PLAN DATA
  // ---------------------------------------------------------------------------

  Future<void> _loadPlanData() async {
    await Future.wait([
      _aiController.generateHealthPlan(),
      _aiController.getRecommendations(),
      _authController.getCurrentUser(),
      _waterController.fetchTodayWater(),

      // Dynamic:
      // total tasks
      // completed tasks
      // pending tasks
      // percentage
      _todayProgressController.refreshTodayProgress(),
    ]);
  }

  Future<void> _refreshPlan() async {
    await _loadPlanData();
  }

  // ---------------------------------------------------------------------------
  // DYNAMIC STREAK
  // ---------------------------------------------------------------------------

  int get _streakDays {
    final user = _authController.currentUser.value;

    if (user != null && user['current_streak'] != null) {
      return int.tryParse(user['current_streak'].toString()) ?? 0;
    }

    return 0;
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION
  // ---------------------------------------------------------------------------

  void _onBottomNavigationTap(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Get.offAllNamed(AppRoutes.dashboard);
        break;

      case 1:
        break;

      case 2:
        Get.toNamed(AppRoutes.progress);
        break;

      case 3:
        Get.toNamed(AppRoutes.aiCoach);
        break;

      case 4:
        Get.toNamed(AppRoutes.contactNutritionist);
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // BACK ACTION
  // ---------------------------------------------------------------------------

  void _handleBackAction() {
    if (_isFromOnboarding) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleBackAction();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,

        bottomNavigationBar: _isFromOnboarding
            ? null
            : DashboardBottomNavBar(
                currentIndex: _currentIndex,
                onTap: _onBottomNavigationTap,
              ),

        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              final bool isTablet = width >= 700 || width > height;

              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: _refreshPlan,
                child: Stack(
                  children: [
                    isTablet
                        ? _buildTabletLayout(width, height)
                        : _buildPhoneLayout(width, height),

                    if (_isFromOnboarding)
                      Positioned(
                        top: 10,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _handleBackAction,
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: AppColors.primary,
                              ),
                            ),

                            ElevatedButton(
                              onPressed: () {
                                Get.snackbar(
                                  'Subscription'.tr,
                                  'Proceeding to payment gateway...'.tr,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                              ),
                              child: Text('Purchase Plan'.tr),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GENERATED AI PLAN
  // ---------------------------------------------------------------------------

  Widget _buildGeneratedPlanCard() {
    return Obx(() {
      final response = _aiController.healthPlan.value;
      final dynamic data = response?.data;

      if (_aiController.isGeneratingPlan.value) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(.3)),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      if (data == null) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withOpacity(.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(.06),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Custom Plan',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (data is Map<String, dynamic>) ...[
              ...((data['plan'] is Map ? data['plan'] : data)
                      as Map<String, dynamic>)
                  .entries
                  .map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key.replaceAll('_', ' ').capitalizeFirst ??
                                entry.key,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            entry.value.toString(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(),
            ] else ...[
              Text(
                data.toString(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // DYNAMIC STREAK CARD
  // ---------------------------------------------------------------------------

  Widget _buildDynamicStreakCard() {
    return Obx(() => StreakCard(streakDays: _streakDays));
  }

  // ---------------------------------------------------------------------------
  // DYNAMIC WATER CARD
  // ---------------------------------------------------------------------------

  Widget _buildWaterTrackerCard() {
    return Obx(
      () => WaterTrackerCard(
        currentIntake: _waterController.todayIntake,
        dailyGoal: _waterController.dailyGoal,
        progress: _waterController.progress,
        percentage: _waterController.percentage,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PHONE LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildPhoneLayout(double width, double height) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(20, _isFromOnboarding ? 60 : 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlanHeader(),

          const SizedBox(height: 20),

          _buildGeneratedPlanCard(),

          const SizedBox(height: 16),

          // Dynamic task progress.
          const TodayProgressCard(),

          const SizedBox(height: 16),

          const AiMessageCard(),

          const SizedBox(height: 16),

          // Dynamic task list.
          DailyTaskCard(),

          const SizedBox(height: 16),

          _buildWaterTrackerCard(),

          //const SizedBox(height: 16),

          //const MealPlanCard(),
          const SizedBox(height: 16),

          _buildDynamicStreakCard(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TABLET / DESKTOP LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildTabletLayout(double width, double height) {
    final double padding = width >= 1200 ? 120.0 : 60.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              padding,
              _isFromOnboarding ? 70 : 30,
              padding,
              40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PlanHeader(),

                const SizedBox(height: 20),

                _buildGeneratedPlanCard(),

                const SizedBox(height: 20),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================================================
                    // LEFT COLUMN
                    // =========================================================
                    Expanded(
                      child: Column(
                        children: [
                          const TodayProgressCard(),

                          const SizedBox(height: 20),

                          DailyTaskCard(),

                          const SizedBox(height: 20),

                          _buildWaterTrackerCard(),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // =========================================================
                    // RIGHT COLUMN
                    // =========================================================
                    Expanded(
                      child: Column(
                        children: [
                          const AiMessageCard(),

                          //const SizedBox(height: 20),

                          //const MealPlanCard(),
                          const SizedBox(height: 20),

                          _buildDynamicStreakCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
