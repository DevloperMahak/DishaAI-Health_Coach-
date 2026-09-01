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
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, height, __) {
              return Container(
                height: 90 * height,
                width: 18,
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
              );
            },
          ),

          const SizedBox(height: 10),

          Text(
            day,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
