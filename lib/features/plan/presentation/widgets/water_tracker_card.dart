import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class WaterTrackerCard extends StatelessWidget {
  const WaterTrackerCard({
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

  String _formatLiters(int ml) {
    if (ml >= 1000) {
      final liters = ml / 1000;

      if (liters == liters.roundToDouble()) {
        return '${liters.toInt()}L';
      }

      return '${liters.toStringAsFixed(1)}L';
    }

    return '${ml}ml';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final bool tablet = width > 600;

    final double safeProgress = progress.clamp(0.0, 1.0);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: tablet ? width * .05 : 0),
      padding: EdgeInsets.all(tablet ? 22 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(tablet ? 18 : 14),
        border: Border.all(color: AppColors.primaryDark.withOpacity(.6)),
      ),
      child: Row(
        children: [
          Container(
            height: tablet ? 60 : 50,
            width: tablet ? 60 : 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(.15),
            ),
            child: Icon(
              Icons.water_drop_outlined,
              color: AppColors.primary,
              size: tablet ? 32 : 26,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Water Intake',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: tablet ? 20 : 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: safeProgress,
                    minHeight: tablet ? 10 : 8,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_formatLiters(currentIntake)} / '
                        '${_formatLiters(dailyGoal)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: tablet ? 14 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: tablet ? 14 : 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
