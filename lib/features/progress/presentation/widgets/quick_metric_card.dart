import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class QuickMetricCard extends StatelessWidget {
  const QuickMetricCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String unit;

  double _scale(double width) => (width / 390).clamp(.88, 1.15);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 390).clamp(.88, 1.15);

    final iconSize = (24 * scale).clamp(20.0, 28.0);
    final circle = (46 * scale).clamp(42.0, 52.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8 * scale,
        vertical: 14 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: circle,
            height: circle,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(.12),
              border: Border.all(color: iconColor.withOpacity(.5)),
            ),
            child: Icon(icon, color: iconColor, size: iconSize),
          ),

          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18 * scale,
              ),
            ),
          ),

          Text(
            unit,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11 * scale,
            ),
          ),

          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10 * scale,
            ),
          ),
        ],
      ),
    );
  }
}
