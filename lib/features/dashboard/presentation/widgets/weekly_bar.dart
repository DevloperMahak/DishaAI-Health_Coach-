import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class WeeklyBar extends StatelessWidget {
  const WeeklyBar({
    super.key,
    required this.day,
    required this.value,
    required this.color,
    this.selected = false,
  });

  final String day;
  final double value;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // SAFE PROGRESS VALUE
    // ============================================================

    double safeValue = value;

    if (!safeValue.isFinite) {
      safeValue = 0.0;
    }

    safeValue = safeValue.clamp(0.0, 1.0);

    final double barHeight = 90.0 * safeValue;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      children: [
        // ============================================================
        // PROGRESS BAR
        // ============================================================
        Container(
          height: barHeight,
          width: 18.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [color, color.withOpacity(.45)],
            ),
            boxShadow: [
              if (selected)
                BoxShadow(color: color.withOpacity(.35), blurRadius: 12),
            ],
          ),
        ),

        // ============================================================
        // DAY LABEL
        // ============================================================
        const SizedBox(height: 10),

        Text(
          day,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
