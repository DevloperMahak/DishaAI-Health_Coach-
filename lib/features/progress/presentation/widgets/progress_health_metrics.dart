import 'package:flutter/material.dart';

import 'package:disha_ai/app/theme/app_colors.dart';

class ProgressHealthMetrics extends StatelessWidget {
  const ProgressHealthMetrics({
    super.key,
    required this.calories,
    required this.caloriesTarget,
    required this.caloriesProgress,
    required this.water,
    required this.waterTargetMl,
    required this.waterProgress,
    required this.sleep,
    required this.sleepTarget,
    required this.sleepProgress,
    required this.steps,
    required this.stepsTarget,
    required this.stepsProgress,
  });

  // ============================================================
  // CALORIES
  // ============================================================

  final String calories;
  final double caloriesTarget;
  final double caloriesProgress;

  // ============================================================
  // WATER
  // ============================================================

  final String water;
  final double waterTargetMl;
  final double waterProgress;

  // ============================================================
  // SLEEP
  // ============================================================

  final String sleep;
  final double sleepTarget;
  final double sleepProgress;

  // ============================================================
  // STEPS
  // ============================================================

  final String steps;
  final double stepsTarget;
  final double stepsProgress;

  // ============================================================
  // HELPERS
  // ============================================================

  double _normalizeProgress(double value) {
    // Backend contract currently returns percentages such as:
    // 89.3, 84.0, 87.5, 88.0.
    //
    // This also safely supports 0.0 - 1.0 values if the backend
    // ever changes to that representation.

    if (value <= 0) {
      return 0.0;
    }

    if (value <= 1.0) {
      return value.clamp(0.0, 1.0);
    }

    return (value / 100.0).clamp(0.0, 1.0);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _formatWaterTarget(double ml) {
    if (ml <= 0) {
      return '—';
    }

    final double liters = ml / 1000.0;

    if (liters == liters.roundToDouble()) {
      return '${liters.toInt()} L';
    }

    return '${liters.toStringAsFixed(1)} L';
  }

  String _formatCaloriesTarget(double value) {
    if (value <= 0) {
      return '—';
    }

    return '${_formatNumber(value)} kcal';
  }

  String _formatSleepTarget(double value) {
    if (value <= 0) {
      return '—';
    }

    return '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)} hrs';
  }

  String _formatStepsTarget(double value) {
    if (value <= 0) {
      return '—';
    }

    return _formatNumber(value);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        final int columns;

        if (width >= 900) {
          columns = 4;
        } else if (width >= 560) {
          columns = 2;
        } else {
          columns = 2;
        }

        final double spacing = width < 400 ? 10.0 : 14.0;

        final double cardWidth = (width - (spacing * (columns - 1))) / columns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // SECTION HEADER
            // ======================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),

                const SizedBox(width: 11),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Health Metrics',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Track your progress against your daily goals',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ======================================================
            // METRICS GRID
            // ======================================================
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    title: 'Water',
                    value: water,
                    unit: 'L',
                    targetLabel: _formatWaterTarget(waterTargetMl),
                    progress: _normalizeProgress(waterProgress),
                    icon: Icons.water_drop_rounded,
                    iconColor: Colors.blue,
                    progressColor: Colors.blue,
                  ),
                ),

                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    title: 'Calories',
                    value: calories,
                    unit: 'kcal',
                    targetLabel: _formatCaloriesTarget(caloriesTarget),
                    progress: _normalizeProgress(caloriesProgress),
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.orange,
                    progressColor: Colors.orange,
                  ),
                ),

                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    title: 'Sleep',
                    value: sleep,
                    unit: 'hrs',
                    targetLabel: _formatSleepTarget(sleepTarget),
                    progress: _normalizeProgress(sleepProgress),
                    icon: Icons.bedtime_rounded,
                    iconColor: Colors.indigo,
                    progressColor: Colors.indigo,
                  ),
                ),

                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    title: 'Steps',
                    value: steps,
                    unit: '',
                    targetLabel: _formatStepsTarget(stepsTarget),
                    progress: _normalizeProgress(stepsProgress),
                    icon: Icons.directions_walk_rounded,
                    iconColor: Colors.green,
                    progressColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// METRIC CARD
// ============================================================================

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.targetLabel,
    required this.progress,
    required this.icon,
    required this.iconColor,
    required this.progressColor,
  });

  final String title;
  final String value;
  final String unit;
  final String targetLabel;
  final double progress;
  final IconData icon;
  final Color iconColor;
  final Color progressColor;

  String _percentageText() {
    return '${(progress * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================================
          // TOP
          // ==========================================================
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                _percentageText(),
                style: TextStyle(
                  color: progressColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ==========================================================
          // VALUE
          // ==========================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),

              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // ==========================================================
          // PROGRESS BAR
          // ==========================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: progressColor.withOpacity(.10),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),

          const SizedBox(height: 8),

          // ==========================================================
          // TARGET
          // ==========================================================
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Goal',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ),

              Flexible(
                child: Text(
                  targetLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
