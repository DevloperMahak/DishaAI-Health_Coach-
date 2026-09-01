import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class HydrationStatistics extends StatelessWidget {
  const HydrationStatistics({
    super.key,
    required this.averageWater,
    required this.bestWater,
    required this.streak,
    required this.score,
  });

  final int averageWater;
  final int bestWater;
  final int streak;
  final int score;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.15);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    final bool isTablet = width >= 700;

    final double spacing = width < 360 ? 10 : 16;

    final double cardWidth = isTablet
        ? (width - 170) / 4
        : (width - (spacing * 3)) / 2;

    return Container(
      padding: EdgeInsets.all(22 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withOpacity(.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(color: AppColors.primary.withOpacity(.06), blurRadius: 18),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //--------------------------------------------------
          // HEADER
          //--------------------------------------------------
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(.12),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),

              SizedBox(width: 16 * scale),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hydration Statistics",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: (20 * scale).clamp(18.0, 24.0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 4 * scale),

                    Text(
                      "Your hydration performance",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: (13 * scale).clamp(12.0, 15.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 24 * scale),

          //--------------------------------------------------
          // RESPONSIVE CARDS
          //--------------------------------------------------
          SizedBox(
            height: isTablet ? 210 : 400,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,

              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: width >= 900 ? 4 : 2,

                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,

                // Change card height here
                mainAxisExtent: width >= 700 ? 210 : 185,
              ),

              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _StatisticCard(
                      icon: Icons.water_drop_rounded,
                      title: "Average",
                      value: "${(averageWater / 1000).toStringAsFixed(1)} L",
                      subtitle: "Per Day",
                    );

                  case 1:
                    return _StatisticCard(
                      icon: Icons.emoji_events_rounded,
                      title: "Best",
                      value: "${(bestWater / 1000).toStringAsFixed(1)} L",
                      subtitle: "Highest Intake",
                    );

                  case 2:
                    return _StatisticCard(
                      icon: Icons.local_fire_department_rounded,
                      title: "Streak",
                      value: "$streak",
                      subtitle: "Days",
                    );

                  default:
                    return _StatisticCard(
                      icon: Icons.star_rounded,
                      title: "Hydration",
                      value: "$score%",
                      subtitle: "Health Score",
                    );
                }
              },
            ),
          ),
          SizedBox(height: 24 * scale),

          //--------------------------------------------------
          // AI INSIGHT
          //--------------------------------------------------
          Container(
            padding: EdgeInsets.all(18 * scale),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primary.withOpacity(.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(.15),
                  ),
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    color: AppColors.primary,
                  ),
                ),

                SizedBox(width: 14 * scale),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "AI Insight",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        score >= 90
                            ? "Excellent hydration! Keep maintaining your routine."
                            : score >= 70
                            ? "You're doing well. One more glass of water today will help you reach your goal."
                            : "Your hydration is below the recommended level. Drink water regularly throughout the day.",
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
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
//--------------------------------------------------------------
// STATISTIC CARD
//--------------------------------------------------------------

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final bool isTablet = width >= 700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18 : 14,
        vertical: isTablet ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withOpacity(.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isTablet ? 58 : 52,
            height: isTablet ? 58 : 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(.12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: isTablet ? 30 : 26,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isTablet ? 22 : 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isTablet ? 15 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isTablet ? 12 : 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
