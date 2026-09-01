import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../widgets/onboarding_top_bar.dart';
import '../widgets/challenge_card.dart';

class ChallengeSelectionScreen extends StatefulWidget {
  const ChallengeSelectionScreen({super.key});

  @override
  State<ChallengeSelectionScreen> createState() =>
      _ChallengeSelectionScreenState();
}

class _ChallengeSelectionScreenState extends State<ChallengeSelectionScreen> {
  //==============================================================
  // ONBOARDING
  //==============================================================

  static const int _currentStep = 7;
  static const int _totalSteps = 9;

  //==============================================================
  // CONTROLLERS
  //==============================================================

  final TextEditingController _noteController = TextEditingController();

  // Inject the HealthProfileController
  final HealthProfileController _healthProfileController =
      Get.find<HealthProfileController>();

  //==============================================================
  // SELECTED CHALLENGES
  //==============================================================

  final Set<String> _selectedChallenges = {};

  //==============================================================
  // CHALLENGE LIST
  //==============================================================

  final List<ChallengeItem> _challenges = const [
    ChallengeItem(title: "Build Muscle", icon: Icons.fitness_center_rounded),
    ChallengeItem(
      title: "Lack of Energy",
      icon: Icons.battery_charging_full_rounded,
    ),
    ChallengeItem(
      title: "Weight Management",
      icon: Icons.monitor_weight_rounded,
    ),
    ChallengeItem(title: "Poor Sleep", icon: Icons.bedtime_rounded),
    ChallengeItem(
      title: "Stress & Anxiety",
      icon: Icons.self_improvement_rounded,
    ),
    ChallengeItem(
      title: "Irregular Eating",
      icon: Icons.restaurant_menu_rounded,
    ),
    ChallengeItem(
      title: "Motivation & Consistency",
      icon: Icons.emoji_events_rounded,
    ),
    ChallengeItem(title: "Other", icon: Icons.more_horiz_rounded),
  ];

  //==============================================================
  // DISPOSE
  //==============================================================

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  //==============================================================
  // RESPONSIVE SCALE
  //==============================================================

  double _scale(double width) {
    return (width / 390).clamp(0.88, 1.12);
  }

  double _spacing(double width, double value) {
    return value * _scale(width);
  }

  double _horizontalPadding(double width) {
    if (width <= 340) return 16;
    if (width <= 380) return 20;
    if (width <= 430) return 22;
    return 28;
  }

  //==============================================================
  // TOGGLE
  //==============================================================

  void _toggleChallenge(String value) {
    setState(() {
      if (_selectedChallenges.contains(value)) {
        _selectedChallenges.remove(value);
      } else {
        _selectedChallenges.add(value);
      }
    });
  }

  //==============================================================
  // NEXT & API INTEGRATION
  //==============================================================

  Future<void> _onNext() async {
    FocusScope.of(context).unfocus();

    if (_selectedChallenges.isEmpty) {
      Get.snackbar(
        "Required",
        "Please select at least one challenge.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        borderColor: AppColors.primary,
        borderWidth: 1,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final challengesList = _selectedChallenges.toList();
    final notes = _noteController.text;

    debugPrint("Selected Challenges API: $challengesList");
    debugPrint("Notes API: $notes");

    // CALL API
    final success = await _healthProfileController.saveChallenges(
      challenges: challengesList,
      notes: notes,
    );

    if (success) {
      Get.toNamed(AppRoutes.analyze);
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

  //==============================================================
  // SKIP
  //==============================================================

  void _skipOnboarding() {
    FocusScope.of(context).unfocus();
    Get.offAllNamed(AppRoutes.analyze);
  }

  //==============================================================
  // BUILD
  //==============================================================

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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding(width)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingTopBar(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
                onBack: () => Get.back(),
                onSkip: _skipOnboarding,
              ),
              SizedBox(height: _spacing(width, 24)),
              _buildTitle(width),
              SizedBox(height: _spacing(width, 8)),
              _buildSubtitle(width),
              SizedBox(height: _spacing(width, 24)),
              _buildChallengeList(width),
              SizedBox(height: _spacing(width, 28)),
              _buildNotesSection(width),
              SizedBox(height: _spacing(width, 30)),
              _buildNextButton(width),
              SizedBox(height: _spacing(width, 24)),
            ],
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
            vertical: 30,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingTopBar(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                  onBack: () => Get.back(),
                  onSkip: _skipOnboarding,
                ),
                const SizedBox(height: 30),
                _buildTitle(width),
                const SizedBox(height: 10),
                _buildSubtitle(width),
                const SizedBox(height: 30),
                _buildChallengeList(width),
                const SizedBox(height: 35),
                _buildNotesSection(width),
                const SizedBox(height: 35),
                _buildNextButton(width),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(double width) {
    final scale = _scale(width);
    final fontSize = (21 * scale).clamp(19.0, 24.0);

    return Text(
      "What are your biggest\nhealth challenges?",
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.18,
      ),
    );
  }

  Widget _buildSubtitle(double width) {
    final scale = _scale(width);
    final fontSize = (12.5 * scale).clamp(11.5, 14.0);

    return Text(
      "Choose all that apply. This helps personalize your experience.",
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.45,
      ),
    );
  }

  Widget _buildChallengeList(double width) {
    final scale = _scale(width);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _challenges.length,
      separatorBuilder: (_, __) => SizedBox(height: 12 * scale),
      itemBuilder: (context, index) {
        final item = _challenges[index];

        return ChallengeCard(
          title: item.title,
          icon: item.icon,
          selected: _selectedChallenges.contains(item.title),
          onTap: () => _toggleChallenge(item.title),
        );
      },
    );
  }

  Widget _buildNotesSection(double width) {
    final scale = _scale(width);
    final labelSize = (12 * scale).clamp(11.0, 14.0);
    final textSize = (12.5 * scale).clamp(11.5, 14.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Anything else you'd like us to know?",
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 8 * scale),
        TextField(
          controller: _noteController,
          minLines: 4,
          maxLines: 5,
          cursorColor: AppColors.primary,
          style: TextStyle(fontSize: textSize, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: "Tell us about any injuries, health concerns or goals...",
            hintStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: textSize,
            ),
            contentPadding: const EdgeInsets.all(16),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton(double width) {
    final scale = _scale(width);
    final height = (48 * scale).clamp(46.0, 54.0);
    final radius = (8 * scale).clamp(7.0, 10.0);
    final fontSize = (13 * scale).clamp(12.0, 15.0);

    // Disable button if nothing is selected to match other screens
    final enabled = _selectedChallenges.isNotEmpty;

    return Obx(() {
      final isSaving = _healthProfileController.isSaving.value;

      return SizedBox(
        width: double.infinity,
        height: height,
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
            boxShadow: enabled && !isSaving
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: isSaving ? null : _onNext,
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
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? Colors.black
                              : AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: enabled ? Colors.black : AppColors.textSecondary,
                        size: 18 * scale,
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}

class ChallengeItem {
  final String title;
  final IconData icon;

  const ChallengeItem({required this.title, required this.icon});
}
