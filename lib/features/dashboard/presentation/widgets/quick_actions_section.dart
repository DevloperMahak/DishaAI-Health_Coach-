import 'package:disha_ai/app/routes/app_routes.dart';
import 'package:disha_ai/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:disha_ai/features/dashboard/data/models/quick_action_category_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import 'quick_action_item.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  // 💡 Helper mapper to bind API slugs to local assets, colors, and routes
  Map<String, dynamic> _getMetadataForSlug(String slug) {
    switch (slug.toLowerCase()) {
      case 'meditation':
        return {
          'image': 'assets/images/meditation.png',
          'color': Colors.teal,
          'route': AppRoutes.meditation,
        };
      case 'workout':
        return {
          'image': 'assets/images/workout.png',
          'color': Colors.green,
          'route': AppRoutes.workout,
        };
      case 'water':
        return {
          'image': 'assets/images/water.png',
          'color': Colors.blue,
          'route': AppRoutes.waterTracker,
        };
      case 'meals':
        return {
          'image': 'assets/images/meals.png',
          'color': Colors.orange,
          'route': AppRoutes.meal,
        };
      case 'sleep':
        return {
          'image': 'assets/images/sleep.png',
          'color': Colors.deepPurple,
          'route': AppRoutes.sleep,
        };
      case 'progress':
        return {
          'image': 'assets/images/progress.png',
          'color': Colors.amber,
          'route': AppRoutes.progress,
        };
      case 'weight':
        return {
          'image': 'assets/images/weight.png',
          'color': Colors.redAccent,
          'route': AppRoutes.weight,
        };
      case 'vitals':
        return {
          'image': 'assets/images/vitals.png',
          'color': Colors.pink,
          'route': AppRoutes.vitalsAnalysis,
        };
      case 'mood':
        return {
          'image': 'assets/images/mood.png',
          'color': Colors.amber,
          'route': AppRoutes.mood,
        };
      case 'steps':
        return {
          'image': 'assets/images/steps.png',
          'color': Colors.indigo,
          'route': AppRoutes.steps,
        };
      case 'sexual-wellness':
        return {
          'image': 'assets/images/sexual_wellness.png',
          'color': Colors.pinkAccent,
          'route': AppRoutes.sexualWellness,
        };
      case 'addictions':
        return {
          'image': 'assets/images/addictions.png',
          'color': Colors.deepOrange,
          'route': AppRoutes.addiction,
        };
      case 'medical-record':
        return {
          'image': 'assets/images/medicine.png',
          'color': Colors.cyan,
          'route': AppRoutes.explainReport,
        };
      case 'ai-coach':
        return {
          'image': 'assets/images/ai_coach.png',
          'color': AppColors.primary,
          'route': AppRoutes.aiCoach,
        };
      default:
        return {
          'image': 'assets/images/Profile.png',
          'color': AppColors.primary,
          'route': AppRoutes.dashboard,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();
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
        ? 0.82
        : 0.88;

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
        Obx(() {
          if (controller.isLoadingQuickActions.value &&
              controller.quickActions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final categories = controller.quickActions;

          if (categories.isEmpty) {
            return const SizedBox.shrink();
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final meta = _getMetadataForSlug(cat.slug);

              return QuickActionItem(
                title: cat.title,
                imagePath: meta['image'] as String,
                color: meta['color'] as Color,
                onTap: () {
                  final route = meta['route'] as String;
                  Get.toNamed(route);
                },
              );
            },
          );
        }),
      ],
    );
  }
}
