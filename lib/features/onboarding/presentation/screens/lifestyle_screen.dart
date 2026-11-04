import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/onboarding_top_bar.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class LifestyleScreen extends StatefulWidget {
  const LifestyleScreen({super.key});

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen>
    with SingleTickerProviderStateMixin {
  //===============================================================
  // CONSTANTS
  //===============================================================

  static const int _totalSteps = 9;
  static const int _currentStep = 5;

  //===============================================================
  // CONTROLLERS
  //===============================================================

  // Inject the HealthProfileController
  final HealthProfileController _healthProfileController =
      Get.find<HealthProfileController>();

  //===============================================================
  // SLEEP HOURS
  //===============================================================

  final List<String> _sleepHours = const [
    "Less than 5 hours",
    "5-6 hours",
    "6-7 hours",
    "7-8 hours",
    "8-9 hours",
    "More than 9 hours",
  ];

  int _selectedSleepHour = 3;

  //===============================================================
  // SLEEP QUALITY
  //===============================================================

  final List<_SleepQuality> _qualities = const [
    _SleepQuality(
      label: "Poor",
      icon: Icons.sentiment_very_dissatisfied_rounded,
    ),
    _SleepQuality(label: "Fair", icon: Icons.sentiment_dissatisfied_rounded),
    _SleepQuality(label: "Good", icon: Icons.sentiment_neutral_rounded),
    _SleepQuality(
      label: "Very Good",
      icon: Icons.sentiment_satisfied_alt_rounded,
    ),
    _SleepQuality(
      label: "Excellent",
      icon: Icons.sentiment_very_satisfied_rounded,
    ),
  ];

  int? _selectedQuality = 4;

  // Duration-based estimated quality (not a clinical sleep assessment).
  static const List<int> _qualityBySleepHour = [0, 1, 2, 4, 3, 1];

  //===============================================================
  // ANIMATION
  //===============================================================

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  //===============================================================
  // LIFECYCLE
  //===============================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, .035), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  //===============================================================
  // NAVIGATION & API INTEGRATION
  //===============================================================

  void _goBack() {
    Get.back();
  }

  void _skip() {
    Get.toNamed(AppRoutes.foodPreference);
  }

  Future<void> _next() async {
    if (_selectedQuality == null) {
      _showValidationMessage();
      return;
    }

    final sleepDurationStr = _sleepHours[_selectedSleepHour];
    final qualityStr = _qualities[_selectedQuality!].label;

    // Convert "6-7 hours" string to a number for the API (e.g., average it to 6.5)
    double targetHours = 8.0; // default
    if (sleepDurationStr == "Less than 5 hours") {
      targetHours = 4.5;
    } else if (sleepDurationStr == "5-6 hours") {
      targetHours = 5.5;
    } else if (sleepDurationStr == "6-7 hours") {
      targetHours = 6.5;
    } else if (sleepDurationStr == "7-8 hours") {
      targetHours = 7.5;
    } else if (sleepDurationStr == "8-9 hours") {
      targetHours = 8.5;
    } else if (sleepDurationStr == "More than 9 hours") {
      targetHours = 9.5;
    }

    // Map UI Quality to API Stress Level string (low, medium, high)
    String apiStressLevel = "medium";
    if (qualityStr == "Excellent" || qualityStr == "Very Good") {
      apiStressLevel = "low";
    } else if (qualityStr == "Good" || qualityStr == "Fair") {
      apiStressLevel = "medium";
    } else if (qualityStr == "Poor") {
      apiStressLevel = "high";
    }

    debugPrint("Sleep Duration to API : $targetHours");
    debugPrint("Stress Level to API : $apiStressLevel");

    // CALL API
    final success = await _healthProfileController.saveLifestyle(
      sleepHoursTarget: targetHours,
      stressLevel: apiStressLevel,
    );

    if (success) {
      Get.toNamed(AppRoutes.foodPreference);
    } else {
      Get.snackbar(
        "Error",
        _healthProfileController.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  void _showValidationMessage() {
    Get.snackbar(
      "Sleep Quality",
      "Please rate your sleep quality.",
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      borderColor: AppColors.primary,
      borderWidth: 1,
      duration: const Duration(seconds: 2),
    );
  }

  // ============================================================
  // SKIP
  // ============================================================

  void _skipOnboarding() {
    FocusScope.of(context).unfocus();
    Get.toNamed(AppRoutes.foodPreference);
  }

  //===============================================================
  // BUILD
  //===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            if (width >= 700) {
              return _buildTabletLayout(width: width, height: height);
            }

            return _buildPhoneLayout(width: width, height: height);
          },
        ),
      ),
    );
  }

  //===============================================================
  // PHONE
  //===============================================================

  Widget _buildPhoneLayout({required double width, required double height}) {
    final horizontalPadding = _getHorizontalPadding(width);
    final compact = height < 680;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            _getTopPadding(height),
            horizontalPadding,
            20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height - 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingTopBar(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  onBack: () => Get.back(),
                  onSkip: _skipOnboarding,
                ),
                SizedBox(height: compact ? 24 : 30),
                _buildHeader(width: width, compact: compact),
                SizedBox(height: compact ? 22 : 28),
                _buildSleepHoursSection(width: width, compact: compact),
                SizedBox(height: compact ? 24 : 28),
                _buildSleepQualitySection(width: width, compact: compact),
                SizedBox(height: compact ? 34 : 42),
                _buildNextButton(width: width),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //===============================================================
  // TABLET
  //===============================================================

  Widget _buildTabletLayout({required double width, required double height}) {
    final contentWidth = width >= 1100 ? 620.0 : 560.0;

    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OnboardingTopBar(
                    currentStep: _currentStep,
                    totalSteps: _totalSteps,
                    onBack: () => Get.back(),
                    onSkip: _skipOnboarding,
                  ),
                  const SizedBox(height: 34),
                  _buildHeader(width: contentWidth, compact: false),
                  const SizedBox(height: 30),
                  _buildSleepHoursSection(width: contentWidth, compact: false),
                  const SizedBox(height: 30),
                  _buildSleepQualitySection(
                    width: contentWidth,
                    compact: false,
                  ),
                  const SizedBox(height: 40),
                  _buildNextButton(width: contentWidth),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //===============================================================
  // RESPONSIVE HELPERS
  //===============================================================

  double _getHorizontalPadding(double width) {
    if (width <= 340) return 16;
    if (width <= 375) return 18;
    if (width <= 430) return 22;
    if (width <= 600) return 28;
    return 32;
  }

  double _getTopPadding(double height) {
    if (height <= 600) return 10;
    if (height <= 700) return 14;
    if (height <= 850) return 18;
    return 24;
  }

  double _getScale(double width) {
    return (width / 390).clamp(0.88, 1.15);
  }

  //===============================================================
  // HEADER
  //===============================================================

  Widget _buildHeader({required double width, required bool compact}) {
    final scale = _getScale(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tell us about\nyour sleep",
          style: TextStyle(
            fontSize: (22 * scale).clamp(20.0, 25.0),
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.22,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        Text(
          "Your sleep plays a big role in your\nhealth and energy.",
          style: TextStyle(
            fontSize: (13.5 * scale).clamp(12.0, 15.0),
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  //===============================================================
  // SLEEP HOURS SECTION
  //===============================================================

  Widget _buildSleepHoursSection({
    required double width,
    required bool compact,
  }) {
    final scale = _getScale(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "How many hours do you sleep\non average ?",
          style: TextStyle(
            fontSize: (13 * scale).clamp(12.0, 14.5),
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: compact ? 14 : 16),
        GestureDetector(
          onTap: _showSleepHoursBottomSheet,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(.75)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.nightlight_round,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _sleepHours[_selectedSleepHour],
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  //===============================================================
  // SLEEP QUALITY
  //===============================================================

  Widget _buildSleepQualitySection({
    required double width,
    required bool compact,
  }) {
    final scale = _getScale(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "How would you rate your\nsleep quality ?",
          style: TextStyle(
            fontSize: (13 * scale).clamp(12.0, 14.5),
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: compact ? 16 : 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_qualities.length, (index) {
            final selected = _selectedQuality == index;

            return GestureDetector(
              onTap: null,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: AppColors.primary,
                        width: selected ? 2 : 1.4,
                      ),
                    ),
                    child: Icon(
                      _qualities[index].icon,
                      color: selected ? Colors.black : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 52,
                    child: Text(
                      _qualities[index].label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  //===============================================================
  // NEXT BUTTON
  //===============================================================

  Widget _buildNextButton({required double width}) {
    final scale = _getScale(width);
    final enabled = _selectedQuality != null;
    final radius = (9 * scale).clamp(8.0, 11.0);

    return Obx(() {
      final isSaving = _healthProfileController.isSaving.value;

      return SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: enabled && !isSaving
                ? const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  )
                : LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(.35),
                      AppColors.primary.withOpacity(.35),
                    ],
                  ),
          ),
          child: ElevatedButton(
            onPressed: isSaving ? null : _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: isSaving
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
                      Text(
                        "Next",
                        style: TextStyle(
                          color: enabled
                              ? Colors.black
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: enabled ? Colors.black : AppColors.textSecondary,
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  //===============================================================
  // TOP BAR
  //===============================================================

  Widget _buildTopBar({required double width, required bool compact}) {
    final scale = _getScale(width);

    return SizedBox(
      height: compact ? 30 : 34,
      child: Row(
        children: [
          InkWell(
            onTap: _goBack,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_rounded,
                size: (22 * scale).clamp(20.0, 25.0),
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _skip,
            child: Text(
              "Skip",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: (13.5 * scale).clamp(12.5, 15.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //===============================================================
  // PROGRESS
  //===============================================================

  Widget _buildProgressSection({required double width, required bool compact}) {
    final scale = _getScale(width);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: (5 * scale).clamp(4.0, 6.0),
              child: LinearProgressIndicator(
                value: _currentStep / _totalSteps,
                backgroundColor: AppColors.primary.withOpacity(.15),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          "$_currentStep/$_totalSteps",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: (12 * scale).clamp(11.0, 13.5),
          ),
        ),
      ],
    );
  }

  //===============================================================
  // BOTTOM SHEET
  //===============================================================

  void _showSleepHoursBottomSheet() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _sleepHours.length,
            itemBuilder: (_, index) {
              final selected = _selectedSleepHour == index;

              return ListTile(
                title: Text(
                  _sleepHours[index],
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                trailing: selected
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedSleepHour = index;
                    _selectedQuality = _qualityBySleepHour[index];
                  });
                  Get.back();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

//===============================================================
// MODEL
//===============================================================

class _SleepQuality {
  final String label;
  final IconData icon;

  const _SleepQuality({required this.label, required this.icon});
}
