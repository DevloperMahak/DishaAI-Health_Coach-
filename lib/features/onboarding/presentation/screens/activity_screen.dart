import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/onboarding_top_bar.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class ActivityLevelScreen extends StatefulWidget {
  const ActivityLevelScreen({super.key});

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen>
    with SingleTickerProviderStateMixin {
  //===============================================================
  // CONSTANTS
  //===============================================================

  static const int _totalSteps = 9;
  static const int _currentStep = 4;

  //===============================================================
  // CONTROLLERS
  //===============================================================

  // Inject the HealthProfileController
  final HealthProfileController _healthProfileController =
      Get.find<HealthProfileController>();

  //===============================================================
  // ACTIVITY LIST
  //===============================================================

  final List<_ActivityLevel> _activities = const [
    _ActivityLevel(
      title: "Sedentary",
      description: "Little or no exercise during the week",
      icon: Icons.weekend_outlined,
    ),
    _ActivityLevel(
      title: "Lightly Active",
      description: "Light exercise 1–3 days every week",
      icon: Icons.directions_walk_outlined,
    ),
    _ActivityLevel(
      title: "Moderately Active",
      description: "Moderate exercise 3–5 days every week",
      icon: Icons.directions_run_outlined,
    ),
    _ActivityLevel(
      title: "Very Active",
      description: "Hard exercise 6–7 days every week",
      icon: Icons.fitness_center_outlined,
    ),
    _ActivityLevel(
      title: "Extra Active",
      description: "Athlete or physically demanding work",
      icon: Icons.sports_gymnastics_outlined,
    ),
  ];

  int? _selectedActivity;

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
    Get.toNamed(AppRoutes.lifestyle);
  }

  Future<void> _next() async {
    if (_selectedActivity == null) {
      _showValidation();
      return;
    }

    final selectedTitle = _activities[_selectedActivity!].title;

    // Map UI string to API string
    String apiActivityLevel;
    switch (selectedTitle) {
      case "Sedentary":
        apiActivityLevel = "sedentary";
        break;
      case "Lightly Active":
        apiActivityLevel = "lightly_active";
        break;
      case "Moderately Active":
        apiActivityLevel = "moderately_active";
        break;
      case "Very Active":
        apiActivityLevel = "very_active";
        break;
      case "Extra Active":
        apiActivityLevel = "extra_active";
        break;
      default:
        apiActivityLevel = "lightly_active";
    }

    // CALL API with mapped value
    final success = await _healthProfileController.saveActivityLevel(
      activityLevel: apiActivityLevel,
    );

    if (success) {
      Get.toNamed(AppRoutes.lifestyle);
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

  void _showValidation() {
    Get.snackbar(
      "Select Activity",
      "Please select your activity level.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      borderColor: AppColors.primary,
      borderWidth: 1,
      margin: const EdgeInsets.all(16),
    );
  }

  // ============================================================
  // SKIP
  // ============================================================

  void _skipOnboarding() {
    FocusScope.of(context).unfocus();
    Get.toNamed(AppRoutes.lifestyle);
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
                _buildActivityList(width: width, compact: compact),
                SizedBox(height: compact ? 26 : 32),
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
            height: height,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                  _buildActivityList(width: contentWidth, compact: false),
                  const SizedBox(height: 34),
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
  // TOP BAR
  //===============================================================

  Widget _buildTopBar({required double width, required bool compact}) {
    final scale = _getScale(width);

    return SizedBox(
      height: compact ? 30 : 34,
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
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
          ),
          const Spacer(),
          GestureDetector(
            onTap: _skip,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                "Skip",
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: (13.5 * scale).clamp(12.5, 15.0),
                  fontWeight: FontWeight.w600,
                ),
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
    final progressHeight = (5 * scale).clamp(4.0, 6.0);
    final textSize = (12 * scale).clamp(11.0, 13.5);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: progressHeight,
              child: LinearProgressIndicator(
                value: _currentStep / _totalSteps,
                backgroundColor: AppColors.primary.withOpacity(.16),
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
            fontSize: textSize,
          ),
        ),
      ],
    );
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
          "What is your activity\nlevel ?",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: (22 * scale).clamp(20.0, 25.0),
            height: 1.22,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        Text(
          "This helps us plan the right recommendations.",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: (13.5 * scale).clamp(12.0, 15.0),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  //===============================================================
  // LIST
  //===============================================================

  Widget _buildActivityList({required double width, required bool compact}) {
    return Column(
      children: List.generate(
        _activities.length,
        (index) => Padding(
          padding: EdgeInsets.only(
            bottom: index == _activities.length - 1 ? 0 : (compact ? 10 : 12),
          ),
          child: _buildActivityCard(
            activity: _activities[index],
            index: index,
            width: width,
            compact: compact,
          ),
        ),
      ),
    );
  }

  //===============================================================
  // CARD
  //===============================================================

  Widget _buildActivityCard({
    required _ActivityLevel activity,
    required int index,
    required double width,
    required bool compact,
  }) {
    final scale = _getScale(width);
    final selected = _selectedActivity == index;
    final cardHeight = compact ? 72.0 : 76.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedActivity = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: cardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(.12)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(activity.icon, color: Colors.black, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: (13 * scale).clamp(12.0, 14.5),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    activity.description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: (11 * scale).clamp(10.0, 12.0),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: selected ? 2 : 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  //===============================================================
  // NEXT BUTTON
  //===============================================================

  Widget _buildNextButton({required double width}) {
    final enabled = _selectedActivity != null;
    final scale = _getScale(width);

    return Obx(() {
      final isSaving = _healthProfileController.isSaving.value;

      return SizedBox(
        width: double.infinity,
        height: (51 * scale).clamp(48.0, 56.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
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
                borderRadius: BorderRadius.circular(10),
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
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: enabled ? Colors.black : AppColors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}

//===============================================================
// MODEL
//===============================================================

class _ActivityLevel {
  final String title;
  final String description;
  final IconData icon;

  const _ActivityLevel({
    required this.title,
    required this.description,
    required this.icon,
  });
}
