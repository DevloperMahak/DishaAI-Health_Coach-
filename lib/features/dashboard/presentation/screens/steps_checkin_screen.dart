import 'dart:async';

import 'package:disha_ai/core/storage/step_storage.dart';
import 'package:disha_ai/app/theme/app_colors.dart';

import 'package:disha_ai/features/dashboard/presentation/widgets/banner_carousel.dart';
import 'package:disha_ai/features/onboarding/presentation/controllers/health_nutrition_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepsCheckinScreen extends StatefulWidget {
  const StepsCheckinScreen({super.key});

  @override
  State<StepsCheckinScreen> createState() => _StepsCheckinScreenState();
}

class _StepsCheckinScreenState extends State<StepsCheckinScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final HealthNutritionController _healthController =
      Get.isRegistered<HealthNutritionController>()
      ? Get.find<HealthNutritionController>()
      : Get.put(HealthNutritionController());

  // ============================================================
  // OPTIONAL STEPS BANNER
  // ============================================================

  final GlobalKey<BannerCarouselState> _stepsBannerKey =
      GlobalKey<BannerCarouselState>();

  bool _hasStepsBanners = false;

  void _onStepsBannerVisibilityChanged(bool visible) {
    if (!mounted || _hasStepsBanners == visible) return;

    setState(() {
      _hasStepsBanners = visible;
    });
  }

  // ============================================================
  // PEDOMETER STREAM SUBSCRIPTIONS
  // ============================================================

  StreamSubscription<StepCount>? _stepCountSubscription;

  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  // ============================================================
  // STATE
  // ============================================================

  String _steps = '0';

  String _status = 'Initializing...';

  bool _isSubmitting = false;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // RESTORE TODAY'S SAVED STEPS
    // ----------------------------------------------------------

    final storage = StepStorage.instance;

    final now = DateTime.now();

    final String today =
        '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    if (storage.savedDate == today) {
      _steps = storage.todaySteps.toString();
    }

    // ----------------------------------------------------------
    // INITIALIZE HARDWARE SENSOR
    // ----------------------------------------------------------

    _initPlatformState();
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();

    super.dispose();
  }

  // ============================================================
  // INITIALIZE PEDOMETER
  // ============================================================

  Future<void> _initPlatformState() async {
    try {
      final status = await Permission.activityRecognition.request();

      if (!mounted) return;

      if (!status.isGranted) {
        setState(() {
          _status = 'Permission Denied for Step Counter';
        });

        return;
      }

      // --------------------------------------------------------
      // PEDESTRIAN STATUS STREAM
      // --------------------------------------------------------

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        onPedestrianStatusChanged,
        onError: onPedestrianStatusError,
      );

      // --------------------------------------------------------
      // STEP COUNT STREAM
      // --------------------------------------------------------

      _stepCountSubscription = Pedometer.stepCountStream.listen(
        onStepCount,
        onError: onStepCountError,
      );
    } catch (e) {
      debugPrint('❌ [STEPS] Sensor initialization error: $e');

      if (!mounted) return;

      setState(() {
        _status = 'Step Counter Not Available';
      });
    }
  }

  // ============================================================
  // HARDENED DAILY STEP CALCULATION LOGIC
  //
  // Existing logic preserved:
  //
  // 1. Detect new day.
  // 2. Restore saved steps.
  // 3. Handle hardware baseline.
  // 4. Handle device reboot.
  // 5. Persist steps locally.
  // ============================================================

  Future<void> onStepCount(StepCount event) async {
    final storage = StepStorage.instance;

    final now = DateTime.now();

    final String today =
        '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final int currentEventSteps = event.steps;

    int calculatedTodaySteps = 0;

    if (storage.savedDate != today) {
      // --------------------------------------------------------
      // NEW DAY
      // --------------------------------------------------------

      await storage.saveDate(today);

      await storage.saveBaseline(currentEventSteps);

      await storage.savePreviousTotal(0);

      await storage.saveTodaySteps(0);

      calculatedTodaySteps = 0;
    } else {
      final int baseline = storage.baselineSteps;

      if (baseline == 0 && currentEventSteps > 0) {
        // ------------------------------------------------------
        // MISSING BASELINE
        // ------------------------------------------------------

        await storage.saveBaseline(currentEventSteps);

        calculatedTodaySteps = 0;
      } else if (currentEventSteps < baseline) {
        // ------------------------------------------------------
        // DEVICE REBOOT
        // ------------------------------------------------------

        final int prevSteps = storage.todaySteps;

        await storage.savePreviousTotal(prevSteps);

        await storage.saveBaseline(currentEventSteps);

        calculatedTodaySteps = prevSteps;
      } else {
        // ------------------------------------------------------
        // NORMAL CASE
        // ------------------------------------------------------

        calculatedTodaySteps =
            storage.previousTotal + (currentEventSteps - baseline);
      }
    }

    // ----------------------------------------------------------
    // SAVE STEPS LOCALLY
    // ----------------------------------------------------------

    await storage.saveTodaySteps(calculatedTodaySteps);

    // ----------------------------------------------------------
    // UPDATE UI
    // ----------------------------------------------------------

    if (!mounted) return;

    setState(() {
      _steps = calculatedTodaySteps.toString();
    });
  }

  // ============================================================
  // PEDESTRIAN STATUS
  // ============================================================

  void onPedestrianStatusChanged(PedestrianStatus event) {
    if (!mounted) return;

    setState(() {
      _status = event.status;
    });
  }

  // ============================================================
  // STEP COUNT ERROR
  // ============================================================

  void onStepCountError(dynamic error) {
    debugPrint('❌ [STEPS] Step count error: $error');

    if (!mounted) return;

    setState(() {
      _status = 'Step Count Not Available';
    });
  }

  // ============================================================
  // PEDESTRIAN STATUS ERROR
  // ============================================================

  void onPedestrianStatusError(dynamic error) {
    debugPrint('❌ [STEPS] Pedestrian status error: $error');

    if (!mounted) return;

    setState(() {
      _status = 'Pedestrian Status Not Available';
    });
  }

  // ============================================================
  // OPTIONAL STEPS BANNER
  //
  // Backend category: Steps
  //
  // Banner available:
  //   Show Meditation-style banner.
  //
  // No banner:
  //   No banner and no extra spacing.
  // ============================================================

  Widget _buildOptionalStepsBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BannerCarousel(
          key: _stepsBannerKey,
          category: 'Steps',
          title: 'Every Step Counts',
          subtitle: 'Move more, feel stronger, stay motivated',
          height: 175,
          autoSlideDuration: const Duration(seconds: 5),
          showSectionTitle: true,
          onVisibilityChanged: _onStepsBannerVisibilityChanged,
        ),

        if (_hasStepsBanners) const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // PULL-TO-REFRESH
  //
  // Only refresh banners.
  //
  // Do not reset the step counter or sensor baseline.
  // ============================================================

  Future<void> _refreshStepsScreen() async {
    await _stepsBannerKey.currentState?.refreshBanners();
  }

  // ============================================================
  // SYNC STEPS TO API
  //
  // Existing API logic preserved.
  // ============================================================

  Future<void> _syncStepsToApi() async {
    if (_isSubmitting) return;

    final parsedSteps = int.tryParse(_steps) ?? 0;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentLog = _healthController.healthLog.value;

      final success = await _healthController.postHealthMetrics(
        steps: parsedSteps,
        sleepHours: currentLog?.sleepHours ?? 7.5,
        caloriesConsumed: currentLog?.caloriesConsumed ?? 1800,
        caloriesBurned: currentLog?.caloriesBurned ?? 350,
        weightKg: currentLog?.weightKg ?? 58.0,
        mood: currentLog?.mood ?? 'energetic',
        stressLevel: currentLog?.stressLevel ?? 'low',
      );

      if (!mounted) return;

      if (success) {
        Get.back();

        Get.snackbar(
          'Steps Synced',
          'Successfully synced $parsedSteps live steps to your profile!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
          margin: const EdgeInsets.all(16),
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
          ),
        );
      } else {
        Get.snackbar(
          'Sync Failed',
          'Could not sync steps with server. Try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      debugPrint('❌ [STEPS] Sync error: $e');

      if (!mounted) return;

      Get.snackbar(
        'Sync Failed',
        'Unable to sync steps. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // STEPS CIRCULAR COUNTER
  // ============================================================

  Widget _buildStepsCounter() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.directions_walk_rounded,
            color: AppColors.primary,
            size: 48,
          ),

          const SizedBox(height: 10),

          Text(
            _steps,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Text(
            'Steps Today',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOTION STATUS
  // ============================================================

  Widget _buildMotionStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _status == 'walking' ? Icons.directions_run : Icons.accessibility_new,
          color: AppColors.primary,
        ),

        const SizedBox(width: 8),

        Flexible(
          child: Text(
            'Motion Status: ${_status.capitalizeFirst ?? _status}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SYNC BUTTON
  // ============================================================

  Widget _buildSyncButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _syncStepsToApi,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Sync Live Steps to Server',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ========================================================
      // APP BAR — ORIGINAL UI PRESERVED
      // ========================================================
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Auto Step Counter',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _refreshStepsScreen,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: EdgeInsets.all(isWide ? 30 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),

                          // ====================================
                          // OPTIONAL STEPS BANNER
                          // ====================================
                          _buildOptionalStepsBanner(),

                          // ====================================
                          // ORIGINAL STEPS COUNTER
                          // ====================================
                          _buildStepsCounter(),

                          const SizedBox(height: 30),

                          // ====================================
                          // MOTION STATUS
                          // ====================================
                          _buildMotionStatus(),

                          const SizedBox(height: 15),

                          // ====================================
                          // ORIGINAL DESCRIPTION
                          // ====================================
                          const Text(
                            "Your phone's hardware sensor is automatically tracking your steps in real-time.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 50),

                          // ====================================
                          // SYNC BUTTON
                          // ====================================
                          _buildSyncButton(),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
