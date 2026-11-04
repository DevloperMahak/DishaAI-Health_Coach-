import 'package:disha_ai/app/theme/app_colors.dart';
import 'package:disha_ai/features/dashboard/presentation/controllers/mood_checkin_controller.dart';
import 'package:disha_ai/features/dashboard/presentation/widgets/banner_carousel.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MoodCheckinScreen extends StatefulWidget {
  const MoodCheckinScreen({super.key});

  @override
  State<MoodCheckinScreen> createState() => _MoodCheckinScreenState();
}

class _MoodCheckinScreenState extends State<MoodCheckinScreen> {
  late final MoodCheckinController _controller;

  // ============================================================
  // OPTIONAL MOOD BANNER
  // ============================================================

  final GlobalKey<BannerCarouselState> _moodBannerKey =
      GlobalKey<BannerCarouselState>();

  bool _hasMoodBanners = false;

  void _onMoodBannerVisibilityChanged(bool visible) {
    if (!mounted || _hasMoodBanners == visible) return;

    setState(() {
      _hasMoodBanners = visible;
    });
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller = Get.isRegistered<MoodCheckinController>()
        ? Get.find<MoodCheckinController>()
        : Get.put(MoodCheckinController());
  }

  // ============================================================
  // REFRESH BANNERS
  // ============================================================

  Future<void> _refreshMoodScreen() async {
    await _moodBannerKey.currentState?.refreshBanners();
  }

  // ============================================================
  // OPTIONAL MOOD BANNER
  //
  // Backend category: Mood
  //
  // Banner exists:
  //   Display Meditation-style carousel.
  //
  // No banner:
  //   Preserve original UI without extra spacing.
  // ============================================================

  Widget _buildOptionalMoodBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BannerCarousel(
          key: _moodBannerKey,
          category: 'Mood',
          title: 'Your Emotional Wellness',
          subtitle: 'Take a moment to reconnect with how you feel',
          height: 175,
          autoSlideDuration: const Duration(seconds: 5),
          showSectionTitle: true,
          onVisibilityChanged: _onMoodBannerVisibilityChanged,
        ),

        if (_hasMoodBanners) const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // MOOD -> STRESS
  //
  // This mapping is ONLY for immediate UI feedback.
  //
  // Backend remains the final source of truth after saving.
  //
  // API mapping:
  //
  // anxious      -> high
  // overwhelmed  -> high
  // low_sad      -> moderate
  // irritated    -> moderate
  // tired        -> moderate
  // calm         -> low
  // happy        -> low
  // energetic    -> low
  // ============================================================

  String _getExpectedStress(String mood) {
    switch (mood.trim().toLowerCase()) {
      case 'anxious':
      case 'overwhelmed':
        return 'high';

      case 'low_sad':
      case 'irritated':
      case 'tired':
        return 'moderate';

      case 'calm':
      case 'happy':
      case 'energetic':
        return 'low';

      default:
        return '';
    }
  }

  // ============================================================
  // STRESS VALUE
  // ============================================================

  double _getStressProgress(String stress) {
    switch (stress.trim().toLowerCase()) {
      case 'low':
        return 0.33;

      case 'moderate':
        return 0.66;

      case 'high':
        return 1.0;

      default:
        return 0.0;
    }
  }

  // ============================================================
  // SAVE MOOD
  // ============================================================

