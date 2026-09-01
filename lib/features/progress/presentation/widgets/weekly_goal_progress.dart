import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class WeeklyGoalProgress extends StatelessWidget {
  const WeeklyGoalProgress({super.key, required this.goals});

  final List<WeeklyGoalModel> goals;

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
        border: Border.all(color: AppColors.primary.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //------------------------------------------------------
          // Header
          //------------------------------------------------------
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded, color: AppColors.primary),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  "Weekly Goals",
                  style: TextStyle(
                    fontSize: (18 * scale).clamp(16.0, 20.0),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 22 * scale),

          ...goals.map(
            (goal) => Padding(
              padding: EdgeInsets.only(bottom: 16 * scale),
              child: _GoalTile(goal: goal),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});

  final WeeklyGoalModel goal;

  @override
  Widget build(BuildContext context) {
    final percent = (goal.current / goal.target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //----------------------------------------------------
          // Row
          //----------------------------------------------------
          Row(
            children: [
              Icon(goal.icon, color: AppColors.primary, size: 22),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),

              Text(
                "${goal.current}/${goal.target}",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 9,
              backgroundColor: AppColors.primary.withOpacity(.08),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${(percent * 100).toInt()}% Completed",
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyGoalModel {
  final String title;
  final IconData icon;
  final int current;
  final int target;

  const WeeklyGoalModel({
    required this.title,
    required this.icon,
    required this.current,
    required this.target,
  });
}
