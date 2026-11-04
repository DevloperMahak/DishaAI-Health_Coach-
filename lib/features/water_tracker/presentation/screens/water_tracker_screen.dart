import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

import '../controllers/water_tracker_controller.dart';
import 'package:disha_ai/features/dashboard/presentation/widgets/banner_carousel.dart';
import '../widgets/water_header.dart';
import '../widgets/water_progress_card.dart';
import '../widgets/quick_add_water.dart';
import '../widgets/hydration_ai_card.dart';
import '../widgets/todays_water_timeline.dart';
import '../widgets/custom_water_bottom_sheet.dart';
import '../widgets/weekly_water_chart.dart';
import '../widgets/hydration_statistics.dart';
import '../widgets/reminder_card.dart';

import 'package:disha_ai/features/reminders/data/services/reminder_service.dart';
import 'package:disha_ai/features/reminders/presentation/controller/reminder_settings_controller.dart';

class WaterTrackerScreen extends StatelessWidget {
  WaterTrackerScreen({super.key});

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final WaterTrackerController controller =
      Get.isRegistered<WaterTrackerController>()
      ? Get.find<WaterTrackerController>()
      : Get.put(WaterTrackerController());

  final ReminderSettingsController reminderSettingsController =
      Get.isRegistered<ReminderSettingsController>()
      ? Get.find<ReminderSettingsController>()
      : Get.put(ReminderSettingsController(service: ReminderService()));

  // ============================================================
  // BANNER KEY
  // ============================================================

  final GlobalKey<BannerCarouselState> _bannerKey =
      GlobalKey<BannerCarouselState>();

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshAllData() async {
    await Future.wait([
      controller.refreshData(),
      _bannerKey.currentState?.refreshBanners() ?? Future<void>.value(),
    ]);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final bool isTablet = width >= 700;

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: _refreshAllData,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1160),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : horizontalPadding(width),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ========================================
                          // HEADER
                          // ========================================
                          // ============================================================
                          // APP BAR — SAME AS MEDITATION
                          // ============================================================
                          WaterHeader(
                            goal: controller.dailyGoal,
                            current: controller.todayIntake,
                            onBack: () => Get.back(),
                          ),

                          const SizedBox(height: 26),

                          // ============================================================
                          // GREETING — SAME AS MEDITATION
                          // ============================================================
                          _buildGreeting(width),

                          const SizedBox(height: 28),

                          // ============================================================
                          // API BANNER — SAME AS MEDITATION
                          // ============================================================
                          _buildWaterBanner(),

                          const SizedBox(height: 20),

                          // ========================================
                          // MAIN CONTENT
                          // ========================================
                          if (isTablet)
                            _buildTabletContent()
                          else
                            _buildPhoneContent(),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // WATER BANNER
  // ============================================================

  Widget _buildWaterBanner() {
    return BannerCarousel(
      key: _bannerKey,
      category: 'Water',
      title: 'Stay Hydrated',
      subtitle: 'A little inspiration for your hydration journey',
      height: 175,
      autoSlideDuration: const Duration(seconds: 5),
      showSectionTitle: true,
    );
  }

  // ============================================================
  // PHONE CONTENT
  // ============================================================

  Widget _buildPhoneContent() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ========================================
          // DAILY PROGRESS
          // ========================================
          _buildProgressCard(),

          const SizedBox(height: 20),

          // ========================================
          // QUICK ADD
          // ========================================
          _buildQuickAdd(),

          const SizedBox(height: 20),

          // ========================================
          // AI RECOMMENDATION
          // ========================================
          _buildAiCard(),

          const SizedBox(height: 20),

          // ========================================
          // TODAY'S TIMELINE
          // ========================================
          _buildTimeline(),

          // ========================================
          // OPTIONAL SECTIONS
          // ========================================

          // const SizedBox(height: 24),
          // _buildWeeklyChart(),

          // const SizedBox(height: 24),
          // _buildStatistics(),

