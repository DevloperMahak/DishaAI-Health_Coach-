import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class GoalSelector extends StatelessWidget {
  const GoalSelector({
    super.key,
    required this.selectedGoal,
    required this.onChanged,
  });

  final String selectedGoal;
  final ValueChanged<String> onChanged;

  static const List<_GoalItem> _goals = [
    _GoalItem(title: "Lose Weight", icon: Icons.monitor_weight_outlined),
    _GoalItem(title: "Gain Weight", icon: Icons.fitness_center_outlined),
    _GoalItem(title: "Build Muscle", icon: Icons.sports_gymnastics_outlined),
    _GoalItem(title: "Stay Healthy", icon: Icons.favorite_border),
    _GoalItem(title: "Improve Sleep", icon: Icons.bedtime_outlined),
    _GoalItem(title: "Reduce Stress", icon: Icons.self_improvement_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 900
            ? 3
            : width >= 600
            ? 3
            : 2;

        final childAspectRatio = width < 360 ? 1.35 : 1.45;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _goals.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final goal = _goals[index];

            final selected = goal.title == selectedGoal;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onChanged(goal.title),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withOpacity(.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (selected)
                          BoxShadow(
                            color: AppColors.primary.withOpacity(.10),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            goal.icon,
                            size: 28,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            goal.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GoalItem {
  final String title;
  final IconData icon;

  const _GoalItem({required this.title, required this.icon});
}
