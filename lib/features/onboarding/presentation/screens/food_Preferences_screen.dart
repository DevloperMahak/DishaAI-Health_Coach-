import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/onboarding_top_bar.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class FoodPreferencesScreen extends StatefulWidget {
  const FoodPreferencesScreen({super.key});

  @override
  State<FoodPreferencesScreen> createState() => _FoodPreferencesScreenState();
}

class _FoodPreferencesScreenState extends State<FoodPreferencesScreen>
    with SingleTickerProviderStateMixin {
  //===============================================================
  // CONSTANTS
  //===============================================================

  static const int _totalSteps = 9;
  static const int _currentStep = 6;

  //===============================================================
  // CONTROLLERS
  //===============================================================

  final HealthProfileController _healthProfileController =
      Get.find<HealthProfileController>();

  //===============================================================
  // FOOD OPTIONS (Restricted to the 4 backend-supported values)
  //===============================================================

  final List<_FoodPreference> _foods = const [
    _FoodPreference(
      title: "Vegetarian",
      icon: Icons.eco_outlined,
      apiValue: "vegetarian",
    ),
    _FoodPreference(
      title: "Non-Vegetarian",
      icon: Icons.restaurant_outlined,
      apiValue: "non_vegetarian",
    ),
    _FoodPreference(
      title: "Eggitarian",
      icon: Icons.egg_alt_outlined,
      apiValue: "eggetarian",
    ),
    _FoodPreference(
      title: "Vegan",
      icon: Icons.spa_outlined,
      apiValue: "vegan",
    ),
  ];

// ============================================================
// SELECTED FOOD
// No option selected by default.
// User must manually select their diet preference.
// ============================================================

int? _selectedFood;

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

  Future<void> _next() async {
    if (_selectedFood == null) {
      _showValidation();
      return;
    }

    final dietType = _foods[_selectedFood!].apiValue;

    debugPrint("Selected Food to API : $dietType");

    // CALL API
    final success = await _healthProfileController.saveDietType(
      dietType: dietType,
    );

    if (success) {
      Get.toNamed(AppRoutes.challengeSelection);
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
      "Select Preference",
      "Please select your diet preference.",
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      borderColor: AppColors.primary,
      borderWidth: 1,
      duration: const Duration(seconds: 2),
    );
  }

  void _skipOnboarding() {
    FocusScope.of(context).unfocus();
    Get.toNamed(AppRoutes.challengeSelection);
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
                SizedBox(height: compact ? 24 : 28),
                _buildFoodList(width: width, compact: compact),
                SizedBox(height: compact ? 28 : 36),
                _buildNextButton(width: width),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                  _buildFoodList(width: contentWidth, compact: false),
                  const SizedBox(height: 38),
                  _buildNextButton(width: contentWidth),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildHeader({required double width, required bool compact}) {
    final scale = _getScale(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's your diet\npreference ?",
          style: TextStyle(
            fontSize: (22 * scale).clamp(20.0, 25.0),
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.22,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        Text(
          "This helps us personalize your meal\nrecommendations.",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: (13.5 * scale).clamp(12.0, 15.0),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodList({required double width, required bool compact}) {
    return Column(
      children: List.generate(
        _foods.length,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildFoodCard(
            food: _foods[index],
            index: index,
            width: width,
            compact: compact,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodCard({
    required _FoodPreference food,
    required int index,
    required double width,
    required bool compact,
  }) {
    final scale = _getScale(width);
    final selected = _selectedFood == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFood = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: compact ? 60 : 66,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withOpacity(.75),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 42 : 46,
              height: compact ? 42 : 46,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withOpacity(.18)
                    : AppColors.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                food.icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: compact ? 22 : 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                food.title,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: (12.5 * scale).clamp(11.5, 14),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primary),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.black, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton({required double width}) {
    final enabled = _selectedFood != null;
    final radius = (_getScale(width) * 9).clamp(8.0, 11.0);

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
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? Colors.black
                              : AppColors.textSecondary,
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
}

class _FoodPreference {
  final String title;
  final IconData icon;
  final String apiValue;

  const _FoodPreference({
    required this.title,
    required this.icon,
    required this.apiValue,
  });
}
