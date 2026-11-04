import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class WeightProgressChart extends StatelessWidget {
  const WeightProgressChart({
    super.key,
    required this.currentWeight,
    required this.goalWeight,
    required this.startingWeight,
    required this.spots,
    this.labels = const [],
  });

  final double currentWeight;
  final double goalWeight;
  final double startingWeight;

  final List<FlSpot> spots;
  final List<String> labels;
  @override
  Widget build(BuildContext context) {
    // Same calculation used by WeightProgressCard.
    // Both now use the starting weight returned by Progress API.

    final double change = currentWeight - startingWeight;

    final String changeTitle = change < -0.0001
        ? 'Lost'
        : change > 0.0001
        ? 'Gained'
        : 'No Change';

    double lowestValue = min(currentWeight, goalWeight);
    double highestValue = max(currentWeight, goalWeight);
    for (final spot in spots) {
      if (spot.y < lowestValue) lowestValue = spot.y;
      if (spot.y > highestValue) highestValue = spot.y;
    }
    final double safeMinY = lowestValue - 3;
    final double safeMaxY = highestValue + 3;

    // Use the actual x range so a chart with fewer or more than seven
    // records does not draw outside its bounds.
    final double minX = spots.isEmpty
        ? 0
        : min(0.0, spots.map((s) => s.x).reduce(min));
    final double maxX = spots.isEmpty
        ? 6
        : max(6.0, spots.map((s) => s.x).reduce(max));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
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
                  color: AppColors.primary.withOpacity(.15),
                  shape: BoxShape.circle,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Last 7 Days',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
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
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                clipData: const FlClipData.all(),
                minX: minX,
                maxX: maxX,
                minY: safeMinY,
                maxY: safeMaxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.primary.withOpacity(.10),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final int index = value.round();
                        if ((value - index).abs() > 0.001 || index < 0) {
                          return const SizedBox.shrink();
                        }
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final String label =
                            index < labels.length && labels[index].isNotEmpty
                            ? labels[index]
                            : days[index % 7];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 5,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: AppColors.background,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(.35),
                          AppColors.primary.withOpacity(.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  title: 'Current',
                  value: '${currentWeight.toStringAsFixed(1)} kg',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  title: 'Goal',
                  value: '${goalWeight.toStringAsFixed(1)} kg',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  title: changeTitle,
                  value: '${change.abs().toStringAsFixed(1)} kg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(.10)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
