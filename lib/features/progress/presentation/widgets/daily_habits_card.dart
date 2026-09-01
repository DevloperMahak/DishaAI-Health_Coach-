import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class DailyHabitsCard extends StatelessWidget {
  const DailyHabitsCard({super.key});

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.12);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    return Container(
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //--------------------------------------------------
          // TITLE
          //--------------------------------------------------
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.primary,
              ),

              SizedBox(width: 8 * scale),

              Text(
                "Today's Habits",
                style: TextStyle(
                  fontSize: (18 * scale).clamp(16.0, 20.0),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 22 * scale),

          const _HabitTile(
            icon: Icons.water_drop_rounded,
            title: "Water Intake",
            subtitle: "7 / 8 Glasses",
            progress: 0.88,
            color: Colors.blue,
          ),

          const SizedBox(height: 18),

          const _HabitTile(
            icon: Icons.restaurant_menu_rounded,
            title: "Healthy Meals",
            subtitle: "3 / 4 Meals",
            progress: 0.75,
            color: Colors.orange,
          ),

          const SizedBox(height: 18),

          const _HabitTile(
            icon: Icons.fitness_center_rounded,
            title: "Workout",
            subtitle: "45 / 60 min",
            progress: 0.75,
            color: Colors.green,
          ),

          const SizedBox(height: 18),

          const _HabitTile(
            icon: Icons.bedtime_rounded,
            title: "Sleep Goal",
            subtitle: "6.5 / 8 hrs",
            progress: 0.81,
            color: Colors.deepPurple,
          ),
        ],
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              "${(progress * 100).round()}%",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(.06),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
