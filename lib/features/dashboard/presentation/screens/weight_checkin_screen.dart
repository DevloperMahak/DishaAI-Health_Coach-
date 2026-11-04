import 'package:disha_ai/features/onboarding/presentation/controllers/health_nutrition_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:disha_ai/app/theme/app_colors.dart';
import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:disha_ai/features/progress/presentation/controller/progress_controller.dart';
import 'package:disha_ai/features/dashboard/presentation/widgets/banner_carousel.dart';

class WeightCheckinScreen extends StatefulWidget {
  const WeightCheckinScreen({super.key});

  @override
  State<WeightCheckinScreen> createState() => _WeightCheckinScreenState();
}

class _WeightCheckinScreenState extends State<WeightCheckinScreen> {
  final HealthNutritionController _healthController =
      Get.isRegistered<HealthNutritionController>()
      ? Get.find<HealthNutritionController>()
      : Get.put(HealthNutritionController());

  final HealthProfileController _healthProfileController =
      Get.isRegistered<HealthProfileController>()
      ? Get.find<HealthProfileController>()
      : Get.put(HealthProfileController());

  final ProgressController _progressController =
      Get.isRegistered<ProgressController>()
      ? Get.find<ProgressController>()
      : Get.put(ProgressController());

  // ============================================================
  // OPTIONAL WEIGHT BANNER
  // ============================================================

  final GlobalKey<BannerCarouselState> _weightBannerKey =
      GlobalKey<BannerCarouselState>();

  bool _hasWeightBanners = false;

  void _onWeightBannerVisibilityChanged(bool visible) {
    if (!mounted || _hasWeightBanners == visible) return;

    setState(() {
      _hasWeightBanners = visible;
    });
  }

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  bool _isSubmitting = false;
  bool _loadingInitialData = true;
  double? _savedTarget;

  // Profile is authoritative when available; progress is a fallback.
  double? get _resolvedTarget {
    final profileTarget =
        _healthProfileController.healthProfile.value?.targetWeightKg;
    if (_savedTarget != null && _savedTarget! > 0) return _savedTarget;
    if (profileTarget != null && profileTarget > 0) return profileTarget;
    final progressTarget = _progressController.targetWeight;
    return progressTarget > 0 ? progressTarget : null;
  }

  String _formatWeight(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() => _loadingInitialData = true);
    // An optional API failing must not hide data returned by other APIs.
    final results = await Future.wait<bool>([
      _healthProfileController.getHealthProfile().then((_) => true).catchError((
        Object e,
      ) {
        debugPrint('WEIGHT PROFILE LOAD ERROR: $e');
        return false;
      }),
      _healthController.fetchHealthLogs().then((_) => true).catchError((
        Object e,
      ) {
        debugPrint('WEIGHT LOG LOAD ERROR: $e');
        return false;
      }),
      _progressController.refreshProgress().then((_) => true).catchError((
        Object e,
      ) {
        debugPrint('WEIGHT PROGRESS LOAD ERROR: $e');
        return false;
      }),
    ]);
    if (!mounted) return;

    final profile = _healthProfileController.healthProfile.value;
    final progressWeight = _progressController.currentWeight;
    final logWeight = _healthController.healthLog.value?.weightKg;
    final double? currentWeight = progressWeight > 0
        ? progressWeight
        : (logWeight != null && logWeight > 0 ? logWeight : profile?.weightKg);
    final targetWeight = _resolvedTarget;

