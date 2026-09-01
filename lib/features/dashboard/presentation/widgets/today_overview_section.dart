import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/dashboard_controller.dart';
import 'metric_card.dart';
import 'section_header.dart';

class TodayOverviewSection extends StatelessWidget {
  const TodayOverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController dashboardController =
        Get.find<DashboardController>();

    return Obx(() {
      final summary = dashboardController.todaySummary.value;

      // Agar summary null hai, toh loading state ya 0 dikhao
      final String calories = summary?.calories ?? "0";
      final String water = summary?.water ?? "0";
      final String steps = summary?.steps ?? "0";
      final String sleep = summary?.sleep ?? "0";

      final double calorieProgress = _calculateProgress(calories, 2000);
      final double waterProgress = _calculateProgress(water, 3.0);
      final double stepProgress = _calculateProgress(steps, 10000);
      final double sleepProgress = _calculateProgress(sleep, 8.0);

      return Column(
        children: [
          const SectionHeader(
            title: "Today's Overview",
            subtitle: "Track your daily health progress",
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: .95,
            children: [
              MetricCard(
                title: "Calories",
                value: calories,
                unit: "kcal",
                icon: Icons.local_fire_department,
                color: Colors.orange,
                progress: calorieProgress,
              ),
              MetricCard(
                title: "Water",
                value: water,
                unit: "L",
                icon: Icons.water_drop,
                color: Colors.blue,
                progress: waterProgress,
              ),
              MetricCard(
                title: "Steps",
                value: steps,
                unit: "",
                icon: Icons.directions_walk,
                color: Colors.green,
                progress: stepProgress,
              ),
              MetricCard(
                title: "Sleep",
                value: sleep,
                unit: "hrs",
                icon: Icons.bedtime,
                color: Colors.deepPurple,
                progress: sleepProgress,
              ),
            ],
          ),
        ],
      );
    });
  }

  double _calculateProgress(String valStr, double target) {
    final double val =
        double.tryParse(valStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (target <= 0) return 0.0;
    return (val / target).clamp(0.0, 1.0);
  }
}
