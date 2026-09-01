import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class BMIProgressCard extends StatelessWidget {
  const BMIProgressCard({super.key, required this.bmi, required this.category});

  final double bmi;
  final String category;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.12);
  }

  Color get _categoryColor {
    switch (category.toLowerCase()) {
      case "underweight":
        return Colors.orange;

      case "healthy":
        return Colors.green;

      case "overweight":
        return Colors.deepOrange;

      case "obese":
        return Colors.red;

      default:
        return AppColors.primary;
    }
  }

  double get _progress {
    return (bmi / 40).clamp(0.0, 1.0);
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
          //----------------------------------------------------
          // Header
          //----------------------------------------------------
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
                      "BMI Status",
                      style: TextStyle(
                        fontSize: (18 * scale).clamp(16.0, 20.0),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Body Mass Index",
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

          //----------------------------------------------------
          // BMI VALUE
          //----------------------------------------------------
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
                    category,
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

          //----------------------------------------------------
          // Progress Bar
          //----------------------------------------------------
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation(_categoryColor),
            ),
          ),

          SizedBox(height: 10 * scale),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "0",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                "40",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),

          SizedBox(height: 22 * scale),

          //----------------------------------------------------
          // BMI Ranges
          //----------------------------------------------------
          Row(
            children: [
              Expanded(
                child: _RangeChip(
                  title: "Healthy",
                  value: "18.5-24.9",
                  color: Colors.green,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _RangeChip(
                  title: "Over",
                  value: "25-29.9",
                  color: Colors.orange,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _RangeChip(
                  title: "Obese",
                  value: "30+",
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.30)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
