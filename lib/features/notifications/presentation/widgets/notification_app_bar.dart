import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class NotificationAppBar extends StatelessWidget {
  const NotificationAppBar({
    super.key,
    required this.unreadCount,
    required this.onBack,
    required this.onSettings,
    required this.onMarkAllRead,
  });

  final int unreadCount;

  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback onMarkAllRead;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.15);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final bool tablet = width >= 700;

    final scale = _scale(width);

    return Container(
      padding: EdgeInsets.only(top: tablet ? 12 : 6, bottom: 18 * scale),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          //----------------------------------------------------
          // Top Row
          //----------------------------------------------------
          Row(
            children: [
              _circleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
                tablet: tablet,
              ),

              Expanded(
                child: Text(
                  "Notifications",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: tablet ? 28 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 18 * scale),

          //----------------------------------------------------
          // Subtitle
          //----------------------------------------------------
          Row(
            children: [
              Expanded(
                child: Text(
                  unreadCount == 0
                      ? "You're all caught up 🎉"
                      : "$unreadCount unread notifications",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: tablet ? 15 : 13,
                  ),
                ),
              ),

              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: onMarkAllRead,

                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                  ),

                  icon: const Icon(Icons.done_all_rounded, size: 18),

                  label: const Text(
                    "Mark all read",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  //----------------------------------------------------
  // Circle Button
  //----------------------------------------------------

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool tablet,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(50),

      child: Container(
        height: tablet ? 52 : 46,
        width: tablet ? 52 : 46,

        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,

          border: Border.all(color: AppColors.border),
        ),

        child: Icon(icon, color: AppColors.primary, size: tablet ? 24 : 20),
      ),
    );
  }
}
