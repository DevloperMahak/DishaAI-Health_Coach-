import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.onSkip,
  });

  final int currentStep;
  final int totalSteps;

  final VoidCallback onBack;
  final VoidCallback onSkip;

  // ============================================================
  // RESPONSIVE SCALE
  // ============================================================

  double _getScale(double width) {
    return (width / 390).clamp(0.88, 1.12);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _getScale(width);

    final iconSize = (21 * scale).clamp(19.0, 23.0);

    final skipFontSize = (13 * scale).clamp(12.0, 15.0);

    final progressFontSize = (12 * scale).clamp(11.0, 14.0);

    final progressHeight = (5 * scale).clamp(4.0, 6.0);

    return Column(
      children: [
        // ========================================================
        // BACK + SKIP
        // ========================================================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ----------------------------------------------------
            // BACK
            // ----------------------------------------------------
            SizedBox(
              width: 42 * scale,
              height: 42 * scale,
              child: IconButton(
                onPressed: onBack,
                padding: EdgeInsets.zero,
                splashRadius: 22 * scale,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: iconSize,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // ----------------------------------------------------
            // SKIP
            // ----------------------------------------------------
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 6 * scale,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: skipFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 5 * scale),

        // ========================================================
        // PROGRESS BAR + STEP
        // ========================================================
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ----------------------------------------------------
            // PROGRESS BAR
            // ----------------------------------------------------
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(progressHeight),
                child: LinearProgressIndicator(
                  minHeight: progressHeight,
                  value: currentStep / totalSteps,
                  backgroundColor: AppColors.textSecondary.withOpacity(0.28),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            ),

            SizedBox(width: 12 * scale),

            // ----------------------------------------------------
            // STEP
            // ----------------------------------------------------
            Text(
              '$currentStep/$totalSteps',
              style: TextStyle(
                fontSize: progressFontSize,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
