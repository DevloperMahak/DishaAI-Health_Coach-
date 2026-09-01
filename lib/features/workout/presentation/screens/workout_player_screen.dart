import 'dart:async';

import 'package:disha_ai/features/workout/data/models/workout_session.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class WorkoutPlayerScreen extends StatefulWidget {
  final WorkoutSession session;

  const WorkoutPlayerScreen({super.key, required this.session});

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // STATE
  // ============================================================

  bool _isPlaying = false;
  bool _isPaused = false;

  int _currentSecond = 0;

  Timer? _timer;

  late final AnimationController _animationController;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // ============================================================
  // WORKOUT CONTROL
  // ============================================================

  void _toggleWorkout() {
    if (_isPlaying) {
      _pauseWorkout();
    } else {
      _startWorkout();
    }
  }

  void _startWorkout() {
    setState(() {
      _isPlaying = true;
      _isPaused = false;
    });

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (_currentSecond >= widget.session.minutes * 60) {
        _completeWorkout();
        return;
      }

      setState(() {
        _currentSecond++;
      });
    });
  }

  void _pauseWorkout() {
    _timer?.cancel();

    setState(() {
      _isPlaying = false;
      _isPaused = true;
    });
  }

  void _resetWorkout() {
    _timer?.cancel();

    setState(() {
      _currentSecond = 0;
      _isPlaying = false;
      _isPaused = false;
    });
  }

  void _completeWorkout() {
    _timer?.cancel();

    setState(() {
      _currentSecond = widget.session.minutes * 60;
      _isPlaying = false;
    });

    _showCompletionSheet();
  }

  // ============================================================
  // COMPLETION
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
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: 66,
              height: 66,
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

            const SizedBox(height: 16),

            const Text(
              'Workout Complete',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Great work! You made time to move today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: _completionStat(
                    value: widget.session.duration,
                    label: 'Workout',
                  ),
                ),
                Expanded(
                  child: _completionStat(
                    value: '${widget.session.calories}',
                    label: 'Calories',
                  ),
                ),
                Expanded(
                  child: _completionStat(value: '5', label: 'Day Streak'),
                ),
              ],
            ),

            const SizedBox(height: 24),

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
                  style: TextStyle(fontWeight: FontWeight.w600),
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
            final width = constraints.maxWidth;

            return _buildPlayer(width: width, height: constraints.maxHeight);
          },
        ),
      ),
    );
  }

  // ============================================================
  // PLAYER
  // ============================================================

  Widget _buildPlayer({required double width, required double height}) {
    final scale = (width / 390).clamp(0.88, 1.15);

    final contentWidth = width >= 700 ? 560.0 : width - 40;

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
              _buildTopBar(scale),

              SizedBox(height: 30 * scale),

              _buildWorkoutVisual(scale),

              SizedBox(height: 28 * scale),

              Text(
                widget.session.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 23 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(height: 7 * scale),

              Text(
                '${widget.session.level} • ${widget.session.duration}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 30 * scale),

              _buildTimer(scale),

              SizedBox(height: 12 * scale),

              _buildProgress(scale),

              SizedBox(height: 28 * scale),

              _buildControls(scale),

              SizedBox(height: 30 * scale),

              _buildWorkoutInfo(scale),

              SizedBox(height: 24 * scale),

              _buildExerciseHint(scale),

              SizedBox(height: 26 * scale),

              SizedBox(
                width: double.infinity,
                height: 48 * scale,
                child: OutlinedButton(
                  onPressed: _completeWorkout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withOpacity(0.35),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11 * scale),
                    ),
                  ),
                  child: Text(
                    'Complete Workout',
                    style: TextStyle(
                      fontSize: 12.5 * scale,
                      fontWeight: FontWeight.w600,
                    ),
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
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(double scale) {
    return Row(
      children: [
        _circleButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            _timer?.cancel();
            Get.back();
          },
          scale: scale,
        ),

        const Spacer(),

        Text(
          'WORKOUT',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 10 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),

        const Spacer(),

        _circleButton(
          icon: Icons.refresh_rounded,
          onTap: _resetWorkout,
          scale: scale,
        ),
      ],
    );
  }

  // ============================================================
  // VISUAL
  // ============================================================

  Widget _buildWorkoutVisual(double scale) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final value = _animationController.value;

        final outerSize = (205 + value * 8) * scale;

        final innerSize = (145 + value * 6) * scale;

        return SizedBox(
          width: outerSize,
          height: outerSize,
          child: Center(
            child: Container(
              width: outerSize,
              height: outerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.10)),
              ),
              child: Center(
                child: Container(
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.24),
                        AppColors.primary.withOpacity(0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 84 * scale,
                      height: 84 * scale,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.35),
                        ),
                      ),
                      child: Icon(
                        widget.session.icon,
                        color: AppColors.primary,
                        size: 40 * scale,
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
  // TIMER
  // ============================================================

  Widget _buildTimer(double scale) {
    final totalSeconds = widget.session.minutes * 60;

    final remaining = (totalSeconds - _currentSecond).clamp(0, totalSeconds);

    return Text(
      _formatTime(remaining),
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 38 * scale,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  Widget _buildProgress(double scale) {
    final total = widget.session.minutes * 60;

    final progress = total == 0
        ? 0.0
        : (_currentSecond / total).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 5 * scale,
        backgroundColor: AppColors.primary.withOpacity(0.10),
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  // ============================================================
  // CONTROLS
  // ============================================================

  Widget _buildControls(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _playerControl(
          icon: Icons.replay_10_rounded,
          onTap: () {
            setState(() {
              _currentSecond = (_currentSecond - 10).clamp(
                0,
                widget.session.minutes * 60,
              );
            });
          },
          scale: scale,
        ),

        SizedBox(width: 30 * scale),

        GestureDetector(
          onTap: _toggleWorkout,
          child: Container(
            width: 70 * scale,
            height: 70 * scale,
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
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.black,
              size: 32 * scale,
            ),
          ),
        ),

        SizedBox(width: 30 * scale),

        _playerControl(
          icon: Icons.forward_10_rounded,
          onTap: () {
            setState(() {
              _currentSecond = (_currentSecond + 10).clamp(
                0,
                widget.session.minutes * 60,
              );
            });
          },
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
          child: Icon(icon, color: AppColors.textPrimary, size: 26 * scale),
        ),
      ),
    );
  }

  // ============================================================
  // WORKOUT INFO
  // ============================================================

  Widget _buildWorkoutInfo(double scale) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _infoItem(
              icon: Icons.timer_outlined,
              value: widget.session.duration,
              label: 'Duration',
              scale: scale,
            ),
          ),
          Expanded(
            child: _infoItem(
              icon: Icons.local_fire_department_outlined,
              value: '${widget.session.calories}',
              label: 'Calories',
              scale: scale,
            ),
          ),
          Expanded(
            child: _infoItem(
              icon: Icons.signal_cellular_alt_rounded,
              value: widget.session.level,
              label: 'Level',
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String value,
    required String label,
    required double scale,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 19 * scale),
        SizedBox(height: 6 * scale),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11.5 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 3 * scale),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 9 * scale),
        ),
      ],
    );
  }

  // ============================================================
  // EXERCISE HINT
  // ============================================================

  Widget _buildExerciseHint(double scale) {
    final message = _isPlaying
        ? 'Keep moving at a comfortable pace.'
        : _isPaused
        ? 'Take a breath. Continue when you are ready.'
        : 'Get ready. Start when you feel comfortable.';

    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 5 * scale),

        Text(
          'Listen to your body and maintain a comfortable pace.',
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
