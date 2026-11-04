import 'package:disha_ai/features/onboarding/presentation/controllers/health_nutrition_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:disha_ai/app/theme/app_colors.dart';
import 'package:disha_ai/features/meditation/data/models/category_hub_model.dart';
import 'package:disha_ai/features/meditation/presentation/controllers/category_hub_controller.dart';
import 'package:disha_ai/features/meditation/presentation/screens/meditation_player_screen.dart';
import 'package:disha_ai/features/meditation/data/models/meditation_session.dart';
import 'package:disha_ai/features/dashboard/presentation/widgets/banner_carousel.dart';

enum SleepInputMode { manual, bedtime }

class SleepCheckinScreen extends StatefulWidget {
  const SleepCheckinScreen({super.key});

  @override
  State<SleepCheckinScreen> createState() => _SleepCheckinScreenState();
}

class _SleepCheckinScreenState extends State<SleepCheckinScreen> {
  final HealthNutritionController _healthController = Get.put(
    HealthNutritionController(),
  );

  /// Sleep is also a Quick Action category.
  ///
  /// This controller loads:
  /// GET /api/quick-actions/sleep
  final CategoryHubController _categoryController = Get.put(
    CategoryHubController(),
    tag: 'sleep_quick_action',
  );
  // ============================================================
  // OPTIONAL SLEEP BANNER
  // ============================================================

  final GlobalKey<BannerCarouselState> _sleepBannerKey =
      GlobalKey<BannerCarouselState>();

  bool _hasSleepBanners = false;

  // Prevent unnecessary rebuilds.
  void _onSleepBannerVisibilityChanged(bool visible) {
    if (!mounted || _hasSleepBanners == visible) return;

    setState(() {
      _hasSleepBanners = visible;
    });
  }

  // ------------------------------------------------------------
  // INPUT MODE
  // ------------------------------------------------------------

  SleepInputMode _inputMode = SleepInputMode.manual;

  // ------------------------------------------------------------
  // SLEEP DATA
  // ------------------------------------------------------------

  double _sleepHours = 7.5;

  bool _isSubmitting = false;

