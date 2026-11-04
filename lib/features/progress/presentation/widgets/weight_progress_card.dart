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

  @override
  Widget build(BuildContext context) {
    final double change = currentWeight - startingWeight;
    final bool lost = change < -0.0001;
    final bool gained = change > 0.0001;
    final String changeTitle = lost
        ? 'Lost'
        : gained
        ? 'Gained'
        : 'No Change';
    final IconData changeIcon = lost
        ? Icons.trending_down_rounded
        : gained
        ? Icons.trending_up_rounded
        : Icons.remove_rounded;

    final double totalJourney = (targetWeight - startingWeight).abs();
    final double movementTowardGoal = targetWeight < startingWeight
        ? startingWeight - currentWeight
        : targetWeight > startingWeight
        ? currentWeight - startingWeight
        : 0.0;
    final double completed = movementTowardGoal
        .clamp(0.0, totalJourney)
        .toDouble();
    final double progress = totalJourney == 0
        ? (currentWeight == targetWeight ? 1.0 : 0.0)
        : (completed / totalJourney).clamp(0.0, 1.0).toDouble();
    final double remaining = (currentWeight - targetWeight).abs();

    return Container(
      padding: const EdgeInsets.all(20),
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
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Track your journey',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${currentWeight.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Current Weight',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${startingWeight.toStringAsFixed(0)} kg',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                '${targetWeight.toStringAsFixed(0)} kg',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _WeightInfo(
                  title: changeTitle,
                  value: '${change.abs().toStringAsFixed(1)} kg',
                  icon: changeIcon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WeightInfo(
                  title: 'Remaining',
                  value: '${remaining.toStringAsFixed(1)} kg',
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
