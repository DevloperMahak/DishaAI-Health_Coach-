import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class AchievementSection extends StatelessWidget {
  const AchievementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int crossAxisCount;

        if (width >= 1000) {
          crossAxisCount = 4;
        } else if (width >= 650) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primary,
                ),

                const SizedBox(width: 8),

                Text(
                  "Achievements",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: width > 600 ? 20 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),

              itemCount: 4,

              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,

                crossAxisSpacing: 12,

                mainAxisSpacing: 12,

                childAspectRatio: width < 400 ? 0.95 : 1.15,
              ),

              itemBuilder: (context, index) {
                final achievements = [
                  {
                    "title": "7 Day\nStreak",
                    "icon": Icons.local_fire_department_rounded,
                    "color": Colors.orange,
                    "earned": true,
                  },

                  {
                    "title": "Healthy\nEating",
                    "icon": Icons.restaurant_rounded,
                    "color": Colors.green,
                    "earned": true,
                  },

                  {
                    "title": "Workout\nMaster",
                    "icon": Icons.fitness_center_rounded,
                    "color": Colors.blue,
                    "earned": false,
                  },

                  {
                    "title": "Sleep\nChampion",
                    "icon": Icons.bedtime_rounded,
                    "color": Colors.deepPurple,
                    "earned": false,
                  },
                ];

                final item = achievements[index];

                return _AchievementCard(
                  title: item["title"] as String,
                  icon: item["icon"] as IconData,
                  color: item["color"] as Color,
                  earned: item["earned"] as bool,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.earned,
  });

  final String title;
  final IconData icon;
  final Color color;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;

        final iconSize = size * .32;

        return Container(
          padding: EdgeInsets.all(size * .10),

          decoration: BoxDecoration(
            color: AppColors.surface,

            borderRadius: BorderRadius.circular(size * .18),

            border: Border.all(
              color: earned
                  ? color.withOpacity(.35)
                  : Colors.grey.withOpacity(.20),
            ),

            boxShadow: [
              BoxShadow(
                color: earned
                    ? color.withOpacity(.08)
                    : Colors.black.withOpacity(.05),

                blurRadius: 12,

                offset: const Offset(0, 6),
              ),
            ],
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            mainAxisSize: MainAxisSize.min,

            children: [
              Container(
                width: iconSize,

                height: iconSize,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  color: earned
                      ? color.withOpacity(.14)
                      : Colors.grey.withOpacity(.12),
                ),

                child: Icon(
                  icon,

                  size: iconSize * .55,

                  color: earned ? color : Colors.grey,
                ),
              ),

              SizedBox(height: size * .12),

              Flexible(
                child: Text(
                  title,

                  textAlign: TextAlign.center,

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: earned
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,

                    fontWeight: FontWeight.w600,

                    fontSize: size * .14,
                  ),
                ),
              ),

              SizedBox(height: size * .10),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size * .14,

                  vertical: size * .06,
                ),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),

                  color: earned
                      ? AppColors.primary.withOpacity(.15)
                      : Colors.grey.withOpacity(.12),
                ),

                child: Text(
                  earned ? "Unlocked" : "Locked",

                  style: TextStyle(
                    color: earned ? AppColors.primary : Colors.grey,

                    fontWeight: FontWeight.w600,

                    fontSize: size * .11,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
