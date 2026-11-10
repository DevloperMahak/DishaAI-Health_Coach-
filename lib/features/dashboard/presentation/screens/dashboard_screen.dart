import 'dart:async';

import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'package:disha_ai/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:disha_ai/features/dashboard/presentation/controllers/task_controller.dart';
import 'package:disha_ai/features/dashboard/presentation/controllers/weekly_progress_controller.dart';
import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:disha_ai/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:disha_ai/features/payment/data/services/payment_report_service.dart';

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

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  // ============================================================
  // SCAFFOLD KEY
  // ============================================================

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final HealthProfileController _healthProfileController =
      Get.isRegistered<HealthProfileController>()
      ? Get.find<HealthProfileController>()
      : Get.put(HealthProfileController());

  final AiController _aiController = Get.find<AiController>();

  final DashboardController _dashboardController =
      Get.find<DashboardController>();

  final WeeklyProgressController _weeklyProgressController =
      Get.isRegistered<WeeklyProgressController>()
      ? Get.find<WeeklyProgressController>()
      : Get.put(WeeklyProgressController());

  final AuthController _authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  final TaskController _taskController = Get.isRegistered<TaskController>()
      ? Get.find<TaskController>()
      : Get.put(TaskController());

  final NotificationController _notificationController =
      Get.isRegistered<NotificationController>()
      ? Get.find<NotificationController>()
      : Get.put(NotificationController());

  // ============================================================
  // MEMBERSHIP STATUS
  // ============================================================

  final PaymentReportService _paymentService = PaymentReportService();

  bool _isCheckingMembership = false;
  bool _isRedirectingForMembership = false;

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  static const int _homeIndex = 0;

  // Prevent multiple navigation requests from rapid taps.
  bool _isNavigating = false;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Check backend membership when Dashboard opens.
      unawaited(_checkMembershipStatus());

      // Load existing dashboard data.
      unawaited(_loadDashboardData());
    });
  }

  // ============================================================
  // CHECK MEMBERSHIP STATUS FROM BACKEND
  // GET /api/membership/status
  // ============================================================

  Future<void> _checkMembershipStatus() async {
    if (!mounted || _isCheckingMembership || _isRedirectingForMembership) {
      return;
    }

    _isCheckingMembership = true;

    try {
      debugPrint('🔄 [Membership] Checking membership status...');

      final response = await _paymentService.getMembershipStatus();

      if (!mounted || _isRedirectingForMembership) return;

      if (response is! Map) {
        debugPrint(
          '⚠️ [Membership] Invalid membership response. '
          'Keeping dashboard accessible.',
        );
        return;
      }

      final membership = _extractMembershipData(response);

      final state = membership['state']?.toString().trim().toLowerCase();

      final hasAccess = _parseBool(membership['has_access']);

      debugPrint('📌 [Membership] State: $state');
      debugPrint('📌 [Membership] Has access: $hasAccess');

      // --------------------------------------------------------
      // ACTIVE MEMBERSHIP
      // --------------------------------------------------------

      if ((state == 'active' || state == 'legacy_active') && hasAccess) {
        debugPrint('✅ [Membership] Access is active.');
        return;
      }

      // --------------------------------------------------------
      // INITIAL OFFER
      // --------------------------------------------------------

      if (state == 'initial_offer') {
        debugPrint(
          '➡️ [Membership] Initial offer required. '
          'Redirecting to Journey Ahead.',
        );

        _redirectForMembership(AppRoutes.journeyAhead);
        return;
      }

      // --------------------------------------------------------
      // EXPIRED MEMBERSHIP / TRIAL
      // --------------------------------------------------------

      if (state == 'upgrade_required') {
        debugPrint(
          '⛔ [Membership] Membership expired. '
          'Redirecting to Upgrade Premium.',
        );

        _redirectForMembership(AppRoutes.upgradePremium);
        return;
      }

      // --------------------------------------------------------
      // UNKNOWN / INCONSISTENT RESPONSE
      // --------------------------------------------------------

      debugPrint(
        '⚠️ [Membership] Unrecognized membership state: $state. '
        'Keeping dashboard accessible until status can be checked again.',
      );
    } catch (e, stackTrace) {
      // A network or server error does not prove that membership
      // has expired. Keep the user on Dashboard and retry when
      // the app resumes or the user refreshes.

      debugPrint('⚠️ [Membership] Status check failed: $e');
      debugPrint('$stackTrace');
    } finally {
      _isCheckingMembership = false;
    }
  }

  // ============================================================
  // EXTRACT MEMBERSHIP DATA
  // ============================================================

  Map<String, dynamic> _extractMembershipData(Map<dynamic, dynamic> response) {
    final responseMap = Map<String, dynamic>.from(response);

    // PaymentReportService.getMembershipStatus() normally returns
    // the data map directly. This also supports a wrapped response.

    final data = responseMap['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return responseMap;
  }

  // ============================================================
  // BOOLEAN PARSER
  // ============================================================

  bool _parseBool(dynamic value) {
    if (value is bool) return value;

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }

    if (value is int) return value == 1;

    return false;
  }

  // ============================================================
  // REDIRECT BASED ON MEMBERSHIP
  // ============================================================

  void _redirectForMembership(String route) {
    if (!mounted || _isRedirectingForMembership) return;

    _isRedirectingForMembership = true;

    debugPrint('➡️ [Membership] Redirecting to: $route');

    Get.offAllNamed<void>(route);
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint(
        '🔄 [Membership] App resumed. '
        'Checking membership with backend.',
      );

      unawaited(_checkMembershipStatus());
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ============================================================
  // LOAD DASHBOARD DATA
  // ============================================================

  Future<void> _loadDashboardData() async {
    try {
      await Future.wait([
        _healthProfileController.getHealthProfile(),
        _aiController.getRecommendations(),
        _dashboardController.loadDashboard(),
        _authController.getCurrentUser(),
        _taskController.fetchTasks(),
        _weeklyProgressController.refreshWeeklyProgress(),
        _notificationController.fetchNotifications(),
      ]);

      if (!mounted) return;

      debugPrint(
        '🔍 [Dashboard Debug] Current User Data: '
        '${_authController.currentUser.value}',
      );

      debugPrint(
        '🔍 [Dashboard Debug] Health Profile Data: '
        '${_healthProfileController.healthProfile.value?.toJson()}',
      );

      debugPrint(
        '🔍 [Dashboard Debug] Weekly Progress: '
        '${_weeklyProgressController.days.length} days loaded',
      );

      debugPrint(
        '🔔 [Dashboard Debug] Unread Notifications: '
        '${_notificationController.unreadCount}',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [Dashboard] Failed to load dashboard data: $e');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // REFRESH DASHBOARD
  // ============================================================

  Future<void> _refreshDashboard() async {
    await _checkMembershipStatus();

    if (!mounted || _isRedirectingForMembership) return;

    await _loadDashboardData();
  }

  // ============================================================
  // USER NAME
  // ============================================================

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

  // ============================================================
  // HEALTH SCORE
  // ============================================================

  int get _healthScore {
    final profile = _healthProfileController.healthProfile.value;

    if (profile != null && profile.healthScore != null) {
      return profile.healthScore!;
    }

    final user = _authController.currentUser.value;

    if (user != null && user['health_score'] != null) {
      return int.tryParse(user['health_score'].toString()) ?? 85;
    }

    return 85;
  }

  // ============================================================
  // USER GOAL
  // ============================================================

  String get _userGoal {
    final localGoal = _healthProfileController.primaryHealthGoal;

    if (localGoal != null && localGoal.isNotEmpty) {
      return localGoal.tr;
    }

    final profileGoals = _healthProfileController.healthProfile.value?.goals;

    if (profileGoals != null && profileGoals.isNotEmpty) {
      final firstGoal = profileGoals.first;

      return (firstGoal.replaceAll('-', ' ').capitalizeFirst ?? firstGoal).tr;
    }

    return "General Fitness".tr;
  }

  // ============================================================
  // STREAK
  // ============================================================

  int get _streakDays {
    final user = _authController.currentUser.value;

    if (user != null && user['current_streak'] != null) {
      return int.tryParse(user['current_streak'].toString()) ?? 0;
    }

    return 5;
  }

  // ============================================================
  // POINTS
  // ============================================================

  int get _points {
    final user = _authController.currentUser.value;

    if (user != null && user['points'] != null) {
      return int.tryParse(user['points'].toString()) ?? 0;
    }

    return 120;
  }

  // ============================================================
  // AI RECOMMENDATION
  // ============================================================

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

          if (firstRec is Map) {
            final title = firstRec['title'] ?? 'Recommendation'.tr;
            final desc = firstRec['description'] ?? '';

            return "$title: $desc";
          }

          if (firstRec != null) {
            return firstRec.toString();
          }
        }
      }

      return responseData['recommendation']?.toString() ??
          responseData['daily_tip']?.toString() ??
          responseData['message']?.toString() ??
          responseData['summary']?.toString() ??
          "Stay consistent with your routine today!".tr;
    }

    if (responseData is String) {
      return responseData;
    }

    return "Stay consistent with your routine today!".tr;
  }

  // ============================================================
  // SAFE NAVIGATION
  // ============================================================

  Future<void> _navigateTo(String route) async {
    if (_isNavigating || _isRedirectingForMembership) return;

    _isNavigating = true;

    try {
      await Get.toNamed<dynamic>(route);
    } catch (e, stackTrace) {
      debugPrint('❌ [Dashboard Navigation] Error opening $route: $e');
      debugPrint('$stackTrace');
    } finally {
      _isNavigating = false;
    }
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(int index) {
    debugPrint('🔹 [Dashboard Bottom Nav] Tapped index: $index');

    switch (index) {
      case 0:
        // Already on the dashboard.
        break;

      case 1:
        _navigateTo(AppRoutes.myPlan);
        break;

      case 2:
        _navigateTo(AppRoutes.progress);
        break;

      case 3:
        _navigateTo(AppRoutes.aiCoach);
        break;

      case 4:
        _navigateTo(AppRoutes.contactNutritionist);
        break;

      default:
        debugPrint('⚠️ [Dashboard Bottom Nav] Invalid index: $index');
    }
  }

  // ============================================================
  // NOTIFICATION
  // ============================================================

  void _onNotificationTap() {
    _navigateTo(AppRoutes.notifications);
  }

  // ============================================================
  // PROFILE
  // ============================================================

  void _onProfileTap() {
    _navigateTo(AppRoutes.profile);
  }

  // ============================================================
  // PLAN
  // ============================================================

  void _openPlan() {
    _navigateTo(AppRoutes.generatedPlanDashboard);
  }

  // ============================================================
  // NUTRITIONIST
  // ============================================================

  void _openNutritionist() {
    _navigateTo(AppRoutes.contactNutritionist);
  }

  // ============================================================
  // DRAWER
  // ============================================================

  void _onMenuTap() {
    _scaffoldKey.currentState?.openDrawer();
  }

  // ============================================================
  // DRAWER NAVIGATION
  // ============================================================

  void _onDrawerItemTap(int index) {
    switch (index) {
      case 0:
        // Home
        break;

      case 1:
        _navigateTo(AppRoutes.aiCoach);
        break;

      case 2:
        _navigateTo(AppRoutes.myPlan);
        break;

      case 3:
        _navigateTo(AppRoutes.progress);
        break;

      case 4:
        _navigateTo(AppRoutes.notifications);
        break;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,

      // ========================================================
      // DRAWER
      // ========================================================
      drawer: Obx(
        () => DashboardDrawer(
          userName: _userName,
          email: "user@example.com",
          profileImage: null,
          onItemTap: _onDrawerItemTap,
        ),
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================
      bottomNavigationBar: DashboardBottomNavBar(
        currentIndex: _homeIndex,
        onTap: _onBottomNavigationTap,
      ),

      // ========================================================
      // BODY
      // ========================================================
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

  // ============================================================
  // PHONE LAYOUT
  // ============================================================

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
          // APP BAR
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverToBoxAdapter(
              child: Obx(
                () => DashboardAppBar(
                  userName: _userName,
                  notificationCount: _notificationController.unreadCount.value,
                  onMenuTap: _onMenuTap,
                  onNotificationTap: _onNotificationTap,
                  onProfileTap: _onProfileTap,
                ),
              ),
            ),
          ),

          // DASHBOARD CONTENT
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // HEALTH SUMMARY
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

                // QUICK ACTIONS
                const DashboardSection(
                  animationDelay: Duration(milliseconds: 100),
                  child: QuickActionsSection(),
                ),

                const SizedBox(height: 16),

                // TODAY OVERVIEW
                const DashboardSection(
                  animationDelay: Duration(milliseconds: 180),
                  child: TodayOverviewSection(),
                ),

                const SizedBox(height: 16),

                // TODAY SCHEDULE
                DashboardSection(
                  animationDelay: const Duration(milliseconds: 260),
                  child: TodayScheduleCard(),
                ),

                const SizedBox(height: 16),

                // WEEKLY PROGRESS
                const DashboardSection(
                  animationDelay: Duration(milliseconds: 340),
                  child: WeeklyProgressCard(),
                ),

                const SizedBox(height: 16),

                // NUTRITIONIST
                DashboardSection(
                  animationDelay: const Duration(milliseconds: 380),
                  child: _buildNutritionistCard(),
                ),

                const SizedBox(height: 16),

                // AI RECOMMENDATION
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

  // ============================================================
  // WIDE / TABLET / DESKTOP LAYOUT
  // ============================================================

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
                  // APP BAR
                  Obx(
                    () => DashboardAppBar(
                      userName: _userName,
                      notificationCount:
                          _notificationController.unreadCount.value,
                      onMenuTap: _onMenuTap,
                      onNotificationTap: _onNotificationTap,
                      onProfileTap: _onProfileTap,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // HEALTH SUMMARY
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

                  // QUICK ACTIONS
                  const DashboardSection(child: QuickActionsSection()),

                  const SizedBox(height: 16),

                  // MAIN CONTENT
                  DashboardSection(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT COLUMN
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

                        // RIGHT COLUMN
                        Expanded(
                          child: Column(
                            children: [
                              TodayScheduleCard(),
                              const SizedBox(height: 24),
                              _buildNutritionistCard(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // AI RECOMMENDATION
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

  // ============================================================
  // NUTRITIONIST CARD
  // ============================================================

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
          // ICON
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

          // CONTENT
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

          // CONSULT BUTTON
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
