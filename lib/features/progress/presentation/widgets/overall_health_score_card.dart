import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class OverallHealthScoreCard extends StatelessWidget {
  const OverallHealthScoreCard({
    super.key,
    required this.healthScore,
    required this.weeklyImprovement,
    required this.status,
  });

  final int healthScore;
  final int weeklyImprovement;
  final String status;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.15);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    return Container(
      padding: EdgeInsets.all(22 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          //------------------------------------------------------
          // Header
          //------------------------------------------------------
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                ),
              ),

              SizedBox(width: 14 * scale),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Overall Health Score",
                      style: TextStyle(
                        fontSize: (17 * scale).clamp(16, 20),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Updated today",
                      style: TextStyle(
                        fontSize: (12 * scale).clamp(11, 13),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 28 * scale),

          //------------------------------------------------------
          // Circular Score
          //------------------------------------------------------
          SizedBox(
            width: 170 * scale,
            height: 170 * scale,
            child: CustomPaint(
              painter: _ScorePainter(progress: healthScore / 100),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$healthScore",
                      style: TextStyle(
                        fontSize: (38 * scale).clamp(34, 44),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),

                    Text(
                      "/100",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: (13 * scale).clamp(12, 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 24 * scale),

          //------------------------------------------------------
          // Bottom Stats
          //------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.trending_up_rounded,
                  title: "This Week",
                  value: "+$weeklyImprovement%",
                  color: Colors.green,
                ),
              ),

              SizedBox(width: 14 * scale),

              Expanded(
                child: _InfoTile(
                  icon: Icons.auto_awesome_rounded,
                  title: "AI Status",
                  value: status,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePainter extends CustomPainter {
  _ScorePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;

    final center = Offset(size.width / 2, size.height / 2);

    final radius = (size.width - stroke) / 2;

    final background = Paint()
      ..color = Colors.white.withOpacity(.08)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    canvas.drawCircle(center, radius, background);

    final foreground = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primaryDark, AppColors.primary],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * math.pi * 2,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _ScorePainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
