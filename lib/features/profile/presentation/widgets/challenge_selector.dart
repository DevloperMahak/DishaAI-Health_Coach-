import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class ChallengeSelector extends StatelessWidget {
  const ChallengeSelector({
    super.key,
    required this.selectedChallenges,
    required this.onChanged,
  });

  final List<String> selectedChallenges;
  final ValueChanged<List<String>> onChanged;

  static const List<_ChallengeItem> _items = [
    _ChallengeItem(
      title: "Lack of Motivation",
      subtitle: "Need help staying consistent",
      icon: Icons.emoji_events_rounded,
      color: Colors.orange,
    ),
    _ChallengeItem(
      title: "Busy Schedule",
      subtitle: "Very little free time",
      icon: Icons.schedule_rounded,
      color: Colors.blue,
    ),
    _ChallengeItem(
      title: "Poor Sleep",
      subtitle: "Improve sleep quality",
      icon: Icons.bedtime_rounded,
      color: Colors.deepPurple,
    ),
    _ChallengeItem(
      title: "Stress",
      subtitle: "Reduce daily stress",
      icon: Icons.self_improvement_rounded,
      color: Colors.green,
    ),
    _ChallengeItem(
      title: "Low Energy",
      subtitle: "Feel energetic throughout day",
      icon: Icons.bolt_rounded,
      color: Colors.amber,
    ),
    _ChallengeItem(
      title: "Healthy Eating",
      subtitle: "Improve eating habits",
      icon: Icons.restaurant_menu_rounded,
      color: Colors.redAccent,
    ),
    _ChallengeItem(
      title: "Weight Management",
      subtitle: "Maintain healthy weight",
      icon: Icons.monitor_weight_rounded,
      color: Colors.teal,
    ),
    _ChallengeItem(
      title: "Workout Consistency",
      subtitle: "Exercise regularly",
      icon: Icons.fitness_center_rounded,
      color: Colors.indigo,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 1100
            ? 3
            : width >= 700
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: width < 700 ? 3.3 : 2.9,
          ),
          itemBuilder: (context, index) {
            final item = _items[index];

            final selected = selectedChallenges.contains(item.title);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,

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
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),

              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  final updated = List<String>.from(selectedChallenges);

                  if (selected) {
                    updated.remove(item.title);
                  } else {
                    updated.add(item.title);
                  }

                  onChanged(updated);
                },

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Row(
                    children: [
                      //------------------------------------------------
                      // Icon
                      //------------------------------------------------
                      Container(
                        width: 54,
                        height: 54,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.color.withOpacity(.15),
                        ),

                        child: Icon(item.icon, color: item.color, size: 28),
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      //------------------------------------------------
                      // Checkbox
                      //------------------------------------------------
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),

                        width: 26,
                        height: 26,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,

                          color: selected
                              ? AppColors.primary
                              : Colors.transparent,

                          border: Border.all(
                            color: selected ? AppColors.primary : Colors.grey,
                            width: 2,
                          ),
                        ),

                        child: selected
                            ? const Icon(
                                Icons.check,
                                size: 16,
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

class _ChallengeItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ChallengeItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
