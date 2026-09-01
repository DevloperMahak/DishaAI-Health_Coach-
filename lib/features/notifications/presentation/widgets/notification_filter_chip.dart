import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class NotificationFilterChip extends StatelessWidget {
  const NotificationFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.12);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final bool tablet = width >= 700;

    final scale = _scale(width);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),

      margin: EdgeInsets.only(right: 10 * scale),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius: BorderRadius.circular(30),

          onTap: onTap,

          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: tablet ? 18 : 15,
              vertical: tablet ? 13 : 10,
            ),

            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,

              borderRadius: BorderRadius.circular(30),

              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),

              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,

              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: tablet ? 18 : 16,
                    color: selected ? Colors.black : AppColors.primary,
                  ),

                  SizedBox(width: 6 * scale),
                ],

                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.black : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: tablet ? 15 : 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
