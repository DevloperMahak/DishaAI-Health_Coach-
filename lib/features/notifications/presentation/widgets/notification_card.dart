import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isUnread = false,
    this.onTap,
    this.onDelete,
  });

  final String title;
  final String message;
  final String time;

  final IconData icon;
  final Color iconColor;

  final bool isUnread;

  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.15);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final bool tablet = width >= 700;

    final scale = _scale(width);

    return Padding(
      padding: EdgeInsets.only(bottom: 14 * scale),

      child: Dismissible(
        key: ValueKey("$title$time"),

        direction: DismissDirection.endToStart,

        onDismissed: (_) {
          onDelete?.call();
        },

        background: Container(
          alignment: Alignment.centerRight,

          padding: const EdgeInsets.only(right: 24),

          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(22),
          ),

          child: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),

        child: Material(
          color: Colors.transparent,

          child: InkWell(
            onTap: onTap,

            borderRadius: BorderRadius.circular(22),

            child: Ink(
              padding: EdgeInsets.all(tablet ? 18 : 16),

              decoration: BoxDecoration(
                color: AppColors.surface,

                borderRadius: BorderRadius.circular(22),

                border: Border.all(
                  color: isUnread
                      ? AppColors.primary.withOpacity(.35)
                      : AppColors.border,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  //------------------------------------------------
                  // Icon
                  //------------------------------------------------
                  Container(
                    width: tablet ? 56 : 50,
                    height: tablet ? 56 : 50,

                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(.12),
                      shape: BoxShape.circle,
                    ),

                    child: Icon(icon, color: iconColor, size: tablet ? 28 : 24),
                  ),

                  SizedBox(width: 14 * scale),

                  //------------------------------------------------
                  // Text
                  //------------------------------------------------
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: tablet ? 17 : 15,
                                ),
                              ),
                            ),

                            if (isUnread)
                              Container(
                                width: 10,
                                height: 10,

                                margin: const EdgeInsets.only(left: 8),

                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),

                        SizedBox(height: 8 * scale),

                        Text(
                          message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: tablet ? 14 : 13,
                            height: 1.45,
                          ),
                        ),

                        SizedBox(height: 12 * scale),

                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              time,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const Spacer(),

                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
