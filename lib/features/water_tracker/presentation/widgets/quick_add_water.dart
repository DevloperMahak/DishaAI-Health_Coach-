import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class QuickAddWater extends StatelessWidget {
  const QuickAddWater({
    super.key,
    required this.onAdd100,
    required this.onAdd250,
    required this.onAdd500,
    required this.onCustomTap,
  });

  final VoidCallback onAdd100;
  final VoidCallback onAdd250;
  final VoidCallback onAdd500;
  final VoidCallback onCustomTap;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.15);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //--------------------------------------------------
        // TITLE
        //--------------------------------------------------
        Text(
          "Quick Add Water",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: (20 * scale).clamp(18.0, 24.0),
            fontWeight: FontWeight.w800,
          ),
        ),

        SizedBox(height: 6 * scale),

        Text(
          "Log your water intake instantly",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: (13 * scale).clamp(12.0, 15.0),
          ),
        ),

        SizedBox(height: 20 * scale),

        //--------------------------------------------------
        // GRID
        //--------------------------------------------------
        GridView.count(
          crossAxisCount: width >= 700 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.1,
          children: [
            _QuickWaterButton(
              icon: Icons.local_drink_rounded,
              title: "100 ml",
              subtitle: "Small Glass",
              onTap: onAdd100,
            ),

            _QuickWaterButton(
              icon: Icons.sports_bar_rounded,
              title: "250 ml",
              subtitle: "Regular Glass",
              onTap: onAdd250,
            ),

            _QuickWaterButton(
              icon: Icons.water_drop_rounded,
              title: "500 ml",
              subtitle: "Bottle",
              onTap: onAdd500,
            ),

            _QuickWaterButton(
              icon: Icons.add_circle_rounded,
              title: "Custom",
              subtitle: "Enter Amount",
              onTap: onCustomTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickWaterButton extends StatelessWidget {
  const _QuickWaterButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.primary.withOpacity(.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(.12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 28),
                ),

                const SizedBox(height: 14),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
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
