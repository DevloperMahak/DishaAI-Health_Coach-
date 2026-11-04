import 'package:flutter/material.dart';
import 'quick_metric_card.dart';

class QuickHealthMetrics extends StatelessWidget {
  final String calories;
  final String steps;
  final String sleep;
  final String water;

  const QuickHealthMetrics({
    super.key,
    required this.calories,
    required this.steps,
    required this.sleep,
    required this.water,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: QuickMetricCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.orange,
            value: calories,
            unit: "kcal", // Dynamic unit
            title: "Calories",
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: QuickMetricCard(
            icon: Icons.directions_run_rounded,
            iconColor: Colors.green,
            value: steps,
            unit: "",
            title: "Steps",
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: QuickMetricCard(
            icon: Icons.nightlight_round,
            iconColor: Colors.deepPurpleAccent,
            value: sleep,
            unit: "hrs",
            title: "Sleep",
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: QuickMetricCard(
            icon: Icons.water_drop_rounded,
            iconColor: Colors.lightBlue,
            value: water,
            unit: "L", // Matching Today Overview unit
            title: "Water",
          ),
        ),
      ],
    );
  }
}
