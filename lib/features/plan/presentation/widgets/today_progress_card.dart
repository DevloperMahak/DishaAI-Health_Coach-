import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class TodayProgressCard extends StatelessWidget {
  const TodayProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bool tablet = width > 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: tablet ? width * .05 : 0),

      padding: EdgeInsets.all(tablet ? 24 : 18),

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
                  "Today's Progress",

                  style: TextStyle(
                    color: AppColors.textPrimary,

                    fontSize: tablet ? 22 : 18,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "4 / 7 Tasks Completed",

                  style: TextStyle(
                    color: AppColors.textSecondary,

                    fontSize: tablet ? 16 : 13,
                  ),
                ),

                const SizedBox(height: 16),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),

                  child: LinearProgressIndicator(
                    value: .6,

                    minHeight: tablet ? 10 : 8,

                    backgroundColor: AppColors.background,

                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          SizedBox(
            height: tablet ? 90 : 75,

            width: tablet ? 90 : 75,

            child: Stack(
              alignment: Alignment.center,

              children: [
                CircularProgressIndicator(
                  value: .6,

                  strokeWidth: tablet ? 9 : 7,

                  backgroundColor: AppColors.background,

                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),

                Text(
                  "60%",

                  style: TextStyle(
                    color: AppColors.textPrimary,

                    fontSize: tablet ? 20 : 17,

                    fontWeight: FontWeight.bold,
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
