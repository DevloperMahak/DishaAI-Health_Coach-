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
    return (width / 390).clamp(0.88, 1.15);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final bool tablet = width >= 700;
    final scale = _scale(width);

    final double buttonSize = tablet ? 52 : 44;

    return Padding(
      padding: EdgeInsets.only(top: tablet ? 14 : 6, bottom: tablet ? 20 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============================================================
          // HEADER
          // ============================================================
          Row(
            children: [
              // BACK BUTTON
              _circleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
                tablet: tablet,
                tooltip: 'Back',
              ),

              const SizedBox(width: 10),

              // CENTERED TITLE
              Expanded(
                child: Text(
                  'Notifications',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: tablet ? 28 : 21 * scale,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // CLEAR ALL BUTTON
              _circleButton(
                icon: Icons.delete_outline_rounded,
                onTap: onSettings,
                tablet: tablet,
                tooltip: 'Clear all notifications',
                iconColor: Colors.redAccent,
              ),
            ],
          ),

          SizedBox(height: tablet ? 24 : 20 * scale),

          // ============================================================
          // NOTIFICATION STATUS CARD
          // ============================================================
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: tablet ? 20 : 14,
              vertical: tablet ? 16 : 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                // NOTIFICATION ICON
                Container(
                  width: tablet ? 44 : 40,
                  height: tablet ? 44 : 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    unreadCount > 0
                        ? Icons.notifications_active_rounded
                        : Icons.check_circle_outline_rounded,
                    color: AppColors.primary,
                    size: tablet ? 23 : 21,
                  ),
                ),

                const SizedBox(width: 12),

                // STATUS TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unreadCount > 0
                            ? 'Your notifications'
                            : 'All caught up!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: tablet ? 16 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        unreadCount == 0
                            ? 'You have no unread notifications'
                            : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: tablet ? 13 : 11.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // UNREAD BADGE
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),

                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ============================================================
          // MARK ALL AS READ
          // ============================================================
          if (unreadCount > 0) ...[
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onMarkAllRead,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.done_all_rounded, size: 19),
                label: Text(
                  'Mark all as read',
                  style: TextStyle(
                    fontSize: tablet ? 14 : 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // CIRCLE ICON BUTTON
  // ============================================================

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool tablet,
    required String tooltip,
    Color? iconColor,
  }) {
    final double size = tablet ? 52 : 44;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: CircleBorder(
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            height: size,
            width: size,
            child: Icon(
              icon,
              color: iconColor ?? AppColors.primary,
              size: tablet ? 24 : 20,
            ),
          ),
        ),
      ),
    );
  }
}
