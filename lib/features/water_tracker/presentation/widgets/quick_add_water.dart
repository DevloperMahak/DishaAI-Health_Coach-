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
    return (width / 390).clamp(0.88, 1.15);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    final bool isTablet = width >= 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =========================================================
        // TITLE
        // =========================================================
        Text(
          'Quick Add Water',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: (20 * scale).clamp(18.0, 24.0),
            fontWeight: FontWeight.w800,
          ),
        ),

        SizedBox(height: 6 * scale),

        Text(
          'Log your water intake instantly',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: (13 * scale).clamp(12.0, 15.0),
          ),
        ),

        SizedBox(height: 20 * scale),

        // =========================================================
        // GRID
        // =========================================================
        GridView.count(
          crossAxisCount: isTablet ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          crossAxisSpacing: 14,
          mainAxisSpacing: 14,

          // The previous 1.1 ratio was making the cards too short.
          childAspectRatio: isTablet ? 1.15 : 0.90,

          children: [
            _QuickWaterButton(
              icon: Icons.local_drink_rounded,
              title: '100 ml',
              subtitle: 'Small Glass',
              onTap: onAdd100,
              scale: scale,
            ),

            _QuickWaterButton(
              icon: Icons.sports_bar_rounded,
              title: '250 ml',
              subtitle: 'Regular Glass',
              onTap: onAdd250,
              scale: scale,
            ),

            _QuickWaterButton(
              icon: Icons.water_drop_rounded,
              title: '500 ml',
              subtitle: 'Bottle',
              onTap: onAdd500,
              scale: scale,
            ),

            _QuickWaterButton(
              icon: Icons.add_circle_rounded,
              title: 'Custom',
              subtitle: 'Enter Amount',
              onTap: onCustomTap,
              scale: scale,
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
    required this.scale,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final double iconContainerSize = (52 * scale).clamp(46.0, 58.0);
    final double iconSize = (28 * scale).clamp(24.0, 32.0);
    final double titleSize = (17 * scale).clamp(15.0, 19.0);
    final double subtitleSize = (12 * scale).clamp(11.0, 13.0);
    final double padding = (16 * scale).clamp(13.0, 18.0);

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
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(.12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: iconSize),
                ),

                SizedBox(height: 12 * scale),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 5 * scale),

                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: subtitleSize,
                    height: 1.25,
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
