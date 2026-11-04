import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class BMIProgressCard extends StatelessWidget {
  const BMIProgressCard({super.key, required this.bmi, required this.category});

  final double bmi;
  final String category;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.12);
  }

  // ============================================================
  // ASIAN BMI CLASSIFICATION
  // ============================================================
  //
  // BMI < 18.5       → Underweight
  // 18.5 ≤ BMI < 23  → Healthy
  // 23 ≤ BMI < 27.5  → Overweight
  // BMI ≥ 27.5       → Obese
  //
  // These thresholds are intended for adult Asian-population
  // risk classification and should not be applied to children
  // or adolescents.
  // ============================================================

  String get _displayCategory {
    if (bmi < 18.5) {
      return 'Underweight';
    }

    if (bmi < 23.0) {
      return 'Healthy';
    }

    if (bmi < 27.5) {
      return 'Overweight';
    }

    return 'Obese';
  }

  Color get _categoryColor {
    switch (_displayCategory.toLowerCase()) {
      case 'underweight':
        return Colors.orange;

      case 'healthy':
        return Colors.green;

      case 'overweight':
        return Colors.deepOrange;

      case 'obese':
        return Colors.red;

      default:
        return AppColors.primary;
    }
  }

  // ============================================================
  // PROGRESS
  // ============================================================
  //
  // BMI is displayed visually from 0 to 35.
  // Values above 35 are capped to keep the UI responsive.
  // ============================================================

  double get _progress {
    return (bmi / 35).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    return Container(
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HEADER
          // ======================================================
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monitor_weight_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BMI Status',
                      style: TextStyle(
                        fontSize: (18 * scale).clamp(16.0, 20.0),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Asian BMI Classification',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: (12 * scale).clamp(11.0, 14.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 24 * scale),

          // ======================================================
          // BMI VALUE
          // ======================================================
          Center(
            child: Column(
              children: [
                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: (42 * scale).clamp(36.0, 48.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _categoryColor.withOpacity(.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _displayCategory,
                    style: TextStyle(
                      color: _categoryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 26 * scale),

          // ======================================================
          // BMI PROGRESS BAR
          // ======================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(_categoryColor),
            ),
          ),

          SizedBox(height: 10 * scale),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '0',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                '35+',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),

          SizedBox(height: 22 * scale),

          // ======================================================
          // ASIAN BMI RANGES - ALL 4 CATEGORIES
          // ======================================================
          Row(
            children: [
              Expanded(
                child: _RangeChip(
                  title: 'Underweight',
                  value: '< 18.5',
                  color: Colors.orange,
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: _RangeChip(
                  title: 'Healthy',
                  value: '18.5–22.9',
                  color: Colors.green,
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: _RangeChip(
                  title: 'Overweight',
                  value: '23–24.9',
                  color: Colors.deepOrange,
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: _RangeChip(
                  title: 'Pre-Obese',
                  value: '25–29.9',
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(width: 6),

              Expanded(
                child: _RangeChip(
                  title: 'Obese',
                  value: '≥ 30',
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // CLASSIFICATION NOTE
          // ======================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 17,
                  color: AppColors.primary.withOpacity(.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Asian BMI thresholds are used for this classification. '
                    'BMI is a screening measure and does not by itself '
                    'diagnose health conditions.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.5 * scale,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// RANGE CHIP
// ================================================================

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.30)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
