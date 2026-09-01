import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class NotificationEmptyState extends StatelessWidget {
  const NotificationEmptyState({super.key});

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.15);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final bool tablet = width >= 700;

    final scale = _scale(width);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tablet ? 60 : 28,
          vertical: tablet ? 80 : 50,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            //------------------------------------------------------
            // Icon
            //------------------------------------------------------
            Container(
              width: tablet ? 130 : 110,
              height: tablet ? 130 : 110,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(.08),
              ),

              child: Icon(
                Icons.notifications_off_rounded,
                size: tablet ? 62 : 52,
                color: AppColors.primary,
              ),
            ),

            SizedBox(height: 28 * scale),

            //------------------------------------------------------
            // Title
            //------------------------------------------------------
            Text(
              "No Notifications Yet",
              textAlign: TextAlign.center,

              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: tablet ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 12 * scale),

            //------------------------------------------------------
            // Subtitle
            //------------------------------------------------------
            Text(
              "We'll notify you about important updates, reminders and AI recommendations.",
              textAlign: TextAlign.center,

              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: tablet ? 15 : 13,
                height: 1.6,
              ),
            ),

            SizedBox(height: 32 * scale),

            //------------------------------------------------------
            // Feature List
            //------------------------------------------------------
            _item(Icons.smart_toy_rounded, "AI Coach Recommendations"),

            _item(Icons.water_drop_rounded, "Hydration & Workout Reminders"),

            _item(Icons.workspace_premium_rounded, "Achievements & Badges"),

            _item(Icons.calendar_month_rounded, "Personalized Plan Updates"),
          ],
        ),
      ),
    );
  }

  //------------------------------------------------------
  // Feature Tile
  //------------------------------------------------------

  Widget _item(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: AppColors.primary, size: 20),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
