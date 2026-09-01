import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/meditation_session.dart';
import '../../../../app/theme/app_colors.dart';

class MeditationPlayerScreen extends StatefulWidget {
  final MeditationSession session;

  const MeditationPlayerScreen({super.key, required this.session});

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // STATE
  // ============================================================

  bool _isPlaying = false;
  bool _backgroundSound = true;

  double _progress = 0.28;
  double _volume = 0.75;

  late final AnimationController _breathingController;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breathingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  // ============================================================
  // PLAYER ACTIONS
  // ============================================================

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _skipBack() {
    setState(() {
      _progress = (_progress - 0.05).clamp(0.0, 1.0);
    });
  }

  void _skipForward() {
    setState(() {
      _progress = (_progress + 0.05).clamp(0.0, 1.0);
    });
  }

  void _completeSession() {
    setState(() {
      _progress = 1.0;
      _isPlaying = false;
    });

    _showCompletionSheet();
  }

  // ============================================================
  // COMPLETION SHEET
  // ============================================================

  void _showCompletionSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: AppColors.primary.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ----------------------------------------------------
            // HANDLE
            // ----------------------------------------------------
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.30),
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 24),

            // ----------------------------------------------------
            // SUCCESS ICON
            // ----------------------------------------------------
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 34,
              ),
            ),

            const SizedBox(height: 17),

            // ----------------------------------------------------
            // TITLE
            // ----------------------------------------------------
            const Text(
              'Meditation Complete',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            // ----------------------------------------------------
            // DESCRIPTION
            // ----------------------------------------------------
            const Text(
              'Beautiful work. Take this calm feeling with you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 22),

            // ----------------------------------------------------
            // STATS
            // ----------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: _completionStat(
                    value: widget.session.duration,
                    label: 'Meditated',
                  ),
                ),
                Expanded(
                  child: _completionStat(value: '1', label: 'Session'),
                ),
                Expanded(
                  child: _completionStat(value: '8', label: 'Day Streak'),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ----------------------------------------------------
            // DONE
            // ----------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _completionStat({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _buildPlayer(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // RESPONSIVE PLAYER
  // ============================================================

  Widget _buildPlayer({required double width, required double height}) {
    final scale = (width / 390).clamp(0.88, 1.15);

    final contentWidth = width >= 700 ? 560.0 : width - (40 * scale);

    return Center(
      child: SizedBox(
        width: contentWidth,
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20 * scale,
            16 * scale,
            20 * scale,
            30 * scale,
          ),
          child: Column(
            children: [
              // ==================================================
              // TOP BAR
              // ==================================================
              _buildTopBar(scale),

              SizedBox(height: 30 * scale),

              // ==================================================
              // MEDITATION ARTWORK
              // ==================================================
              _buildMeditationArtwork(scale),

              SizedBox(height: 28 * scale),

              // ==================================================
              // TITLE
              // ==================================================
              Text(
                widget.session.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 23 * scale,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),

              SizedBox(height: 7 * scale),

              Text(
                widget.session.duration,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 27 * scale),

              // ==================================================
              // PROGRESS
              // ==================================================
              _buildProgressSlider(scale),

              SizedBox(height: 5 * scale),

              _buildTimeRow(scale),

              SizedBox(height: 23 * scale),

              // ==================================================
              // MAIN CONTROLS
              // ==================================================
              _buildControls(scale),

              SizedBox(height: 28 * scale),

              // ==================================================
              // VOLUME
              // ==================================================
              _buildVolumeControl(scale),

              SizedBox(height: 15 * scale),

              // ==================================================
              // BACKGROUND SOUND
              // ==================================================
              _buildBackgroundSound(scale),

              SizedBox(height: 28 * scale),

              // ==================================================
              // BREATHING MESSAGE
              // ==================================================
              _buildBreathingMessage(scale),

              SizedBox(height: 25 * scale),

              // ==================================================
              // COMPLETE
              // ==================================================
              _buildCompleteButton(scale),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(double scale) {
    return Row(
      children: [
        _circleButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            Get.back();
          },
          scale: scale,
        ),

        const Spacer(),

        Text(
          'MEDITATION',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 10 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),

        const Spacer(),

        _circleButton(
          icon: Icons.more_horiz_rounded,
          onTap: _showOptions,
          scale: scale,
        ),
      ],
    );
  }

  // ============================================================
  // OPTIONS
  // ============================================================

  void _showOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 22),

            _optionTile(
              icon: Icons.bookmark_border_rounded,
              title: 'Save Meditation',
              onTap: () {
                Get.back();

                Get.snackbar(
                  'Saved',
                  'Meditation added to your saved sessions.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.surface,
                  colorText: AppColors.textPrimary,
                );
              },
            ),

            _optionTile(
              icon: Icons.share_outlined,
              title: 'Share',
              onTap: () {
                Get.back();
              },
            ),

            _optionTile(
              icon: Icons.close_rounded,
              title: 'Close Session',
              onTap: () {
                Get.back();
                Get.back();
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // MEDITATION ARTWORK
  // ============================================================

  Widget _buildMeditationArtwork(double scale) {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        final value = _breathingController.value;

        final outerSize = (215 + (value * 10)) * scale;
        final middleSize = (170 + (value * 8)) * scale;
        final innerSize = (125 + (value * 5)) * scale;

        return SizedBox(
          width: outerSize,
          height: outerSize,
          child: Center(
            child: Container(
              width: outerSize,
              height: outerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.09),
                  width: 1,
                ),
              ),
              child: Center(
                child: Container(
                  width: middleSize,
                  height: middleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: innerSize,
                      height: innerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.22),
                            AppColors.primary.withOpacity(0.07),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 78 * scale,
                          height: 78 * scale,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.10),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.08),
                                blurRadius: 25,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.self_improvement_rounded,
                            color: AppColors.primary,
                            size: 38 * scale,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PROGRESS SLIDER
  // ============================================================

  Widget _buildProgressSlider(double scale) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4 * scale,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6 * scale),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 14 * scale),
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.primary.withOpacity(0.12),
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.10),
      ),
      child: Slider(
        value: _progress,
        onChanged: (value) {
          setState(() {
            _progress = value;
          });
        },
      ),
    );
  }

  // ============================================================
  // TIME
  // ============================================================

  Widget _buildTimeRow(double scale) {
    final currentSeconds = _progress * widget.session.minutes * 60;

    final totalSeconds = widget.session.minutes * 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatTime(currentSeconds),
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10 * scale,
          ),
        ),
        Text(
          _formatTime(totalSeconds.toDouble()),
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10 * scale,
          ),
        ),
      ],
    );
  }

  String _formatTime(double seconds) {
    final totalSeconds = seconds.round();

    final minutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // MAIN CONTROLS
  // ============================================================

  Widget _buildControls(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _playerControl(
          icon: Icons.replay_10_rounded,
          onTap: _skipBack,
          scale: scale,
        ),

        SizedBox(width: 30 * scale),

        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 68 * scale,
            height: 68 * scale,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(_isPlaying),
                color: Colors.black,
                size: 31 * scale,
              ),
            ),
          ),
        ),

        SizedBox(width: 30 * scale),

        _playerControl(
          icon: Icons.forward_10_rounded,
          onTap: _skipForward,
          scale: scale,
        ),
      ],
    );
  }

  Widget _playerControl({
    required IconData icon,
    required VoidCallback onTap,
    required double scale,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: EdgeInsets.all(8 * scale),
          child: Icon(icon, color: AppColors.textPrimary, size: 27 * scale),
        ),
      ),
    );
  }

  // ============================================================
  // VOLUME
  // ============================================================

  Widget _buildVolumeControl(double scale) {
    return Row(
      children: [
        Icon(
          Icons.volume_down_rounded,
          color: AppColors.textSecondary,
          size: 19 * scale,
        ),

        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5 * scale),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12 * scale),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.10),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.10),
            ),
            child: Slider(
              value: _volume,
              onChanged: (value) {
                setState(() {
                  _volume = value;
                });
              },
            ),
          ),
        ),

        Icon(
          Icons.volume_up_rounded,
          color: AppColors.textSecondary,
          size: 19 * scale,
        ),
      ],
    );
  }

  // ============================================================
  // BACKGROUND SOUND
  // ============================================================

  Widget _buildBackgroundSound(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 38 * scale,
            height: 38 * scale,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(9 * scale),
            ),
            child: Icon(
              Icons.waves_rounded,
              color: AppColors.primary,
              size: 19 * scale,
            ),
          ),

          SizedBox(width: 11 * scale),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Background Sound',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11.5 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Soft ambient sounds',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9.5 * scale,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: _backgroundSound,
            onChanged: (value) {
              setState(() {
                _backgroundSound = value;
              });
            },
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.30),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BREATHING MESSAGE
  // ============================================================

  Widget _buildBreathingMessage(double scale) {
    return Column(
      children: [
        Text(
          'Breathe in slowly...',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 5 * scale),

        Text(
          'Let your thoughts come and go without judgment.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10.5 * scale,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COMPLETE BUTTON
  // ============================================================

  Widget _buildCompleteButton(double scale) {
    return SizedBox(
      width: double.infinity,
      height: 48 * scale,
      child: OutlinedButton(
        onPressed: _completeSession,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withOpacity(0.35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11 * scale),
          ),
        ),
        child: Text(
          'Complete Session',
          style: TextStyle(fontSize: 12.5 * scale, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ============================================================
  // CIRCLE BUTTON
  // ============================================================

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    required double scale,
  }) {
    final size = 42 * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 19 * scale),
        ),
      ),
    );
  }
}

// ================================================================
// MEDITATION SESSION MODEL
// ================================================================
//
// Keep this model shared with MeditationHomeScreen later.
// If you already have a model file, move this class there.
//
