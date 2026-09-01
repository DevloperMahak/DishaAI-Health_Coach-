import 'package:disha_ai/features/onboarding/presentation/controllers/master_data_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/health_profile_controller.dart';
import '../widgets/onboarding_top_bar.dart';
import '../../data/models/master_data_model.dart'; // 💡 ConditionItem model

class HealthConditionScreen extends StatefulWidget {
  const HealthConditionScreen({super.key});

  @override
  State<HealthConditionScreen> createState() => _HealthConditionScreenState();
}

class _HealthConditionScreenState extends State<HealthConditionScreen>
    with SingleTickerProviderStateMixin {
  //===============================================================
  // CONSTANTS
  //===============================================================

  static const int _totalSteps = 9;
  static const int _currentStep = 2;

  //===============================================================
  // CONTROLLERS
  //===============================================================

  final TextEditingController _otherController = TextEditingController();

  late final HealthProfileController _healthProfileController;
  late final MasterDataController
  _masterDataController; // 💡 Master data controller

  //===============================================================
  // STATE
  //===============================================================

  final Set<String> _selectedSlugs = {};
  bool _includeOther = false;

  bool get _showOtherField => _includeOther;

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

    if (Get.isRegistered<HealthProfileController>()) {
      _healthProfileController = Get.find<HealthProfileController>();
    } else {
      _healthProfileController = Get.put(
        HealthProfileController(),
        permanent: false,
      );
    }

    // Get or register MasterDataController
    if (Get.isRegistered<MasterDataController>()) {
      _masterDataController = Get.find<MasterDataController>();
    } else {
      _masterDataController = Get.put(MasterDataController());
    }

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
    _loadExistingConditions();
  }

  Future<void> _loadExistingConditions() async {
    await _masterDataController.fetchMasterData();

    final profile = _healthProfileController.healthProfile.value;
    if (profile != null && profile.conditions.isNotEmpty) {
      setState(() {
        for (var cond in profile.conditions) {
          _selectedSlugs.add(cond);
        }
      });
    }
  }

  @override
  void dispose() {
    _otherController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  //===============================================================
  // SELECTION
  //===============================================================

  void _toggleSelection(String slug) {
    setState(() {
      if (_selectedSlugs.contains(slug)) {
        _selectedSlugs.remove(slug);
      } else {
        _selectedSlugs.add(slug);
      }
    });
  }

  void _toggleOther() {
    setState(() {
      _includeOther = !_includeOther;
      if (!_includeOther) {
        _otherController.clear();
      }
    });
  }

  //===============================================================
  // NAVIGATION & API INTEGRATION
  //===============================================================

  void _goBack() {
    Get.back();
  }

  Future<void> _next() async {
    if (_selectedSlugs.isEmpty && !_includeOther) {
      _showValidationMessage();
      return;
    }

    FocusScope.of(context).unfocus();

    final conditions = List<String>.from(_selectedSlugs);

    if (_includeOther && _otherController.text.trim().isNotEmpty) {
      conditions.add(_otherController.text.trim());
    }

    debugPrint("Selected Conditions to API: $conditions");

    final success = await _healthProfileController.saveHealthConditions(
      conditions: conditions,
    );

    if (success) {
      Get.toNamed(AppRoutes.activityLevel);
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
      "Select Health Condition",
      "Please select at least one health condition or Skip.",
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
    Get.toNamed(AppRoutes.activityLevel);
  }

  // Helper mapping icon names
  IconData _getIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'bloodtype':
        return Icons.bloodtype_outlined;
      case 'heart':
      case 'favorite':
        return Icons.favorite_outline;
      case 'thyroid':
      case 'psychology':
        return Icons.psychology_alt_outlined;
      case 'heart_disease':
      case 'monitor_heart':
        return Icons.monitor_heart_outlined;
      case 'female':
        return Icons.female_outlined;
      case 'asthma':
      case 'air':
        return Icons.air_outlined;
      case 'cholesterol':
      case 'opacity':
        return Icons.opacity_outlined;
      default:
        return Icons.medical_services_outlined;
    }
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
  // PHONE LAYOUT
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
                  onBack: _goBack,
                  onSkip: _skipOnboarding,
                ),
                SizedBox(height: compact ? 24 : 30),
                _buildTitleSection(width: width, compact: compact),
                SizedBox(height: compact ? 22 : 28),
                _buildGrid(
                  width: width - (horizontalPadding * 2),
                  compact: compact,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: _showOtherField
                      ? Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: _buildOtherTextField(),
                        )
                      : const SizedBox(),
                ),
                SizedBox(height: compact ? 24 : 30),
                _buildNextButton(width: width - (horizontalPadding * 2)),
                SizedBox(height: compact ? 12 : 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //===============================================================
  // TABLET LAYOUT
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
                    onBack: _goBack,
                    onSkip: _skipOnboarding,
                  ),
                  const SizedBox(height: 34),
                  _buildTitleSection(width: contentWidth, compact: false),
                  const SizedBox(height: 30),
                  _buildGrid(width: contentWidth, compact: false),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    child: _showOtherField
                        ? Padding(
                            padding: const EdgeInsets.only(top: 22),
                            child: _buildOtherTextField(),
                          )
                        : const SizedBox(),
                  ),
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
  // TITLE
  //===============================================================

  Widget _buildTitleSection({required double width, required bool compact}) {
    final scale = _getScale(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Do you have any existing\nhealth conditions?",
          style: TextStyle(
            fontSize: (22 * scale).clamp(20.0, 25.0),
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.22,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        Text(
          "You can select multiple options.",
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
  // GRID
  //===============================================================

  Widget _buildGrid({required double width, required bool compact}) {
    final conditionsFromApi =
        _masterDataController.masterData.value?.conditions ?? [];

    // Combine API conditions + hardcoded "Other" card at the end
    final totalCount = conditionsFromApi.length + 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.0,
      ),
      itemBuilder: (_, index) {
        if (index == conditionsFromApi.length) {
          // Render "Other" Card manually
          return _buildConditionCard(
            title: "Other",
            icon: Icons.more_horiz,
            selected: _includeOther,
            onTap: _toggleOther,
            width: width,
            compact: compact,
          );
        }

        final item = conditionsFromApi[index];
        final slug = item.slug ?? item.name ?? '';
        final selected = _selectedSlugs.contains(slug);

        return _buildConditionCard(
          title: item.name ?? '',
          icon: _getIconData(item.slug),
          selected: selected,
          onTap: () => _toggleSelection(slug),
          width: width,
          compact: compact,
        );
      },
    );
  }

  //===============================================================
  // CONDITION CARD
  //===============================================================

  Widget _buildConditionCard({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required double width,
    required bool compact,
  }) {
    final scale = _getScale(width);
    final cardHeight = compact
        ? (66 * scale).clamp(62.0, 70.0)
        : (72 * scale).clamp(68.0, 78.0);
    final iconBox = (42 * scale).clamp(38.0, 46.0);
    final titleSize = (12.5 * scale).clamp(11.5, 14.0);
    final checkSize = (20 * scale).clamp(18.0, 22.0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: cardHeight,
        padding: EdgeInsets.symmetric(
          horizontal: 10 * scale,
          vertical: 8 * scale,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withOpacity(.72),
            width: selected ? 1.35 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(.9),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 21, color: Colors.black),
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: checkSize,
              height: checkSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(color: AppColors.primary),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.black, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  //===============================================================
  // OTHER TEXT FIELD
  //===============================================================

  Widget _buildOtherTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Please specify (Optional)",
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _otherController,
          maxLines: 4,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: "Write here...",
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(.7),
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(.7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(.7)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: AppColors.primary, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  //===============================================================
  // NEXT BUTTON
  //===============================================================

  Widget _buildNextButton({required double width}) {
    final scale = _getScale(width);

    final buttonHeight = (51 * scale).clamp(48.0, 56.0);
    final fontSize = (14 * scale).clamp(13.0, 15.5);
    final iconSize = (18 * scale).clamp(17.0, 20.0);
    final radius = (9 * scale).clamp(8.0, 11.0);

    final enabled = _selectedSlugs.isNotEmpty || _includeOther;

    return Obx(() {
      final isSaving = _healthProfileController.isSaving.value;

      return SizedBox(
        width: double.infinity,
        height: buttonHeight,
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
                      color: AppColors.primary.withOpacity(.16),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: isSaving ? null : _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: EdgeInsets.zero,
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
    });
  }
}
