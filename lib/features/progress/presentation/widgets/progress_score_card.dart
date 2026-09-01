import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class ProgressScoreCard extends StatelessWidget {
  const ProgressScoreCard({
    super.key,
    required this.healthScore,
    required this.change,
  });

  final int healthScore;
  final double change;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.12);
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
            color: Colors.black.withOpacity(.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          //---------------------------------------------------
          // Circular Score
          //---------------------------------------------------
          SizedBox(
            width: 110 * scale,
            height: 110 * scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 110 * scale,
                  height: 110 * scale,
                  child: CircularProgressIndicator(
                    value: healthScore / 100,
                    strokeWidth: 10,
                    backgroundColor: AppColors.primary.withOpacity(.10),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$healthScore",
                      style: TextStyle(
                        fontSize: (28 * scale).clamp(24.0, 32.0),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),

                    Text(
                      "Score",
                      style: TextStyle(
                        fontSize: (12 * scale).clamp(11.0, 14.0),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: 22 * scale),

          //---------------------------------------------------
          // Details
          //---------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Health Score",
                  style: TextStyle(
                    fontSize: (18 * scale).clamp(16.0, 20.0),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 8 * scale),

                Text(
                  "Your overall wellness is improving consistently.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontSize: (12.5 * scale).clamp(11.5, 14.0),
                  ),
                ),

                SizedBox(height: 18 * scale),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.green,
                        size: 18,
                      ),

                      const SizedBox(width: 6),

                      Text(
                        "+${change.toStringAsFixed(1)}%",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(width: 4),

                      const Text(
                        "this week",
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
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
