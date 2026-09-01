import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  double _scale(double width) {
    return (width / 390).clamp(0.88, 1.12);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    final iconSize = (21 * scale).clamp(19.0, 24.0);
    final titleSize = (13 * scale).clamp(12.0, 15.0);
    final radius = (10 * scale).clamp(8.0, 12.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withOpacity(.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withOpacity(.45),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14 * scale,
              vertical: 12 * scale,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 38 * scale,
                  height: 38 * scale,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(.15)
                        : AppColors.surface.withOpacity(.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),

                SizedBox(width: 14 * scale),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: selected
                      ? Container(
                          key: const ValueKey(true),
                          width: 26 * scale,
                          height: 26 * scale,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 17,
                            color: Colors.black,
                          ),
                        )
                      : Container(
                          key: const ValueKey(false),
                          width: 26 * scale,
                          height: 26 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.textSecondary.withOpacity(.4),
                            ),
                          ),
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
