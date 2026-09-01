import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'section_header.dart';
import 'weekly_bar.dart';

class WeeklyProgressCard extends StatelessWidget {
  const WeeklyProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(
          title: "Weekly Progress",
          subtitle: "Last 7 days activity",
        ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(.15)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              //--------------------------------------------------
              // TOP STATS
              //--------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      title: "Calories",
                      value: "12.4k",
                      color: Colors.orange,
                      icon: Icons.local_fire_department,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _Stat(
                      title: "Steps",
                      value: "58k",
                      color: Colors.green,
                      icon: Icons.directions_walk,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _Stat(
                      title: "Water",
                      value: "16L",
                      color: Colors.blue,
                      icon: Icons.water_drop,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              //--------------------------------------------------
              // CHART
              //--------------------------------------------------
              SizedBox(
                height: 130,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    WeeklyBar(day: "M", value: .65, color: Colors.orange),

                    WeeklyBar(day: "T", value: .82, color: Colors.orange),

                    WeeklyBar(day: "W", value: .58, color: Colors.orange),

                    WeeklyBar(
                      day: "T",
                      value: .90,
                      color: Colors.orange,
                      selected: true,
                    ),

                    WeeklyBar(day: "F", value: .78, color: Colors.orange),

                    WeeklyBar(day: "S", value: .96, color: Colors.orange),

                    WeeklyBar(day: "S", value: .72, color: Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(.15),
          child: Icon(icon, color: color, size: 18),
        ),

        const SizedBox(height: 10),

        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          title,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
