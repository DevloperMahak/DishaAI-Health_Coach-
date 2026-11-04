import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class WaterProgressCard extends StatefulWidget {
  const WaterProgressCard({
    super.key,
    required this.currentIntake,
    required this.dailyGoal,
    required this.progress,
    required this.percentage,
  });

  final int currentIntake;
  final int dailyGoal;
  final double progress;
  final int percentage;

  @override
  State<WaterProgressCard> createState() => _WaterProgressCardState();
}

class _WaterProgressCardState extends State<WaterProgressCard>
    with SingleTickerProviderStateMixin {
  // ===============================================================
  // ANIMATION CONTROLLER
  // ===============================================================

  late final AnimationController _controller;

  // IMPORTANT:
  // This MUST NOT be "late final".
  //
  // didUpdateWidget() needs to replace the animation whenever the
  // water progress changes.
  late Animation<double> _animation;

  // ===============================================================
  // INIT
  // ===============================================================

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: _safeProgress(widget.progress),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  // ===============================================================
  // WIDGET UPDATE
  // ===============================================================

  @override
  void didUpdateWidget(covariant WaterProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only animate when the actual progress changes.
    if (oldWidget.progress != widget.progress) {
      final double currentValue = _animation.value;
      final double newProgress = _safeProgress(widget.progress);

      // Replace the animation.
      //
      // This is now legal because _animation is not "final".
      _animation = Tween<double>(begin: currentValue, end: newProgress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );

      // Restart the animation from the current visual value.
      _controller
        ..reset()
        ..forward();
    }
  }

  // ===============================================================
  // SAFE PROGRESS
  // ===============================================================

  double _safeProgress(double value) {
    if (value.isNaN || value.isInfinite) {
      return 0.0;
    }

    return value.clamp(0.0, 1.0).toDouble();
  }

  // ===============================================================
  // DISPOSE
  // ===============================================================

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ===============================================================
  // RESPONSIVE SCALE
  // ===============================================================

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.15);
  }

  // ===============================================================
  // FORMAT WATER
  // ===============================================================

  String _format(int ml) {
    if (ml >= 1000) {
      final double litre = ml / 1000;

      return '${litre.toStringAsFixed(litre % 1 == 0 ? 0 : 1)} L';
    }

    return '$ml ml';
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double scale = _scale(width);

    final int remaining = (widget.dailyGoal - widget.currentIntake).clamp(
      0,
      widget.dailyGoal,
    );

    return Container(
      padding: EdgeInsets.all(24 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withOpacity(.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(color: AppColors.primary.withOpacity(.08), blurRadius: 20),
        ],
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Column(
            children: [
              // =======================================================
              // CIRCULAR PROGRESS
              // =======================================================
              SizedBox(
                width: 240 * scale,
                height: 240 * scale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220 * scale,
                      height: 220 * scale,
                      child: CustomPaint(
                        painter: _WaterProgressPainter(
                          progress: _animation.value,
                        ),
                      ),
                    ),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 70 * scale,
                          height: 70 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(.12),
                          ),
                          child: const Icon(
                            Icons.water_drop_rounded,
                            color: AppColors.primary,
                            size: 36,
                          ),
                        ),

                        SizedBox(height: 18 * scale),

                        Text(
                          '${widget.percentage}%',
                          style: TextStyle(
                            fontSize: (42 * scale).clamp(34.0, 48.0),
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        SizedBox(height: 6 * scale),

                        Text(
                          'Hydration',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: (14 * scale).clamp(12.0, 16.0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 28 * scale),

              // =======================================================
              // SUMMARY ROW 1
              // =======================================================
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: 'Current',
                      value: _format(widget.currentIntake),
                      icon: Icons.local_drink_rounded,
                    ),
                  ),

                  SizedBox(width: 16 * scale),

                  Expanded(
                    child: _InfoCard(
                      title: 'Goal',
                      value: _format(widget.dailyGoal),
                      icon: Icons.flag_rounded,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16 * scale),

              // =======================================================
              // SUMMARY ROW 2
              // =======================================================
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: 'Remaining',
                      value: _format(remaining),
                      icon: Icons.water_drop_outlined,
                    ),
                  ),

                  SizedBox(width: 16 * scale),

                  Expanded(
                    child: _InfoCard(
                      title: 'Status',
                      value: widget.percentage >= 100
                          ? 'Completed'
                          : widget.percentage >= 70
                          ? 'On Track'
                          : 'Keep Going',
                      icon: widget.percentage >= 100
                          ? Icons.emoji_events_rounded
                          : Icons.trending_up_rounded,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24 * scale),

              // =======================================================
              // MOTIVATION CARD
              // =======================================================
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(18 * scale),
                decoration: BoxDecoration(
                  color: widget.percentage >= 100
                      ? Colors.green.withOpacity(.08)
                      : AppColors.primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.percentage >= 100
                        ? Colors.green.withOpacity(.30)
                        : AppColors.primary.withOpacity(.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      widget.percentage >= 100
                          ? Icons.emoji_events_rounded
                          : Icons.lightbulb_rounded,
                      color: widget.percentage >= 100
                          ? Colors.green
                          : AppColors.primary,
                      size: 28,
                    ),

                    SizedBox(width: 14 * scale),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.percentage >= 100
                                ? 'Goal Achieved 🎉'
                                : 'AI Hydration Tip',
                            style: TextStyle(
                              fontSize: (16 * scale).clamp(15.0, 18.0),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          SizedBox(height: 8 * scale),

                          Text(
                            widget.percentage >= 100
                                ? "Excellent! You've completed today's hydration goal. Keep maintaining this healthy habit."
                                : remaining <= 250
                                ? "You're almost there. One more glass of water will complete today's goal."
                                : remaining <= 750
                                ? 'Great progress! Continue drinking water regularly over the next few hours.'
                                : 'Start with a glass of water now and sip consistently throughout the day instead of drinking a large amount at once.',
                            style: TextStyle(
                              height: 1.55,
                              color: AppColors.textSecondary,
                              fontSize: (13 * scale).clamp(12.0, 15.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===================================================================
// INFO CARD
// ===================================================================

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 26),

          const SizedBox(height: 12),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// CIRCULAR PROGRESS PAINTER
// ===================================================================

class _WaterProgressPainter extends CustomPainter {
  const _WaterProgressPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const double startAngle = -math.pi / 2;

    final Rect rect = Offset.zero & size;

    final Paint backgroundPaint = Paint()
      ..color = AppColors.primary.withOpacity(.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final Paint progressPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Background circle.
    canvas.drawArc(rect, startAngle, math.pi * 2, false, backgroundPaint);

    // Progress arc.
    canvas.drawArc(
      rect,
      startAngle,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
