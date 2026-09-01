import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class ActivityStatisticsCard extends StatelessWidget {
  const ActivityStatisticsCard({
    super.key,
    required this.steps,
    required this.calories,
    required this.water,
    required this.sleepHours,
    required this.workouts,
  });

  final int steps;
  final int calories;
  final double water;
  final double sleepHours;
  final int workouts;

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
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //----------------------------------------------------------
          // HEADER
          //----------------------------------------------------------
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  "Today's Statistics",
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

          //----------------------------------------------------------
          // GRID
          //----------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.directions_walk,
                  color: Colors.blue,
                  title: "Steps",
                  value: "$steps",
                ),
              ),

              SizedBox(width: 14 * scale),

              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                  title: "Calories",
                  value: "$calories kcal",
                ),
              ),
            ],
          ),

          SizedBox(height: 14 * scale),

          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.water_drop,
                  color: Colors.cyan,
                  title: "Water",
                  value: "${water.toStringAsFixed(1)} L",
                ),
              ),

              SizedBox(width: 14 * scale),

              Expanded(
                child: _StatTile(
                  icon: Icons.bedtime,
                  color: Colors.deepPurple,
                  title: "Sleep",
                  value: "${sleepHours.toStringAsFixed(1)} hrs",
                ),
              ),
            ],
          ),

          SizedBox(height: 14 * scale),

          _WorkoutCard(workouts: workouts),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.workouts});

  final int workouts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(.15),
            ),
            child: const Icon(Icons.fitness_center, color: Colors.green),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Workouts Completed",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "$workouts Sessions",
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.check_circle, color: Colors.green, size: 28),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(.15),
            ),
            child: Icon(icon, color: color),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}
