import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'package:disha_ai/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:disha_ai/features/dashboard/presentation/controllers/task_controller.dart';
import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:disha_ai/app/routes/app_routes.dart';
import 'package:disha_ai/core/widgets/drawer.dart';
import '../../../../app/theme/app_colors.dart';

import '../controllers/dashboard_controller.dart';

import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_bottom_nav_bar.dart';
import '../widgets/dashboard_section.dart';

import '../widgets/health_summary_card.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/today_overview_section.dart';
import '../widgets/today_schedule_card.dart';
import '../widgets/weekly_progress_card.dart';
import '../widgets/ai_recommendation_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final HealthProfileController _healthProfileController = Get.put(
    HealthProfileController(),
  );
  final AiController _aiController = Get.put(AiController());
  final DashboardController _dashboardController = Get.put(
    DashboardController(),
  );
  final AuthController _authController = Get.put(AuthController());
  final TaskController _taskController = Get.put(TaskController());

  int _currentIndex = 0;
  final int _healthScore = 91;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _healthProfileController.getHealthProfile(),
      _aiController.getRecommendations(),
      _dashboardController.loadDashboard(),
      _authController.getCurrentUser(),
      _taskController.fetchTasks(),
    ]);
  }

  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
  }

  String get _userName {
    final profile = _healthProfileController.healthProfile.value;
    if (profile?.name != null && profile!.name!.trim().isNotEmpty) {
      return profile.name!.split(' ').first.capitalizeFirst ?? profile.name!;
    }

    final user = _authController.currentUser.value;
    if (user != null) {
      final name = user['name'] ?? user['full_name'] ?? user['username'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString().split(' ').first.capitalizeFirst ??
            name.toString();
      }
    }

    return "User".tr;
  }

  String get _userGoal {
    final localGoal = _healthProfileController.primaryHealthGoal;
    if (localGoal != null && localGoal.isNotEmpty) return localGoal.tr;

    final goals = _healthProfileController.healthProfile.value?.goals;
    if (goals != null && goals.isNotEmpty) {
      final firstGoal = goals.first;
      return (firstGoal.replaceAll('-', ' ').capitalizeFirst ?? firstGoal).tr;
    }
    return "General Fitness".tr;
  }

  int get _streakDays {
    final user = _authController.currentUser.value;
    if (user != null && user['current_streak'] != null) {
      return int.tryParse(user['current_streak'].toString()) ?? 0;
    }
    return 5;
  }

  int get _points {
    final user = _authController.currentUser.value;
    if (user != null && user['points'] != null) {
      return int.tryParse(user['points'].toString()) ?? 0;
    }
    return 120;
  }

  String get _aiRecommendation {
    if (_aiController.isRecommending.value) {
      return "Analyzing your metrics to generate today's personalized recommendations..."
          .tr;
    }

    final responseData = _aiController.recommendations.value?.data;
    if (responseData == null) {
      return "Stay hydrated, maintain your diet, and complete your daily goals to keep your streak going!"
          .tr;
    }

    if (responseData is Map<String, dynamic>) {
      if (responseData['recommendations'] is List) {
        final List recs = responseData['recommendations'];
        if (recs.isNotEmpty) {
          final firstRec = recs.first;
          final title = firstRec['title'] ?? 'Recommendation'.tr;
          final desc = firstRec['description'] ?? '';
          return "$title: $desc";
        }
      }
      return responseData['recommendation']?.toString() ??
          responseData['daily_tip']?.toString() ??
          responseData['message']?.toString() ??
          responseData['summary']?.toString() ??
          "Stay consistent with your routine today!".tr;
    }

    if (responseData is String) return responseData;
    return "Stay consistent with your routine today!".tr;
  }

  void _onBottomNavigationTap(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Get.toNamed(AppRoutes.myPlan);
        break;
      case 2:
        Get.toNamed(AppRoutes.progress);
        break;
      case 3:
        Get.toNamed(AppRoutes.aiCoach);
        break;
      case 4:
        Get.toNamed(
          AppRoutes.contactNutritionist,
        ); // Expert Tab routes to Nutritionist List
        break;
    }
  }

  void _onNotificationTap() => Get.toNamed(AppRoutes.notifications);

  // Profile icon tap navigates to Profile Screen
  void _onProfileTap() => Get.toNamed(AppRoutes.profile);

  void _openPlan() => Get.toNamed(AppRoutes.generatedPlan);
  void _openNutritionist() => Get.toNamed(AppRoutes.contactNutritionist);
  void _onMenuTap() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: Obx(
        () => DashboardDrawer(
          userName: _userName,
          email: "user@example.com",
          profileImage: null,
          onItemTap: (index) {
            switch (index) {
              case 0:
                break;
              case 1:
                Get.toNamed(AppRoutes.aiCoach);
                break;
              case 2:
                Get.toNamed(AppRoutes.myPlan);
                break;
              case 3:
                Get.toNamed(AppRoutes.progress);
                break;
              case 4:
                Get.toNamed(AppRoutes.notifications);
                break;
            }
          },
        ),
      ),
      bottomNavigationBar: DashboardBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavigationTap,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final bool isTablet = width >= 700 || width > height;

            if (isTablet) {
              return _buildWideLayout(width: width, height: height);
            }
            return _buildPhoneLayout(width: width, height: height);
          },
        ),
      ),
    );
  }

  Widget _buildPhoneLayout({required double width, required double height}) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _refreshDashboard,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverToBoxAdapter(
              child: Obx(
                () => DashboardAppBar(
                  userName: _userName,
                  notificationCount: 3,
                  onMenuTap: _onMenuTap,
                  onNotificationTap: _onNotificationTap,
                  onProfileTap: _onProfileTap,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                DashboardSection(
                  animationDelay: const Duration(milliseconds: 0),
                  child: Obx(
                    () => HealthSummaryCard(
                      userName: _userName,
                      healthScore: _healthScore,
                      streakDays: _streakDays,
                      goal: _userGoal,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const DashboardSection(
                  animationDelay: Duration(milliseconds: 100),
                  child: QuickActionsSection(),
                ),
                const SizedBox(height: 16),
                const DashboardSection(
                  animationDelay: Duration(milliseconds: 180),
                  child: TodayOverviewSection(),
                ),
                const SizedBox(height: 16),
                DashboardSection(
                  animationDelay: const Duration(milliseconds: 260),
                  child: TodayScheduleCard(),
                ),
                const SizedBox(height: 16),
                const DashboardSection(
                  animationDelay: Duration(milliseconds: 340),
                  child: WeeklyProgressCard(),
                ),
                const SizedBox(height: 16),
                DashboardSection(
                  animationDelay: const Duration(milliseconds: 380),
                  child: _buildNutritionistCard(),
                ),
                const SizedBox(height: 16),
                DashboardSection(
                  animationDelay: const Duration(milliseconds: 420),
                  child: Obx(
                    () => AIRecommendationCard(
                      title: "AI Health Coach".tr,
                      message: _aiRecommendation,
                      buttonText: "View Full Plan".tr,
                      onPressed: _openPlan,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout({required double width, required double height}) {
    final horizontalPadding = width >= 1400
        ? 120.0
        : width >= 1100
        ? 80.0
        : 40.0;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1250),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                28,
                horizontalPadding,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => DashboardAppBar(
                      userName: _userName,
                      notificationCount: 3,
                      onMenuTap: _onMenuTap,
                      onNotificationTap: _onNotificationTap,
                      onProfileTap: _onProfileTap,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DashboardSection(
                    child: Obx(
                      () => HealthSummaryCard(
                        userName: _userName,
                        healthScore: _healthScore,
                        streakDays: _streakDays,
                        goal: _userGoal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const DashboardSection(child: QuickActionsSection()),
                  const SizedBox(height: 16),
                  DashboardSection(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            children: [
                              TodayOverviewSection(),
                              SizedBox(height: 24),
                              WeeklyProgressCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            children: [
                              TodayScheduleCard(),
                              SizedBox(height: 24),
                              _buildNutritionistCard(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  DashboardSection(
                    child: Obx(
                      () => AIRecommendationCard(
                        title: "AI Health Coach".tr,
                        message: _aiRecommendation,
                        buttonText: "Open My Plan".tr,
                        onPressed: _openPlan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionistCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Need Expert Guidance?".tr,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Consult with certified nutritionists for custom plans.".tr,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _openNutritionist,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Consult".tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
