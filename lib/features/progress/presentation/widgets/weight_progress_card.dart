import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class WeightProgressCard extends StatelessWidget {
  const WeightProgressCard({
    super.key,
    required this.currentWeight,
    required this.targetWeight,
    required this.startingWeight,
  });

  final double currentWeight;
  final double targetWeight;
  final double startingWeight;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.12);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = _scale(width);

    final totalJourney = (startingWeight - targetWeight).abs();
    final completed = (startingWeight - currentWeight).abs().clamp(
      0.0,
      totalJourney,
    );

    final progress = totalJourney == 0
        ? 1.0
        : (completed / totalJourney).clamp(0.0, 1.0);

    final remaining = (currentWeight - targetWeight).abs();

    return Container(
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //--------------------------------------------------
          // Header
          //--------------------------------------------------
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(.15),
                ),
                child: const Icon(
                  Icons.monitor_weight_rounded,
                  color: AppColors.primary,
                ),
              ),

              SizedBox(width: 14 * scale),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Weight Progress",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: (17 * scale).clamp(16.0, 20.0),
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      "Track your journey",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: (12 * scale).clamp(11.0, 14.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 24 * scale),

          //--------------------------------------------------
          // Current Weight
          //--------------------------------------------------
          Center(
            child: Column(
              children: [
                Text(
                  "${currentWeight.toStringAsFixed(1)} kg",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: (36 * scale).clamp(32.0, 42.0),
                  ),
                ),
                SizedBox(height: 6 * scale),
                Text(
                  "Current Weight",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: (13 * scale).clamp(12.0, 15.0),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24 * scale),

          //--------------------------------------------------
          // Progress Bar
          //--------------------------------------------------
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),

          SizedBox(height: 10 * scale),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${startingWeight.toStringAsFixed(0)} kg",
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                "${targetWeight.toStringAsFixed(0)} kg",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 24 * scale),

          //--------------------------------------------------
          // Stats
          //--------------------------------------------------
          Row(
            children: [
              Expanded(
                child: _WeightInfo(
                  title: "Lost",
                  value: "${completed.toStringAsFixed(1)} kg",
                  icon: Icons.trending_down_rounded,
                ),
              ),

              SizedBox(width: 12 * scale),

              Expanded(
                child: _WeightInfo(
                  title: "Remaining",
                  value: "${remaining.toStringAsFixed(1)} kg",
                  icon: Icons.flag_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightInfo extends StatelessWidget {
  const _WeightInfo({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(.10)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
