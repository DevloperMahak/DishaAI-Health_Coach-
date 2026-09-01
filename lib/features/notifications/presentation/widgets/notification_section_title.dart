import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class NotificationSectionTitle extends StatelessWidget {
  const NotificationSectionTitle({
    super.key,
    required this.title,
    this.count,
    this.icon,
  });

  final String title;
  final int? count;
  final IconData? icon;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.12);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final bool tablet = width >= 700;

    final scale = _scale(width);

    return Padding(
      padding: EdgeInsets.only(top: 18 * scale, bottom: 12 * scale),

      child: Row(
        children: [
          //--------------------------------------------------
          // Optional Icon
          //--------------------------------------------------
          if (icon != null) ...[
            Container(
              width: tablet ? 38 : 34,
              height: tablet ? 38 : 34,

              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.12),
                borderRadius: BorderRadius.circular(10),
              ),

              child: Icon(
                icon,
                color: AppColors.primary,
                size: tablet ? 20 : 18,
              ),
            ),

            SizedBox(width: 10 * scale),
          ],

          //--------------------------------------------------
          // Title
          //--------------------------------------------------
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: tablet ? 20 : 17,
              ),
            ),
          ),

          //--------------------------------------------------
          // Count Badge
          //--------------------------------------------------
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(.25)),
              ),

              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
