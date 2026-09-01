import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class QuickActionItem extends StatelessWidget {
  const QuickActionItem({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  double _scale(double width) {
    return (width / 390).clamp(0.88, 1.12);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    final iconContainer = (46 * scale).clamp(42.0, 52.0);
    final iconSize = (22 * scale).clamp(20.0, 26.0);
    final fontSize = (11.5 * scale).clamp(10.5, 13.0);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withOpacity(.10),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: 8 * scale,
            vertical: 10 * scale,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(.18)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: iconContainer,
                height: iconContainer,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(.14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: iconSize),
              ),

              SizedBox(height: 8 * scale),

              Expanded(
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
