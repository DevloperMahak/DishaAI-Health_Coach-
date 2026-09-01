import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class AchievementBadges extends StatelessWidget {
  const AchievementBadges({super.key, required this.badges});

  final List<AchievementBadgeModel> badges;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.12);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Text(
              "Achievements",
              style: TextStyle(
                fontSize: (18 * scale).clamp(16.0, 20.0),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),

        SizedBox(height: 18 * scale),

        SizedBox(
          height: 155 * scale,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: badges.length,
            separatorBuilder: (_, __) => SizedBox(width: 14 * scale),
            itemBuilder: (context, index) {
              return _BadgeCard(badge: badges[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final AchievementBadgeModel badge;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 125,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: badge.unlocked
              ? AppColors.primary
              : Colors.grey.withOpacity(.20),
        ),
        boxShadow: badge.unlocked
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(.15),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //--------------------------------------------------------
          // Badge Icon
          //--------------------------------------------------------
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: badge.unlocked
                  ? const LinearGradient(
                      colors: [Color(0xFFFFF2A6), AppColors.primary],
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade700, Colors.grey.shade600],
                    ),
            ),
            child: Icon(badge.icon, size: 30, color: Colors.black),
          ),

          const SizedBox(height: 14),

          Text(
            badge.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            badge.unlocked ? "Unlocked" : "Locked",
            style: TextStyle(
              color: badge.unlocked ? Colors.green : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AchievementBadgeModel {
  final String title;
  final IconData icon;
  final bool unlocked;

  const AchievementBadgeModel({
    required this.title,
    required this.icon,
    required this.unlocked,
  });
}