  Future<void> _saveMood() async {
    FocusScope.of(context).unfocus();

    final String selectedMood = _controller.selectedMood.value.trim();

    if (selectedMood.isEmpty) {
      Get.snackbar(
        'Mood Required',
        'Please select how you are feeling today.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
      );

      return;
    }

    final bool success = await _controller.submitMood();

    if (!mounted) return;

    if (success) {
      final String stress = _controller.calculatedStressLevel.value.trim();

      debugPrint('✅ [MOOD UI] Mood saved successfully');
      debugPrint('😊 Mood: $selectedMood');
      debugPrint('🧠 Backend stress: $stress');

      Get.back();

      Get.snackbar(
        'Mood Logged',
        stress.isNotEmpty
            ? 'Your mood was saved successfully. Stress level: ${stress.capitalizeFirst ?? stress}.'
            : 'Your emotional wellness check-in was saved successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
      );
    } else {
      final String error = _controller.errorMessage.value.trim();

      Get.snackbar(
        'Failed',
        error.isNotEmpty
            ? error
            : 'Could not save mood check-in. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
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
          'Daily Mood & Stress Check-in',
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
          onRefresh: _refreshMoodScreen,
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
                      padding: EdgeInsets.all(isWide ? 30 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ======================================
                          // OPTIONAL MOOD BANNER
                          // ======================================
                          _buildOptionalMoodBanner(),

                          // ======================================
                          // EXISTING MOOD UI
                          // ======================================
                          Obx(() {
                            final String selectedMood =
                                _controller.selectedMood.value;

                            final String backendStress =
                                _controller.calculatedStressLevel.value;

                            // Before saving:
                            // Show stress predicted from selected mood.
                            //
                            // After saving:
                            // Backend stress takes priority.

                            final String displayedStress =
                                backendStress.isNotEmpty
                                ? backendStress
                                : _getExpectedStress(selectedMood);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ==================================
                                // HEADER
                                // ==================================
                                const Text(
                                  'How are you feeling right now?',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                const Text(
                                  'Select the option that best reflects your current energy and emotions.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ==================================
                                // MOOD GRID
                                // ==================================
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),

                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
                                        childAspectRatio: 2.2,
                                      ),

                                  itemCount: _controller.moods.length,

                                  itemBuilder: (context, index) {
                                    final Map<String, String> mood =
                                        _controller.moods[index];

                                    final String value = mood['value'] ?? '';

                                    final bool isSelected =
                                        selectedMood == value;

                                    return GestureDetector(
                                      onTap: _controller.isSubmitting.value
                                          ? null
                                          : () {
                                              debugPrint(
                                                '🎭 [MOOD UI] Mood selected: $value',
                                              );

                                              _controller.selectMood(value);
                                            },

                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),

                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary.withOpacity(
                                                  0.15,
                                                )
                                              : AppColors.surface,

                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),

                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.primary.withOpacity(
                                                    0.15,
                                                  ),
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),

                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),

                                        child: Row(
                                          children: [
                                            Text(
                                              mood['emoji'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 24,
                                              ),
                                            ),

                                            const SizedBox(width: 10),

                                            Expanded(
                                              child: Text(
                                                mood['label'] ?? '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : AppColors.textPrimary,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),

                                            if (isSelected)
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 32),

                                // ==================================
                                // STRESS LEVEL
                                // ==================================
                                const Text(
                                  'Current Stress Level',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                const Text(
                                  'Automatically determined from your selected mood.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),

                                const SizedBox(height: 18),

                                _buildStressSlider(stress: displayedStress),

                                const SizedBox(height: 45),

                                // ==================================
                                // SAVE BUTTON
                                // ==================================
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _controller.isSubmitting.value
                                        ? null
                                        : _saveMood,

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.black,
                                      minimumSize: const Size(
                                        double.infinity,
                                        52,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),

                                    child: _controller.isSubmitting.value
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'Save Mood Check-in',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                const Center(
                                  child: Text(
                                    'Stress level is calculated automatically by the backend from your selected mood.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
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

  // ============================================================
  // STRESS SLIDER / BAR
  // ============================================================

  Widget _buildStressSlider({required String stress}) {
    final bool hasStress = stress.trim().isNotEmpty;

    final double progress = _getStressProgress(stress);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // CURRENT VALUE
          // ======================================================
          Row(
            children: [
              const Icon(
                Icons.psychology_rounded,
                color: AppColors.primary,
                size: 22,
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Stress Level',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Text(
                hasStress ? stress.capitalizeFirst ?? stress : 'Select mood',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ======================================================
          // PROGRESS BAR
          // ======================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ======================================================
          // LOW / MODERATE / HIGH
          // ======================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStressLabel('Low', stress.toLowerCase() == 'low'),

              _buildStressLabel('Moderate', stress.toLowerCase() == 'moderate'),

              _buildStressLabel('High', stress.toLowerCase() == 'high'),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            hasStress
                ? 'Stress level is automatically calculated from your mood.'
                : 'Select a mood to see your estimated stress level.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STRESS LABEL
  // ============================================================

  Widget _buildStressLabel(String label, bool active) {
    return Text(
      label,
      style: TextStyle(
        color: active ? AppColors.primary : AppColors.textSecondary,
        fontSize: 11.5,
        fontWeight: active ? FontWeight.bold : FontWeight.w500,
      ),
    );
  }
}
