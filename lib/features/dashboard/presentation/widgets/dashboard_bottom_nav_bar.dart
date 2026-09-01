import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class DashboardBottomNavBar extends StatelessWidget {
  const DashboardBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<_NavItem> _items = [
    _NavItem(label: 'Home', icon: Icons.home_rounded),
    _NavItem(label: 'Plan', icon: Icons.assignment_outlined),
    _NavItem(label: 'Progress', icon: Icons.bar_chart_rounded),
    _NavItem(label: 'AI Coach', icon: Icons.auto_awesome_rounded),
    _NavItem(
      label: 'Expert',
      icon: Icons.health_and_safety_rounded,
    ), // 💡 Replaced Profile with Expert
  ];

  // ==============================================================
  // RESPONSIVE
  // ==============================================================

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.12);
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    final barHeight = (74 * scale).clamp(68.0, 82.0);

    return SafeArea(
      top: false,
      child: Container(
        height: barHeight,
        margin: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 14 * scale),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withOpacity(.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.primary.withOpacity(.08),
              blurRadius: 18,
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (index) {
            final selected = currentIndex == index;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 4 * scale,
                  vertical: 6 * scale,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(index),
                    borderRadius: BorderRadius.circular(16 * scale),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16 * scale),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _items[index].icon,
                            size: (21 * scale).clamp(19.0, 23.0),
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            _items[index].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: (10.5 * scale).clamp(10.0, 12.0),
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
