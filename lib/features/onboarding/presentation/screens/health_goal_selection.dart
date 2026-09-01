import 'package:disha_ai/features/onboarding/presentation/controllers/master_data_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/master_data_model.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/health_profile_controller.dart';
import '../widgets/onboarding_top_bar.dart';

class PrimaryHealthGoalScreen extends StatefulWidget {
  const PrimaryHealthGoalScreen({super.key});

  @override
  State<PrimaryHealthGoalScreen> createState() =>
      _PrimaryHealthGoalScreenState();
}

class _PrimaryHealthGoalScreenState extends State<PrimaryHealthGoalScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalSteps = 9;
  static const int _currentStep = 1;

  late final HealthProfileController _controller;
  late final MasterDataController
  _masterDataController; // 💡 Master data controller

  int? _selectedGoalIndex;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<HealthProfileController>()) {
      _controller = Get.find<HealthProfileController>();
    } else {
      _controller = Get.put(HealthProfileController(), permanent: false);
    }

    // Initialize MasterDataController
    _masterDataController = Get.put(MasterDataController());

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _loadExistingGoal();
  }

  Future<void> _loadExistingGoal() async {
    // Wait until master data is fetched if needed, then sync existing choice
    await _masterDataController.fetchMasterData();

    final localGoal = _controller.primaryHealthGoal;
    if (localGoal != null && localGoal.isNotEmpty) {
      _selectExistingGoal(localGoal);
      return;
    }

    final existingProfile = _controller.healthProfile.value;
    if (existingProfile != null && existingProfile.goals.isNotEmpty) {
      final goal = existingProfile.goals.first;
      _controller.setPrimaryHealthGoal(goal);
      _selectExistingGoal(goal);
      return;
    }

    final success = await _controller.getHealthProfile();
    if (!mounted || !success) return;

    final profile = _controller.healthProfile.value;
    if (profile != null && profile.goals.isNotEmpty) {
      final goal = profile.goals.first;
      _controller.setPrimaryHealthGoal(goal);
      _selectExistingGoal(goal);
    }
  }

  void _selectExistingGoal(String apiValue) {
    final goals = _masterDataController.masterData.value?.goals ?? [];
    final index = goals.indexWhere((goal) => goal.slug == apiValue);

    if (index == -1 || !mounted) return;

    setState(() {
      _selectedGoalIndex = index;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose(); // if any
    super.dispose();
  }

  final TextEditingController _searchController = TextEditingController();

  void _goBack() {
    FocusScope.of(context).unfocus();
    Get.back();
  }

  void _selectGoal(int index) {
    setState(() {
      _selectedGoalIndex = index;
    });
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();

    if (_selectedGoalIndex == null) {
      _showValidationMessage();
      return;
    }

    final goals = _masterDataController.masterData.value?.goals ?? [];
    if (_selectedGoalIndex! < goals.length) {
      final selectedGoal = goals[_selectedGoalIndex!];
      _controller.setPrimaryHealthGoal(selectedGoal.slug ?? '');
    }

    if (!mounted) return;
    Get.toNamed(AppRoutes.personalInfo);
  }

  void _skipOnboarding() {
    FocusScope.of(context).unfocus();
    Get.toNamed(AppRoutes.personalInfo);
  }

  void _showValidationMessage() {
    Get.snackbar(
      'Select your goal'.tr,
      'Please select a health goal to continue.'.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      borderColor: AppColors.primary,
      borderWidth: 1,
      duration: const Duration(seconds: 2),
    );
  }

  // Helper mapping string icon names to Material IconData
  IconData _getIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'fitness':
      case 'fitness_center':
        return Icons.fitness_center_outlined;
      case 'weight':
      case 'monitor_weight':
        return Icons.monitor_weight_outlined;
      case 'run':
      case 'directions_run':
        return Icons.directions_run_outlined;
      case 'bedtime':
      case 'sleep':
        return Icons.bedtime_outlined;
      case 'stress':
      case 'self_improvement':
        return Icons.self_improvement_outlined;
      case 'medical':
      case 'medical_services':
        return Icons.medical_services_outlined;
      default:
        return Icons.favorite_border_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Obx(() {
          if (_masterDataController.isLoading.value &&
              _masterDataController.masterData.value == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              if (width >= 700) {
                return _buildTabletLayout(width: width, height: height);
              }
              return _buildPhoneLayout(width: width, height: height);
            },
          );
        }),
      ),
    );
  }

  Widget _buildPhoneLayout({required double width, required double height}) {
    final horizontalPadding = _getHorizontalPadding(width);
    final compactHeight = height < 680;

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
                  onBack: _goBack,
                  onSkip: _skipOnboarding,
                ),
                SizedBox(height: compactHeight ? 24 : 30),
                _buildHeader(
                  width: width - (horizontalPadding * 2),
                  compact: compactHeight,
                ),
                SizedBox(height: compactHeight ? 20 : 26),
                _buildGoalList(
                  width: width - (horizontalPadding * 2),
                  compact: compactHeight,
                ),
                SizedBox(height: compactHeight ? 22 : 30),
                _buildNextButton(width: width - (horizontalPadding * 2)),
                SizedBox(height: compactHeight ? 12 : 18),
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
            height: height,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OnboardingTopBar(
                    currentStep: _currentStep,
                    totalSteps: _totalSteps,
                    onBack: _goBack,
                    onSkip: _skipOnboarding,
                  ),
                  const SizedBox(height: 34),
                  _buildHeader(width: contentWidth, compact: false),
                  const SizedBox(height: 30),
                  _buildGoalList(width: contentWidth, compact: false),
                  const SizedBox(height: 36),
                  _buildNextButton(width: contentWidth),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required double width, required bool compact}) {
    final scale = _getScale(width);
    final titleSize = (22.0 * scale).clamp(20.0, 25.0);
    final descriptionSize = (13.5 * scale).clamp(12.0, 15.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is your primary\nhealth goal?'.tr,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.22,
            letterSpacing: -0.1,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        Text(
          'Choose the goal that matters most to you'.tr,
          style: TextStyle(
            fontSize: descriptionSize,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalList({required double width, required bool compact}) {
    final goals = _masterDataController.masterData.value?.goals ?? [];
    final cardSpacing = compact ? 9.0 : 11.0;

    if (goals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            "No goals available",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(goals.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == goals.length - 1 ? 0 : cardSpacing,
          ),
          child: _buildGoalCard(
            goal: goals[index],
            index: index,
            width: width,
            compact: compact,
          ),
        );
      }),
    );
  }

  Widget _buildGoalCard({
    required GoalItem goal,
    required int index,
    required double width,
    required bool compact,
  }) {
    final scale = _getScale(width);
    final selected = _selectedGoalIndex == index;

    final cardHeight = compact
        ? (66 * scale).clamp(62.0, 70.0)
        : (72 * scale).clamp(68.0, 78.0);

    final radius = (9 * scale).clamp(8.0, 11.0);
    final iconContainerSize = (42 * scale).clamp(38.0, 46.0);
    final titleSize = (12.5 * scale).clamp(11.5, 14.0);
    final descriptionSize = (10.5 * scale).clamp(9.5, 12.0);
    final radioSize = (20 * scale).clamp(18.0, 22.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectGoal(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: double.infinity,
        height: cardHeight,
        padding: EdgeInsets.symmetric(
          horizontal: 9 * scale,
          vertical: 8 * scale,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.72),
            width: selected ? 1.35 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.88),
                borderRadius: BorderRadius.circular(
                  (6 * scale).clamp(5.0, 7.0),
                ),
              ),
              child: Icon(
                _getIconData(goal.icon),
                size: (21 * scale).clamp(19.0, 23.0),
                color: Colors.black,
              ),
            ),
            SizedBox(width: 11 * scale),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 3 * scale),
                  Text(
                    goal.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: descriptionSize,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8 * scale),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: radioSize,
              height: radioSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: selected ? 2.0 : 1.4,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: radioSize * 0.48,
                        height: radioSize * 0.48,
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

  Widget _buildNextButton({required double width}) {
    final scale = _getScale(width);
    final buttonHeight = (51 * scale).clamp(48.0, 56.0);
    final fontSize = (14 * scale).clamp(13.0, 15.5);
    final iconSize = (18 * scale).clamp(17.0, 20.0);
    final radius = (9 * scale).clamp(8.0, 11.0);
    final enabled = _selectedGoalIndex != null;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                )
              : LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.35),
                    AppColors.primary.withOpacity(0.35),
                  ],
                ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: enabled ? _next : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            disabledForegroundColor: AppColors.textSecondary,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Next'.tr,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: enabled ? Colors.black : AppColors.textSecondary,
                  height: 1,
                ),
              ),
              SizedBox(width: 9 * scale),
              Icon(
                Icons.arrow_forward_rounded,
                size: iconSize,
                color: enabled ? Colors.black : AppColors.textSecondary,
              ),
            ],
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
}
