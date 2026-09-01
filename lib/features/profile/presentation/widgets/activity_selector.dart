import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class ActivitySelector extends StatelessWidget {
  const ActivitySelector({
    super.key,
    required this.selectedActivity,
    required this.onChanged,
  });

  final String selectedActivity;
  final ValueChanged<String> onChanged;

  static const List<_ActivityItem> _activities = [
    _ActivityItem(
      title: "Sedentary",
      subtitle: "Little or no exercise",
      icon: Icons.weekend_rounded,
    ),
    _ActivityItem(
      title: "Lightly Active",
      subtitle: "1–3 workouts/week",
      icon: Icons.directions_walk_rounded,
    ),
    _ActivityItem(
      title: "Moderately Active",
      subtitle: "3–5 workouts/week",
      icon: Icons.directions_run_rounded,
    ),
    _ActivityItem(
      title: "Very Active",
      subtitle: "6–7 workouts/week",
      icon: Icons.fitness_center_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 900
            ? 2
            : width >= 600
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _activities.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: width < 600 ? 3.2 : 3.6,
          ),
          itemBuilder: (context, index) {
            final item = _activities[index];

            final selected = selectedActivity == item.title;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),

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
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),

              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onChanged(item.title),

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Row(
                    children: [
                      //------------------------------------------------
                      // Icon
                      //------------------------------------------------
                      Container(
                        width: 52,
                        height: 52,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,

                          color: selected
                              ? AppColors.primary.withOpacity(.18)
                              : AppColors.background,
                        ),

                        child: Icon(
                          item.icon,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(width: 16),

                      //------------------------------------------------
                      // Text
                      //------------------------------------------------
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              item.title,

                              style: TextStyle(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,

                                fontWeight: FontWeight.w700,

                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              item.subtitle,

                              style: const TextStyle(
                                color: AppColors.textSecondary,

                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      //------------------------------------------------
                      // Check
                      //------------------------------------------------
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),

                        width: 24,
                        height: 24,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,

                          border: Border.all(
                            color: selected ? AppColors.primary : Colors.grey,
                            width: 2,
                          ),

                          color: selected
                              ? AppColors.primary
                              : Colors.transparent,
                        ),

                        child: selected
                            ? const Icon(
                                Icons.check,
                                size: 15,
                                color: Colors.black,
                              )
                            : null,
                      ),
                    ],
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

class _ActivityItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