    setState(() {
      _weightController.text = currentWeight != null && currentWeight > 0
          ? _formatWeight(currentWeight)
          : '';
      _targetController.text = targetWeight != null
          ? _formatWeight(targetWeight)
          : '';
      _savedTarget = targetWeight;
      _loadingInitialData = false;
    });
    debugPrint(
      'WEIGHT TARGET: profile=${profile?.targetWeightKg}, '
      'progress=${_progressController.targetWeight}, resolved=$targetWeight',
    );
    if (results.every((ok) => !ok)) {
      _showNotice(
        'Loading Failed',
        'Unable to refresh weight data. Pull down to retry.',
        error: true,
      );
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _showNotice(String title, String message, {bool error = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: error
          ? Colors.redAccent.withOpacity(0.9)
          : AppColors.surface,
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(16),
      icon: Icon(
        error ? Icons.error_outline : Icons.check_circle_rounded,
        color: error ? Colors.white : AppColors.primary,
      ),
    );
  }

  Future<void> _saveWeight() async {
    if (_isSubmitting || _loadingInitialData) return;

    final parsedWeight = double.tryParse(_weightController.text.trim());

    if (parsedWeight == null || parsedWeight < 20 || parsedWeight > 500) {
      _showNotice(
        'Invalid Input',
        'Please enter a realistic weight (20–500 kg).',
        error: true,
      );
      return;
    }

    final targetText = _targetController.text.trim();

    final double? target = targetText.isEmpty
        ? null
        : double.tryParse(targetText);

    if (targetText.isNotEmpty &&
        (target == null || target < 20 || target > 500)) {
      _showNotice(
        'Invalid Target',
        'Please enter a realistic target weight (20–500 kg).',
        error: true,
      );
      return;
    }

    final bool targetChanged = target != null && target != _savedTarget;

    final profile = _healthProfileController.healthProfile.value;

    if (profile == null) {
      _showNotice(
        'Profile Unavailable',
        'Could not load your health profile. Please retry.',
        error: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ============================================================
      // STEP 1: SAVE CURRENT WEIGHT TO DAILY HEALTH LOG
      // ============================================================

      final currentLog = _healthController.healthLog.value;

      final bool weightSaved = await _healthController.postHealthMetrics(
        steps: currentLog?.steps ?? 0,
        sleepHours: currentLog?.sleepHours ?? 7.5,
        caloriesConsumed: currentLog?.caloriesConsumed ?? 1800,
        caloriesBurned: currentLog?.caloriesBurned ?? 350,
        weightKg: parsedWeight,
        mood: currentLog?.mood ?? 'energetic',
        stressLevel: currentLog?.stressLevel ?? 'low',
      );

      if (!weightSaved) {
        _showNotice(
          'Sync Failed',
          'Could not save your weight. Please try again.',
          error: true,
        );
        return;
      }

      // ============================================================
      // STEP 2: UPDATE TARGET ONLY WHEN CHANGED
      //
      // IMPORTANT:
      // Preserve the onboarding baseline weight.
      // ============================================================

      if (targetChanged) {
        final bool goalSaved = await _healthProfileController
            .updateHealthProfile(
              name: profile.name ?? 'User',
              email: profile.email,
              mobile: profile.mobile,
              age: profile.age ?? 25,
              gender: profile.gender ?? 'other',
              heightCm: profile.heightCm ?? 0,

              // Preserve original onboarding weight.
              weightKg: profile.weightKg ?? _progressController.startingWeight,

              targetWeightKg: target,

              activityLevel: profile.activityLevel ?? 'lightly_active',
              sleepHoursTarget: profile.sleepHoursTarget ?? 7.5,
              stressLevel: profile.stressLevel ?? 'medium',
              dietType: profile.dietType ?? 'vegetarian',
              goals: profile.goals,
              conditions: profile.conditions,
              challenges: profile.challenges,
              allergies: profile.allergies,
              avoidedFoods: profile.avoidedFoods,
              sleepQuality: profile.sleepQuality ?? 'good',
            );

        if (!goalSaved) {
          _showNotice(
            'Partially Saved',
            'Weight logged successfully, but target goal could not be updated.',
            error: true,
          );
          return;
        }

        _savedTarget = target;
        if (mounted) setState(() {});
      }

      // ============================================================
      // STEP 3: REFRESH PROGRESS API
      // ============================================================

      await _progressController.refreshProgress();

      // ============================================================
      // STEP 4: REFRESH HEALTH PROFILE
      // ============================================================

      await _healthProfileController.getHealthProfile();
      if (!mounted) return;
      // Keep the verified saved goal visible even if the progress endpoint lags.
      if (targetChanged) {
        setState(() => _savedTarget = target);
      }

      Get.back();

      _showNotice(
        'Weight Updated',
        targetChanged
            ? 'Weight and target goal saved successfully.'
            : 'Successfully logged your weight as ${_formatWeight(parsedWeight)} kg!',
      );
    } catch (e) {
      debugPrint('WEIGHT CHECK-IN SAVE ERROR: $e');

      _showNotice(
        'Save Failed',
        'Unable to complete the update. Please try again.',
        error: true,
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
  // REFRESH WEIGHT DATA + OPTIONAL BANNERS
  // ============================================================

  Future<void> _refreshWeightScreen() async {
    await Future.wait<void>([
      _loadInitialData(),
      _weightBannerKey.currentState?.refreshBanners() ?? Future<void>.value(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          "Weight Check-in",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _refreshWeightScreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // ==================================================
                // OPTIONAL WEIGHT BANNER
                //
                // Banner exists:
                //   Display the Meditation-style carousel.
                //
                // No banner:
                //   Display nothing, including no extra spacing.
                // ==================================================
                _buildOptionalWeightBanner(),

                // ==================================================
                // EXISTING TARGET & GOAL CARD — UNCHANGED
                // ==================================================
                Obx(() {
                  final targetWeight = _resolvedTarget;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              "Target Goal",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              targetWeight == null
                                  ? 'Not set'
                                  : '${_formatWeight(targetWeight)} kg',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                        Column(
                          children: [
                            const Text(
                              "Goal Status",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "On Track",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 40),

                const Text(
                  "Enter your current weight",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Regular logging helps your AI coach fine-tune your nutrition and calorie goals.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 30),

                // WEIGHT INPUT FIELD
                TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    suffixText: "kg",
                    suffixStyle: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // OPTIONAL TARGET WEIGHT INPUT — SAME STYLE AS CURRENT WEIGHT
                const Text(
                  'Enter your target weight (optional)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set a personal weight goal to track your progress.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _targetController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    suffixText: 'kg',
                    suffixStyle: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // SUBMIT BUTTON
                ElevatedButton(
                  onPressed: (_isSubmitting || _loadingInitialData)
                      ? null
                      : _saveWeight,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: (_isSubmitting || _loadingInitialData)
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Save Weight Record",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // ============================================================
  // OPTIONAL WEIGHT BANNER
  //
  // Backend: GET /api/banners?category=Weight
  //
  // Banner available -> Display Meditation-style banner.
  // No banner -> Preserve existing screen without extra spacing.
  // ============================================================

  Widget _buildOptionalWeightBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasWeightBanners) const SizedBox(height: 24),

        BannerCarousel(
          key: _weightBannerKey,
          category: 'Weight',
          title: 'Your Weight Journey',
          subtitle: 'Small steps towards your personal health goals',
          height: 175,
          autoSlideDuration: const Duration(seconds: 5),
          showSectionTitle: true,
          onVisibilityChanged: _onWeightBannerVisibilityChanged,
        ),

        if (_hasWeightBanners) const SizedBox(height: 24),
      ],
    );
  }
}
