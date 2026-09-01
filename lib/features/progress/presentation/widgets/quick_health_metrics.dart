import 'package:flutter/material.dart';
import 'quick_metric_card.dart';

class QuickHealthMetrics extends StatelessWidget {
  const QuickHealthMetrics({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: QuickMetricCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.orange,
            value: "1,650",
            unit: "/2000",
            title: "kcal",
          ),
        ),

        SizedBox(width: 8),

        Expanded(
          child: QuickMetricCard(
            icon: Icons.directions_run_rounded,
            iconColor: Colors.green,
            value: "1,650",
            unit: "",
            title: "steps",
          ),
        ),

        SizedBox(width: 8),

        Expanded(
          child: QuickMetricCard(
            icon: Icons.nightlight_round,
            iconColor: Colors.deepPurpleAccent,
            value: "7.1",
            unit: "",
            title: "hours",
          ),
        ),

        SizedBox(width: 8),

        Expanded(
          child: QuickMetricCard(
            icon: Icons.water_drop_rounded,
            iconColor: Colors.lightBlue,
            value: "20/32",
            unit: "",
            title: "Glasses",
          ),
        ),
      ],
    );
  }
}
