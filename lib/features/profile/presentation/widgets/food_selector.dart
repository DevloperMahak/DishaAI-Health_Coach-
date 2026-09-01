import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class FoodSelector extends StatelessWidget {
  const FoodSelector({
    super.key,
    required this.selectedFood,
    required this.onChanged,
  });

  final String selectedFood;
  final ValueChanged<String> onChanged;

  static const List<_FoodItem> _foods = [
    _FoodItem(
      title: "Vegetarian",
      subtitle: "Plant-based meals with dairy",
      icon: Icons.eco_rounded,
      color: Colors.green,
    ),
    _FoodItem(
      title: "Vegan",
      subtitle: "100% plant-based diet",
      icon: Icons.spa_rounded,
      color: Colors.teal,
    ),
    _FoodItem(
      title: "Eggetarian",
      subtitle: "Vegetarian + Eggs",
      icon: Icons.egg_alt_rounded,
      color: Colors.orange,
    ),
    _FoodItem(
      title: "Non-Vegetarian",
      subtitle: "Includes meat & seafood",
      icon: Icons.lunch_dining_rounded,
      color: Colors.redAccent,
    ),
    _FoodItem(
      title: "Keto",
      subtitle: "Low-carb, high-fat",
      icon: Icons.local_fire_department_rounded,
      color: Colors.deepOrange,
    ),
    _FoodItem(
      title: "High Protein",
      subtitle: "Protein-rich meals",
      icon: Icons.fitness_center_rounded,
      color: Colors.blue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 1000
            ? 3
            : width >= 650
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _foods.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: width < 650 ? 3.2 : 2.8,
          ),
          itemBuilder: (context, index) {
            final item = _foods[index];
            final selected = item.title == selectedFood;

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

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 24,
                        height: 24,
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
                                color: Colors.black,
                                size: 15,
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

class _FoodItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _FoodItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