  // Default:
  // 11:00 PM to 6:30 AM = 7.5 hours
  TimeOfDay _bedTime = const TimeOfDay(hour: 23, minute: 0);

  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);

  // ------------------------------------------------------------
  // LIFECYCLE
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _loadSleepQuickAction();
  }

  Future<void> _loadSleepQuickAction() async {
    await _categoryController.fetchCategoryDetails('sleep');
  }

  // ============================================================
  // SLEEP DURATION CALCULATION
  // ============================================================

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  double _calculateSleepHours(TimeOfDay bedtime, TimeOfDay wakeTime) {
    final bedMinutes = _timeToMinutes(bedtime);
    var wakeMinutes = _timeToMinutes(wakeTime);

    // Wake-up is normally on the next day.
    if (wakeMinutes < bedMinutes) {
      wakeMinutes += 24 * 60;
    }

    return (wakeMinutes - bedMinutes) / 60.0;
  }

  double get _currentSleepHours {
    if (_inputMode == SleepInputMode.bedtime) {
      return _calculateSleepHours(_bedTime, _wakeTime);
    }

    return _sleepHours;
  }

  // ============================================================
  // AUTOMATIC SLEEP QUALITY
  // ============================================================
  //
  // Backend mapping:
  //
  // 7.5 - 9.0       => Great 🌟
  // 6.5 - <7.5      => Good 😊
  // 5.5 - <6.5      => Fair 😐
  // 9.1 - 10.0      => Fair 😐
  // <5.5            => Poor 🤕
  // >10.0           => Poor 🤕
  //
  // The UI uses the same mapping for live preview.
  // The backend remains authoritative when saving.
  // ============================================================

  String get _sleepQuality {
    final hours = _currentSleepHours;

    if (hours >= 7.5 && hours <= 9.0) {
      return 'Great';
    }

    if (hours >= 6.5 && hours < 7.5) {
      return 'Good';
    }

    if ((hours >= 5.5 && hours < 6.5) || (hours > 9.0 && hours <= 10.0)) {
      return 'Fair';
    }

    return 'Poor';
  }

  String get _sleepQualityEmoji {
    switch (_sleepQuality) {
      case 'Great':
        return '🌟';

      case 'Good':
        return '😊';

      case 'Fair':
        return '😐';

      case 'Poor':
      default:
        return '🤕';
    }
  }

  String get _sleepQualityDescription {
    switch (_sleepQuality) {
      case 'Great':
        return 'You are getting an excellent amount of sleep.';

      case 'Good':
        return 'Your sleep duration is in a healthy range.';

      case 'Fair':
        return 'Your sleep duration could be improved.';

      case 'Poor':
      default:
        return 'Your sleep duration is outside the recommended range.';
    }
  }

  // ============================================================
  // FORMATTING
  // ============================================================

  String _formatTime(TimeOfDay time) {
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }

  String _formatDuration(double hours) {
    final totalMinutes = (hours * 60).round();

    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;

    if (m == 0) {
      return '$h ${h == 1 ? 'hour' : 'hours'}';
    }

    return '$h hr $m min';
  }

  // ============================================================
  // TIME PICKERS
  // ============================================================

  Future<void> _selectBedTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _bedTime,
      helpText: 'When did you go to bed?',
    );

    if (selected != null && mounted) {
      setState(() {
        _bedTime = selected;
      });
    }
  }

  Future<void> _selectWakeTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
      helpText: 'When did you wake up?',
    );

    if (selected != null && mounted) {
      setState(() {
        _wakeTime = selected;
      });
    }
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool _validateSleepDuration(double hours) {
    if (hours <= 0) {
      Get.snackbar(
        'Invalid Sleep Duration',
        'Bedtime and wake-up time cannot be the same.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
      );

      return false;
    }

    if (hours > 14) {
      Get.snackbar(
        'Check Your Sleep Times',
        'Sleep duration cannot exceed 14 hours. Please check your selected times.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
      );

      return false;
    }

    return true;
  }

  // ============================================================
  // SAVE SLEEP DATA
  // ============================================================
  //
  // IMPORTANT:
  // This now uses the dedicated Sleep API:
  //
  // POST /api/sleep
  //
  // Payload:
  // {
  //   "date": "YYYY-MM-DD",
  //   "sleep_hours": 8.0
  // }
  //
  // We do NOT send:
  // - steps
  // - calories
  // - weight
  // - mood
  // - stress
  // - manually selected quality
  //
  // Backend automatically calculates sleep_quality.
  // ============================================================

  Future<void> _saveSleepData() async {
    if (_isSubmitting) return;

    final double duration = _currentSleepHours;

    if (!_validateSleepDuration(duration)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final double sleepHours = double.parse(duration.toStringAsFixed(2));

      debugPrint('');
      debugPrint('══════════════════════════════════════════');
      debugPrint('😴 [SLEEP SCREEN] Saving sleep');
      debugPrint('sleepHours: $sleepHours');
      debugPrint('preview quality: $_sleepQuality');
      debugPrint('preview emoji: $_sleepQualityEmoji');
      debugPrint('══════════════════════════════════════════');

      final bool success = await _healthController.logSleep(
        sleepHours: sleepHours,
      );

      if (!mounted) return;

      if (success) {
        // Read the backend-authoritative result when available.
        final savedSleep = _healthController.sleepLog.value;

        final String savedQuality = savedSleep?.sleepQuality ?? _sleepQuality;

        final String savedEmoji = savedSleep?.emoji ?? _sleepQualityEmoji;

        Get.back();

        Get.snackbar(
          'Sleep Logged',
          '${savedEmoji} ${_formatDuration(sleepHours)} • $savedQuality',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
          margin: const EdgeInsets.all(16),
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
          ),
        );
      } else {
        Get.snackbar(
          'Failed',
          _healthController.errorMessage.value.isNotEmpty
              ? _healthController.errorMessage.value
              : 'Could not save sleep data. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      debugPrint('❌ [SLEEP SCREEN] Save sleep error: $e');

      if (!mounted) return;

      Get.snackbar(
        'Error',
        'Unable to save sleep data. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
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
  // QUICK ACTION — SLEEP SUBCATEGORIES
  // ============================================================

  Widget _buildSleepSubcategories() {
    return Obx(() {
      if (_categoryController.isLoading.value &&
          _categoryController.hubData.value == null) {
        return _buildContentLoading();
      }

      final subcategories = _categoryController.subcategories;

      if (subcategories.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Explore Sleep',
            subtitle: 'Choose a sleep experience to help you relax.',
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: subcategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = subcategories[index];

                return _buildSubcategoryCard(item);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSubcategoryCard(SubcategoryItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _categoryController.selectedSubcategoryId.value = item.id;
      },
      child: Container(
        width: 145,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bedtime_rounded,
                color: AppColors.primary,
                size: 19,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTION — SLEEP CONTENT
  // ============================================================

  Widget _buildSleepContent() {
    return Obx(() {
      if (_categoryController.isLoading.value &&
          _categoryController.hubData.value == null) {
        return const SizedBox.shrink();
      }

      final contents = _categoryController.filteredContents;

      if (contents.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Sleep Sessions',
            subtitle: 'Audio and video sessions from Sleep.',
          ),

          const SizedBox(height: 14),

          Column(
            children: List.generate(contents.length, (index) {
              final item = contents[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == contents.length - 1 ? 0 : 12,
                ),
                child: _buildSleepContentCard(item),
              );
            }),
          ),
        ],
      );
    });
  }

  Widget _buildSleepContentCard(ContentItem item) {
    final bool isAudio = item.contentType.toLowerCase() == 'audio';

    final bool isVideo = item.contentType.toLowerCase() == 'video';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openSleepContent(item),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.14)),
          ),
          child: Row(
            children: [
              // ------------------------------------------------
              // THUMBNAIL / CONTENT ICON
              // ------------------------------------------------
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 92,
                  height: 72,
                  child:
                      item.thumbnailUrl != null &&
                          item.thumbnailUrl!.trim().isNotEmpty
                      ? Image.network(
                          item.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return _buildContentPlaceholder(isAudio: isAudio);
                          },
                        )
                      : _buildContentPlaceholder(isAudio: isAudio),
                ),
              ),

              const SizedBox(width: 12),

              // ------------------------------------------------
              // CONTENT INFORMATION
              // ------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    if (item.description != null &&
                        item.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        item.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Icon(
                          isAudio
                              ? Icons.headphones_rounded
                              : isVideo
                              ? Icons.play_circle_outline_rounded
                              : Icons.self_improvement_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          isAudio
                              ? 'Audio'
                              : isVideo
                              ? 'Video'
                              : item.contentType,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        if (item.durationText.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.durationText,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],

                        if (item.level.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item.level,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ------------------------------------------------
              // PLAY BUTTON
              // ------------------------------------------------
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentPlaceholder({required bool isAudio}) {
    return Container(
      color: AppColors.primary.withOpacity(0.10),
      child: Icon(
        isAudio ? Icons.headphones_rounded : Icons.play_circle_outline_rounded,
        color: AppColors.primary,
        size: 30,
      ),
    );
  }

  // ============================================================
  // OPEN SLEEP CONTENT
  // ============================================================

  Future<void> _openSleepContent(ContentItem item) async {
    final url = item.playbackUrl;

    if (url == null || url.trim().isEmpty) {
      Get.snackbar(
        'Content unavailable',
        'This sleep session does not have a playback URL.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final contentType = item.contentType.trim().toLowerCase();

    // ==========================================================
    // AUDIO
    // Open existing MeditationPlayerScreen
    // ==========================================================

    if (contentType == 'audio') {
      Get.to(
        () => MeditationPlayerScreen(
          session: MeditationSession(
            title: item.title,
            description: item.description ?? '',
            duration: item.durationText.isNotEmpty
                ? item.durationText
                : '${item.durationMinutes} min',
            minutes: item.durationMinutes,
            icon: Icons.bedtime_rounded,
          ),
          audioUrl: url,
        ),
      );

      return;
    }

    // ==========================================================
    // VIDEO
    // ==========================================================

    if (contentType == 'video') {
      await _launchExternalUrl(url);
      return;
    }

    // ==========================================================
    // FALLBACK
    // ==========================================================

    await _launchExternalUrl(url);
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      Get.snackbar(
        'Invalid URL',
        'Unable to open this content.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      Get.snackbar(
        'Unable to open',
        'Could not open this sleep content.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildContentLoading() {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // MODE SELECTOR
  // ============================================================

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              title: 'Manual',
              icon: Icons.tune_rounded,
              mode: SleepInputMode.manual,
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: _buildModeButton(
              title: 'Bedtime + Wake-up',
              icon: Icons.schedule_rounded,
              mode: SleepInputMode.bedtime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String title,
    required IconData icon,
    required SleepInputMode mode,
  }) {
    final selected = _inputMode == mode;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _inputMode = mode;

          if (mode == SleepInputMode.bedtime) {
            _sleepHours = _calculateSleepHours(_bedTime, _wakeTime);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),

            const SizedBox(width: 6),

            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MANUAL INPUT
  // ============================================================

  Widget _buildManualInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          const Icon(Icons.bedtime_rounded, color: AppColors.primary, size: 30),

          const SizedBox(height: 10),

          Text(
            '${_sleepHours.toStringAsFixed(1)} hrs',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Sleep duration',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),

          const SizedBox(height: 12),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.15),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.15),
              valueIndicatorColor: AppColors.primary,
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Slider(
              value: _sleepHours,
              min: 1,
              max: 14,
              divisions: 26,
              label: '${_sleepHours.toStringAsFixed(1)} hrs',
              onChanged: (value) {
                setState(() {
                  _sleepHours = value;
                });
              },
            ),
          ),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 hour',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                '14 hours',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BEDTIME INPUT
  // ============================================================

  Widget _buildTimeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 23),

              const SizedBox(height: 10),

              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 10),

              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Tap to change',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBedtimeInput() {
    final duration = _currentSleepHours;

    return Column(
      children: [
        Row(
          children: [
            _buildTimeCard(
              icon: Icons.nightlight_round,
              title: 'Bedtime',
              subtitle: 'Went to bed',
              time: _formatTime(_bedTime),
              onTap: _selectBedTime,
            ),

            const SizedBox(width: 12),

            _buildTimeCard(
              icon: Icons.wb_sunny_rounded,
              title: 'Wake-up',
              subtitle: 'Got out of sleep',
              time: _formatTime(_wakeTime),
              onTap: _selectWakeTime,
            ),
          ],
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.16),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.bedtime_rounded,
                color: AppColors.primary,
                size: 28,
              ),

              const SizedBox(height: 8),

              Text(
                duration > 0 ? '${duration.toStringAsFixed(2)} hrs' : '0 hrs',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                duration > 0
                    ? _formatDuration(duration)
                    : 'Please choose different times',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Calculated automatically from your selected times',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AUTOMATIC QUALITY CARD
  // ============================================================

  Widget _buildAutomaticQualityCard() {
    final quality = _sleepQuality;
    final emoji = _sleepQualityEmoji;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 34)),

              const SizedBox(width: 12),

              Text(
                quality,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            _sleepQualityDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Calculated automatically from sleep duration',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Sleep & Rest Check-in',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ----------------------------------------------------------
      // BODY
      // ----------------------------------------------------------
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================================
              // OPTIONAL SLEEP BANNER
              //
              // Banner exists:
              //   Show Meditation-style banner.
              //
              // No banner:
              //   Show existing screen without extra spacing.
              // ==========================================================
              _buildOptionalSleepBanner(),

              // ==========================================================
              // EXISTING SLEEP UI — UNCHANGED
              // ==========================================================
              _sectionTitle(
                'Track your sleep',
                subtitle: 'Choose how you want to record your nightly rest.',
              ),

              const SizedBox(height: 20),

              _buildModeSelector(),

              const SizedBox(height: 22),

              if (_inputMode == SleepInputMode.manual)
                _buildManualInput()
              else
                _buildBedtimeInput(),

              const SizedBox(height: 30),

              // ==================================================
              // AUTOMATIC SLEEP QUALITY
              // ==================================================
              _sectionTitle(
                'Your sleep quality',
                subtitle:
                    'Sleep quality is calculated automatically from your sleep duration.',
              ),

              const SizedBox(height: 14),

              _buildAutomaticQualityCard(),

              // ==================================================
              // SLEEP QUICK ACTION CONTENT
              // ==================================================
              //
              // IMPORTANT:
              // This uses /quick-actions/sleep
              //
              // It does NOT use suggested_videos because
              // suggested_videos can contain Meditation content.
              //
              // These are the actual Sleep category contents
              // returned by the backend.
              // ==================================================
              const SizedBox(height: 30),

              _buildSleepSubcategories(),

              const SizedBox(height: 30),

              _buildSleepContent(),

              const SizedBox(height: 30),

              // --------------------------------------------------
              // SAVE BUTTON
              // --------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveSleepData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Save Sleep Record',
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
                  'Your sleep duration is saved using the sleep tracking API.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ============================================================
  // SLEEP BANNER — SAME AS MEDITATION
  // ============================================================

  Widget _buildOptionalSleepBanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only add spacing when banners exist.
        if (_hasSleepBanners) const SizedBox(height: 24),

        BannerCarousel(
          key: _sleepBannerKey,
          category: 'Sleep',
          title: 'Restful Nights',
          subtitle: 'A little inspiration for better sleep',
          height: 175,
          autoSlideDuration: const Duration(seconds: 5),
          showSectionTitle: true,
          onVisibilityChanged: _onSleepBannerVisibilityChanged,
        ),

        // Only add spacing when banners exist.
        if (_hasSleepBanners) const SizedBox(height: 24),
      ],
    );
  }
}