          // const SizedBox(height: 24),
          // _buildReminder(),
        ],
      ),
    );
  }

  // ============================================================
  // TABLET CONTENT
  // ============================================================

  Widget _buildTabletContent() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ========================================
          // DAILY PROGRESS
          // ========================================
          _buildProgressCard(),

          const SizedBox(height: 24),

          // ========================================
          // TWO COLUMN LAYOUT
          // ========================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ======================================
              // LEFT COLUMN
              // ======================================
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildQuickAdd(),

                    const SizedBox(height: 24),

                    _buildTimeline(),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // ======================================
              // RIGHT COLUMN
              // ======================================
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAiCard(),

                    // const SizedBox(height: 24),
                    // _buildWeeklyChart(),
                  ],
                ),
              ),
            ],
          ),

          // const SizedBox(height: 24),
          // _buildStatistics(),

          // const SizedBox(height: 24),
          // _buildReminder(),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESS CARD
  // ============================================================

  Widget _buildProgressCard() {
    return WaterProgressCard(
      currentIntake: controller.todayIntake,
      dailyGoal: controller.dailyGoal,
      progress: controller.progress,
      percentage: controller.percentage,
    );
  }

  // ============================================================
  // QUICK ADD WATER
  // ============================================================

  Widget _buildQuickAdd() {
    return QuickAddWater(
      onAdd100: () => controller.addWater(100),
      onAdd250: () => controller.addWater(250),
      onAdd500: () => controller.addWater(500),
      onCustomTap: _showCustomWaterSheet,
    );
  }

  // ============================================================
  // CUSTOM WATER BOTTOM SHEET
  // ============================================================

  void _showCustomWaterSheet() {
    Get.bottomSheet(
      CustomWaterBottomSheet(
        onAdd: (amount) {
          controller.addWater(amount);
        },
      ),
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    );
  }

  // ============================================================
  // AI RECOMMENDATION
  // ============================================================

  Widget _buildAiCard() {
    return HydrationAICard(
      message: controller.aiRecommendation,
      hydrationScore: controller.hydrationScore,
    );
  }

  // ============================================================
  // TODAY'S TIMELINE
  // ============================================================

  Widget _buildTimeline() {
    return TodaysWaterTimeline(logs: controller.todayLogs);
  }

  // ============================================================
  // WEEKLY CHART
  // ============================================================

  Widget _buildWeeklyChart() {
    return WeeklyWaterChart();
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    return HydrationStatistics(
      averageWater: controller.averageWater,
      bestWater: controller.bestWater,
      streak: controller.currentStreak,
      score: controller.hydrationScore,
    );
  }

  // ============================================================
  // HYDRATION REMINDER
  // ============================================================

  Widget _buildReminder() {
    return Obx(() {
      final settings = reminderSettingsController.settings.value;

      if (settings == null && reminderSettingsController.isLoading.value) {
        return _buildReminderLoading();
      }

      if (settings == null) {
        return _buildReminderUnavailable();
      }

      final bool masterEnabled = settings.remindersEnabled;

      final bool hydrationEnabled = settings.categories['hydration'] ?? false;

      final bool reminderEnabled = masterEnabled && hydrationEnabled;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!masterEnabled) ...[
            _buildMasterReminderDisabledCard(),

            const SizedBox(height: 12),
          ],

          ReminderCard(
            enabled: reminderEnabled,
            interval: 120,

            onToggle: (bool value) async {
              await _handleHydrationToggle(value, masterEnabled: masterEnabled);
            },

            onIntervalChanged: (int value) {
              _handleHydrationIntervalChanged(value);
            },
          ),
        ],
      );
    });
  }

  // ============================================================
  // HYDRATION REMINDER TOGGLE
  // ============================================================

  Future<void> _handleHydrationToggle(
    bool value, {
    required bool masterEnabled,
  }) async {
    if (value && !masterEnabled) {
      Get.snackbar(
        'Reminders Disabled',
        'Please enable Master Health Reminders first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        duration: const Duration(seconds: 3),
      );

      return;
    }

    await reminderSettingsController.toggleCategory('hydration', value);
  }

  // ============================================================
  // HYDRATION INTERVAL
  // ============================================================

  void _handleHydrationIntervalChanged(int minutes) {
    Get.snackbar(
      'Reminder Interval',
      'Selected: ${_formatInterval(minutes)}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      duration: const Duration(seconds: 2),
    );
  }

  // ============================================================
  // FORMAT INTERVAL
  // ============================================================

  String _formatInterval(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }

    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;

      return hours == 1 ? '1 hour' : '$hours hours';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    return '${hours}h ${remainingMinutes}m';
  }

  // ============================================================
  // MASTER REMINDER DISABLED
  // ============================================================

  Widget _buildMasterReminderDisabledCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.12),
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Reminders are disabled',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Enable Master Health Reminders from Reminder Settings to use hydration reminders.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REMINDER UNAVAILABLE
  // ============================================================

  Widget _buildReminderUnavailable() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'Reminder settings are unavailable.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GREETING — SAME DESIGN AS MEDITATION
  // ============================================================

  Widget _buildGreeting(double width) {
    final scale = (width / 390).clamp(0.88, 1.12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stay hydrated',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24 * scale,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          'Every sip counts towards a healthier you.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5 * scale,
            height: 1.45,
          ),
        ),
      ],
    );
  }
  // ============================================================
  // REMINDER LOADING
  // ============================================================

  Widget _buildReminderLoading() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'Loading hydration reminder settings...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESPONSIVE PADDING
  // ============================================================

  double horizontalPadding(double width) {
    if (width <= 340) return 16;
    if (width <= 380) return 18;
    if (width <= 430) return 20;
    if (width <= 600) return 24;

    return 32;
  }
}
