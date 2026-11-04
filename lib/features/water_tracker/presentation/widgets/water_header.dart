import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class WaterHeader extends StatelessWidget {
  const WaterHeader({
    super.key,
    required this.goal,
    required this.current,
    required this.onBack,
  });

  final int goal;
  final int current;
  final VoidCallback onBack;

  // ============================================================
  // RESPONSIVE SCALE — SAME AS MEDITATION
  // ============================================================

  double _scale(double width) {
    return (width / 390).clamp(0.88, 1.12);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = _scale(width);

        return Row(
          children: [
            // ====================================================
            // BACK BUTTON — EXACTLY LIKE MEDITATION
            // ====================================================
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(21 * scale),
                child: Container(
                  width: 42 * scale,
                  height: 42 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.16),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 42 * scale * 0.46,
                  ),
                ),
              ),
            ),

            SizedBox(width: 14 * scale),

            // ====================================================
            // TITLE — SAME FONT AS MEDITATION
            // ====================================================
            Expanded(
              child: Text(
                'Water Tracker',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
