import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../widgets/ai_success_illustration.dart';
import '../widgets/onboarding_top_bar.dart';

class AnalysisCompleteScreen extends StatefulWidget {
  const AnalysisCompleteScreen({super.key});

  @override
  State<AnalysisCompleteScreen> createState() => _AnalysisCompleteScreenState();
}

class _AnalysisCompleteScreenState extends State<AnalysisCompleteScreen>
    with TickerProviderStateMixin {
  //==============================================================
  // CONTROLLERS
  //==============================================================

  final AiController _aiController = Get.put(AiController());
  final HealthProfileController _healthProfileController = Get.put(
    HealthProfileController(),
  );

  //==============================================================
  // ONBOARDING
  //==============================================================

  static const int _currentStep = 9;
  static const int _totalSteps = 9;

  //==============================================================
  // ANIMATION
  //==============================================================

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();

    // 💡 Fetch profile analysis automatically on load if empty
    if (_aiController.profileAnalysis.value == null) {
      _aiController.analyzeProfile();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  //==============================================================
  // DYNAMIC PARSERS FROM API (Matching ProgressScreen style)
  //==============================================================

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

  String get _primaryGoal {
    final localGoal = _healthProfileController.primaryHealthGoal;
    if (localGoal != null && localGoal.isNotEmpty) return localGoal;

    final profileGoals = _healthProfileController.healthProfile.value?.goals;
    if (profileGoals != null && profileGoals.isNotEmpty) {
      return profileGoals.first.capitalizeFirst ?? profileGoals.first;
    }
    return "Personalized Fitness";
  }

  String get _formattedWaterIntake {
    final waterMl =
        _analysisData?['daily_water_recommendation_ml'] ??
        _analysisData?['water_intake_ml'];
    if (waterMl != null) {
      final num? ml = num.tryParse(waterMl.toString());
      if (ml != null) {
        final liters = (ml / 1000).toStringAsFixed(1);
        return "$liters L / day (${ml.toInt()} ml)";
      }
    }
    return "2.5 L / day";
  }

  String get _formattedCalories {
    final calories =
        _analysisData?['daily_calorie_recommendation'] ??
        _analysisData?['calorie_target'];
    if (calories != null) {
      return "$calories kcal / day";
    }
    return "2,000 kcal";
  }

  String get _bmiAndCategory {
    final bmi = _analysisData?['bmi'] ?? _analysisData?['BMI'];
    final category =
        _analysisData?['health_category']?.toString() ??
        _analysisData?['bmi_category']?.toString();

    if (bmi != null && category != null) {
      return "$bmi ($category)";
    } else if (bmi != null) {
      return "$bmi";
    } else if (category != null) {
      return category;
    }
    return "Healthy (23.5)";
  }

  //==============================================================
  // RESPONSIVE
  //==============================================================

  double _scale(double width) => (width / 390).clamp(.88, 1.12);
  double _spacing(double width, double value) => value * _scale(width);
  double _horizontalPadding(double width) {
    if (width <= 340) return 16;
    if (width <= 380) return 20;
    if (width <= 430) return 22;
    return 28;
  }

  //==============================================================
  // ACTIONS
  //==============================================================

  Future<void> _generateAndNavigate() async {
    FocusScope.of(context).unfocus();

    final success = await _aiController.generateHealthPlan();

    if (success) {
      Get.offNamed(AppRoutes.generatedPlan);
    } else {
      Get.snackbar(
        "Plan Generation Failed",
        _aiController.errorMessage.value.isNotEmpty
            ? _aiController.errorMessage.value
            : "Something went wrong. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  //==============================================================
  // BUILD
  //==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            if (width >= 700 || width > height) {
              return _buildWideLayout(width: width, height: height);
            }
            return _buildPhoneLayout(width: width, height: height);
          },
        ),
      ),
    );
  }

  Widget _buildPhoneLayout({required double width, required double height}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _horizontalPadding(width),
            vertical: 20,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingTopBar(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  onBack: () => Get.back(),
                  onSkip: _generateAndNavigate,
                ),
                SizedBox(height: _spacing(width, 24)),
                const Center(child: AICompletionIllustration()),
                SizedBox(height: _spacing(width, 24)),
                Center(child: _buildTitle(width)),
                SizedBox(height: _spacing(width, 8)),
                _buildSubtitle(width),
                SizedBox(height: _spacing(width, 24)),
                _buildSummaryCard(width),
                SizedBox(height: _spacing(width, 28)),
                _buildPrimaryButton(width),
                SizedBox(height: _spacing(width, 12)),
                Center(child: _buildSecondaryButton(width)),
                SizedBox(height: _spacing(width, 22)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout({required double width, required double height}) {
    final horizontalPadding = width >= 1200
        ? 100.0
        : width >= 900
        ? 70.0
        : 40.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 28,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  OnboardingTopBar(
                    currentStep: _currentStep,
                    totalSteps: _totalSteps,
                    onBack: () => Get.back(),
                    onSkip: _generateAndNavigate,
                  ),
                  const SizedBox(height: 30),
                  const AICompletionIllustration(),
                  const SizedBox(height: 30),
                  _buildTitle(width),
                  const SizedBox(height: 12),
                  _buildSubtitle(width),
                  const SizedBox(height: 30),
                  _buildSummaryCard(width),
                  const SizedBox(height: 32),
                  _buildPrimaryButton(width),
                  const SizedBox(height: 16),
                  _buildSecondaryButton(width),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(double width) {
    final scale = _scale(width);
    return Text(
      "You're All Set!",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: (24 * scale).clamp(21.0, 28.0),
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.2,
      ),
    );
  }

  Widget _buildSubtitle(double width) {
    final scale = _scale(width);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale),
      child: Text(
        "Based on our analysis, here is your baseline health profile. Next, we will generate your daily plan.",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: (13.5 * scale).clamp(12.0, 15.0),
          height: 1.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double width) {
    final scale = _scale(width);

    // 💡 Wrapped in Obx to dynamically react when profileAnalysis or healthProfile updates
    return Obx(() {
      final userProfile = _healthProfileController.healthProfile.value;
      final isAnalyzing = _aiController.isProfileAnalyzing.value;

      return Container(
        padding: EdgeInsets.all(18 * scale),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withOpacity(.35)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Primary Goal",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12 * scale,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _primaryGoal,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16 * scale,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: AppColors.primary.withOpacity(.2)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "AI Health Metrics",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15 * scale,
                  ),
                ),
                if (isAnalyzing)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _buildInfoTile(Icons.speed_rounded, "BMI Status", _bmiAndCategory),
            const SizedBox(height: 10),
            _buildInfoTile(
              Icons.local_fire_department_rounded,
              "Calorie Target",
              _formattedCalories,
            ),
            const SizedBox(height: 10),
            _buildInfoTile(
              Icons.water_drop_rounded,
              "Water Intake",
              _formattedWaterIntake,
            ),
            const SizedBox(height: 10),
            if (userProfile?.dietType != null) ...[
              _buildInfoTile(
                Icons.restaurant_menu_rounded,
                "Diet Type",
                userProfile!.dietType!.capitalizeFirst ?? userProfile.dietType!,
              ),
              const SizedBox(height: 10),
            ],
            if (userProfile?.activityLevel != null) ...[
              _buildInfoTile(
                Icons.directions_run_rounded,
                "Activity",
                userProfile!.activityLevel!
                        .replaceAll('_', ' ')
                        .capitalizeFirst ??
                    userProfile.activityLevel!,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(double width) {
    final scale = _scale(width);
    final height = (50 * scale).clamp(48.0, 56.0);
    final radius = (10 * scale).clamp(8.0, 12.0);

    return Obx(() {
      final isGenerating = _aiController.isGeneratingPlan.value;

      return SizedBox(
        width: double.infinity,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: isGenerating
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(.35),
                      AppColors.primary.withOpacity(.35),
                    ],
                  )
                : const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
            boxShadow: isGenerating
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: isGenerating ? null : _generateAndNavigate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: isGenerating
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.black54,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                      SizedBox(width: 10 * scale),
                      Text(
                        "Generate My Plan",
                        style: TextStyle(
                          fontSize: (13.5 * scale).clamp(12.0, 15.0),
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.black,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  Widget _buildSecondaryButton(double width) {
    final scale = _scale(width);
    return TextButton.icon(
      onPressed: () => Get.offAllNamed(AppRoutes.primaryHealthGoal),
      icon: Icon(
        Icons.edit_outlined,
        size: 18 * scale,
        color: AppColors.textSecondary,
      ),
      label: Text(
        "Edit Information",
        style: TextStyle(
          fontSize: (13 * scale).clamp(12.0, 15.0),
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 12 * scale,
        ),
      ),
    );
  }
}
