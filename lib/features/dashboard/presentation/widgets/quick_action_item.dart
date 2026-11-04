import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class QuickActionItem extends StatelessWidget {
  const QuickActionItem({
    super.key,
    required this.title,
    required this.imagePath,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String imagePath;
  final Color color;
  final VoidCallback onTap;

  double _scale(double width) {
    return (width / 390).clamp(0.85, 1.1);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    // Outer circle size
    final imageContainer = (64 * scale).clamp(56.0, 72.0);
    final fontSize = (11 * scale).clamp(10.0, 12.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: color.withOpacity(.12),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 2 * scale,
          vertical: 2 * scale,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: imageContainer,
              height: imageContainer,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(.14),
              ),
              alignment: Alignment.center,
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  width: imageContainer,
                  height: imageContainer,
                  fit: BoxFit.contain, // Fills the entire outer circle cleanly
                ),
              ),
            ),
            SizedBox(height: 5 * scale),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
