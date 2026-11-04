import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class StreakCard extends StatelessWidget {
  final int streakDays;

  const StreakCard({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bool tablet = width > 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: tablet ? width * .05 : 0),
      padding: EdgeInsets.all(tablet ? 22 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(tablet ? 18 : 14),
        border: Border.all(color: AppColors.primaryDark.withOpacity(.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🔥 $streakDays Days Streak",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: tablet ? 22 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Keep your wellness journey going",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: tablet ? 15 : 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: tablet ? 55 : 45,
            width: tablet ? 55 : 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(.15),
            ),
            child: Icon(
              Icons.local_fire_department,
              color: AppColors.primary,
              size: tablet ? 32 : 26,
            ),
          ),
        ],
      ),
    );
  }
}
