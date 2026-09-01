import 'package:disha_ai/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import 'quick_action_item.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final crossAxisCount = width >= 900
        ? 6
        : width >= 700
        ? 5
        : width < 360
        ? 2
        : 4;

    final childAspectRatio = width <= 360
        ? 0.72
        : width <= 390
        ? 0.78
        : width <= 430
        ? 0.84
        : 0.92;

    final actions = <Widget>[
      // Meditation
      QuickActionItem(
        title: "Meditation",
        icon: Icons.self_improvement_rounded,
        color: Colors.teal,
        onTap: () {
          Get.toNamed(AppRoutes.meditation);
        },
      ),

      // Workout
      QuickActionItem(
        title: "Workout",
        icon: Icons.fitness_center_rounded,
        color: Colors.green,
        onTap: () {
          Get.toNamed(AppRoutes.workout);
        },
      ),

      // Water
      QuickActionItem(
        title: "Water",
        icon: Icons.water_drop_rounded,
        color: Colors.blue,
        onTap: () {
          Get.toNamed(AppRoutes.waterTracker);
        },
      ),

      // Meals
      QuickActionItem(
        title: "Meals",
        icon: Icons.restaurant_menu_rounded,
        color: Colors.orange,
        onTap: () {
          Get.toNamed(AppRoutes.meal);
        },
      ),

      // Sleep
      QuickActionItem(
        title: "Sleep",
        icon: Icons.bedtime_rounded,
        color: Colors.deepPurple,
        onTap: () {
          Get.toNamed(AppRoutes.sleep);
        },
      ),

      // Progress
      QuickActionItem(
        title: "Progress",
        icon: Icons.show_chart_rounded,
        color: Colors.amber,
        onTap: () {
          Get.toNamed(AppRoutes.progress);
        },
      ),

      // Weight
      QuickActionItem(
        title: "Weight",
        icon: Icons.monitor_weight_rounded,
        color: Colors.redAccent,
        onTap: () {
          Get.toNamed(AppRoutes.weight);
        },
      ),

      // Vitals
      QuickActionItem(
        title: "Vitals",
        icon: Icons.favorite_rounded,
        color: Colors.pink,
        onTap: () {
          Get.toNamed(AppRoutes.vitalsAnalysis);
        },
      ),

      // Mood
      QuickActionItem(
        title: "Mood",
        icon: Icons.mood_rounded,
        color: Colors.amber,
        onTap: () {
          Get.toNamed(AppRoutes.mood);
        },
      ),

      // Steps
      QuickActionItem(
        title: "Steps",
        icon: Icons.directions_walk_rounded,
        color: Colors.indigo,
        onTap: () {
          Get.toNamed(AppRoutes.steps);
        },
      ),

      // Sexual Wellness
      QuickActionItem(
        title: "Sexual Wellness",
        icon: Icons.favorite_border_rounded,
        color: Colors.pinkAccent,
        onTap: () {
          Get.toNamed(AppRoutes.sexualWellness);
        },
      ),

      // Addictions
      QuickActionItem(
        title: "Addictions",
        icon: Icons.block_rounded,
        color: Colors.deepOrange,
        onTap: () {
          Get.toNamed(AppRoutes.addiction);
        },
      ),

      // Medicine
      QuickActionItem(
        title: "Medicine",
        icon: Icons.medication_rounded,
        color: Colors.cyan,
        onTap: () {
          Get.toNamed(AppRoutes.explainReport);
        },
      ),

      // AI Coach
      QuickActionItem(
        title: "AI Coach",
        icon: Icons.auto_awesome_rounded,
        color: AppColors.primary,
        onTap: () {
          Get.toNamed(AppRoutes.aiCoach);
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) => actions[index],
        ),
      ],
    );
  }
}
