import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:disha_ai/features/dashboard/presentation/widgets/banner_carousel.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class AddictionScreen extends StatefulWidget {
  const AddictionScreen({super.key});

  @override
  State<AddictionScreen> createState() => _AddictionScreenState();
}

class _AddictionScreenState extends State<AddictionScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final HealthProfileController _controller;

  // ============================================================
  // OPTIONAL ADDICTIONS BANNER
  // ============================================================

  final GlobalKey<BannerCarouselState> _addictionsBannerKey =
      GlobalKey<BannerCarouselState>();

  bool _hasAddictionsBanners = false;

  // ============================================================
  // ADDICTION OPTIONS
  // ============================================================

  final List<String> addictionOptions = [
    'Porn Addiction',
    'Smoking Addiction',
    'Tobacco',
    'Sexual Health & Compulsive Behavior',
    'Alcohol Addiction',
  ];

  String? selectedOption;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (Get.isRegistered<HealthProfileController>()) {
      _controller = Get.find<HealthProfileController>();
    } else {
      _controller = Get.put(HealthProfileController());
    }

    // Restore existing selection from the health profile.
    final existing = _controller.healthProfile.value?.habitAddiction;

    if (existing != null && addictionOptions.contains(existing)) {
      selectedOption = existing;
    }
  }

  // ============================================================
  // BANNER VISIBILITY
  //
  // Only add banner spacing when banners actually exist.
  // ============================================================

  void _onAddictionsBannerVisibilityChanged(bool visible) {
    if (!mounted || _hasAddictionsBanners == visible) return;

    setState(() {
      _hasAddictionsBanners = visible;
    });
  }

  // ============================================================
  // OPTIONAL ADDICTIONS BANNER
  //
  // Backend category: Addictions
  //
  // Banner available:
  //   Display Meditation-style banner.
  //
  // No banner:
  //   Display nothing and preserve existing screen spacing.
  // ============================================================

  Widget _buildOptionalAddictionsBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasAddictionsBanners) const SizedBox(height: 24),

        BannerCarousel(
          key: _addictionsBannerKey,
          category: 'Addictions',
          title: 'A Healthier You',
          subtitle: 'Every positive change begins with one small step',
          height: 175,
          autoSlideDuration: const Duration(seconds: 5),
          showSectionTitle: true,
          onVisibilityChanged: _onAddictionsBannerVisibilityChanged,
        ),
      ],
    );
  }

  // ============================================================
  // PULL-TO-REFRESH
  //
  // Refresh banners without changing selected addiction.
  // ============================================================

  Future<void> _refreshAddictionsScreen() async {
    await _addictionsBannerKey.currentState?.refreshBanners();
  }

  // ============================================================
  // SAVE ADDICTION PREFERENCE
  //
  // Existing API logic preserved.
  // ============================================================

  Future<void> _onSave() async {
    if (selectedOption == null || _controller.isSaving.value) return;

    FocusScope.of(context).unfocus();

    final success = await _controller.saveHabitAddiction(
      habitAddiction: selectedOption!,
    );

    if (!mounted) return;

    if (success) {
      Get.snackbar(
        'Success'.tr,
        'Health profile saved successfully.'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
      );

      // Preserve existing navigation behavior.
      Get.until((route) => Get.currentRoute == '/' || route.isFirst);
    } else {
      Get.snackbar(
        'Error'.tr,
        _controller.errorMessage.value.isNotEmpty
            ? _controller.errorMessage.value
            : 'Failed to save preference. Please try again.'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: Colors.redAccent,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // ============================================================
  // ADDICTION OPTION CARD
  // ============================================================

  Widget _buildAddictionOption({
    required String option,
    required bool isTablet,
  }) {
    final bool isSelected = selectedOption == option;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedOption = option;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isTablet ? 22 : 18,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  option.tr,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ==================================================
              // RADIO / SELECTION CIRCLE
              // ==================================================
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton(bool isTablet) {
    return Obx(() {
      final bool isSaving = _controller.isSaving.value;

      return SizedBox(
        width: double.infinity,
        height: isTablet ? 58 : 52,
        child: ElevatedButton(
          onPressed: selectedOption != null && !isSaving ? _onSave : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedOption != null
                ? AppColors.primary
                : AppColors.surface,
            foregroundColor: selectedOption != null
                ? Colors.black
                : AppColors.textSecondary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black,
                  ),
                )
              : Text(
                  'Save'.tr,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      );
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ==========================================================
      // APP BAR — ORIGINAL DESIGN PRESERVED
      // ==========================================================
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool isTablet = width >= 600;

          return SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: _refreshAddictionsScreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? width * 0.18 : 20,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 600 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==========================================
                      // ORIGINAL TITLE
                      // ==========================================
                      Text(
                        'Habit & Addiction Support'.tr,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: isTablet ? 28 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ==========================================
                      // ORIGINAL DESCRIPTION
                      // ==========================================
                      Text(
                        'Select an area you would like guidance or structured help overcoming.'
                            .tr,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),

                      // ==========================================
                      // OPTIONAL ADDICTIONS BANNER
                      // ==========================================
                      _buildOptionalAddictionsBanner(),

                      // ==========================================
                      // ORIGINAL SPACING
                      //
                      // No banners:
                      //   Original 32px gap is preserved.
                      // ==========================================
                      const SizedBox(height: 32),

                      // ==========================================
                      // ADDICTION OPTIONS
                      // ==========================================
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: addictionOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final option = addictionOptions[index];

                          return _buildAddictionOption(
                            option: option,
                            isTablet: isTablet,
                          );
                        },
                      ),

                      const SizedBox(height: 48),

                      // ==========================================
                      // SAVE BUTTON
                      // ==========================================
                      _buildSaveButton(isTablet),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
