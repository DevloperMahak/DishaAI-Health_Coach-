import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class HydrationAICard extends StatelessWidget {
  const HydrationAICard({
    super.key,
    required this.message,
    required this.hydrationScore,
  });

  final String message;
  final int hydrationScore;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.15);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    final Color scoreColor = hydrationScore >= 90
        ? Colors.green
        : hydrationScore >= 70
        ? AppColors.primary
        : Colors.orange;

    return Container(
      padding: EdgeInsets.all(22 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withOpacity(.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(color: AppColors.primary.withOpacity(.06), blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //----------------------------------------------------
          // HEADER
          //----------------------------------------------------
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(.12),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),

              SizedBox(width: 16 * scale),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rhea AI Coach",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: (19 * scale).clamp(17.0, 22.0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 4 * scale),

                    Text(
                      "Personalized hydration insights",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: (13 * scale).clamp(12.0, 15.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 24 * scale),

          //----------------------------------------------------
          // HYDRATION SCORE
          //----------------------------------------------------
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18 * scale),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scoreColor.withOpacity(.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite_rounded, color: scoreColor, size: 34),

                SizedBox(width: 16 * scale),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hydration Score",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: (13 * scale).clamp(12.0, 15.0),
                        ),
                      ),

                      SizedBox(height: 6 * scale),

                      Text(
                        "$hydrationScore / 100",
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.w900,
                          fontSize: (28 * scale).clamp(24.0, 32.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 22 * scale),

          //----------------------------------------------------
          // AI MESSAGE
          //----------------------------------------------------
          Text(
            message,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: (14 * scale).clamp(13.0, 16.0),
              height: 1.6,
            ),
          ),

          SizedBox(height: 20 * scale),

          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14 * scale),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8 * scale),
                const Text(
                  "AI updates after every water log",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
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
