import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class MealPlanCard extends StatelessWidget {
  const MealPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bool tablet = width > 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: tablet ? width * .05 : 0),

      padding: EdgeInsets.all(tablet ? 22 : 16),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(tablet ? 18 : 14),

        border: Border.all(color: AppColors.primaryDark.withOpacity(.6)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            "AI Meal Plan",

            style: TextStyle(
              color: AppColors.textPrimary,

              fontSize: tablet ? 22 : 18,

              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          mealItem(
            Icons.wb_sunny_outlined,
            "Breakfast",
            "Oats + Fruits + Protein",
            tablet,
          ),

          mealItem(
            Icons.lunch_dining_outlined,
            "Lunch",
            "Balanced Indian Meal",
            tablet,
          ),

          mealItem(
            Icons.nightlight_outlined,
            "Dinner",
            "Light & Healthy Food",
            tablet,
          ),
        ],
      ),
    );
  }

  Widget mealItem(IconData icon, String title, String value, bool tablet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        children: [
          Container(
            height: tablet ? 42 : 36,

            width: tablet ? 42 : 36,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: AppColors.primary.withOpacity(.15),
            ),

            child: Icon(icon, color: AppColors.primary, size: tablet ? 24 : 20),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: TextStyle(
                    color: AppColors.textPrimary,

                    fontSize: tablet ? 16 : 14,

                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,

                  style: TextStyle(
                    color: AppColors.textSecondary,

                    fontSize: tablet ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
