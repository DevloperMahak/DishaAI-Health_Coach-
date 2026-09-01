import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class WeeklyWaterChart extends StatelessWidget {
  WeeklyWaterChart({super.key});

  final List<_WeekWaterData> weeklyData = const [
    _WeekWaterData(day: "Mon", amount: 2200),
    _WeekWaterData(day: "Tue", amount: 1800),
    _WeekWaterData(day: "Wed", amount: 2600),
    _WeekWaterData(day: "Thu", amount: 2100),
    _WeekWaterData(day: "Fri", amount: 2400),
    _WeekWaterData(day: "Sat", amount: 2900),
    _WeekWaterData(day: "Sun", amount: 1700),
  ];

  static const int dailyGoal = 2500;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.15);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    final average =
        weeklyData.fold<int>(0, (sum, e) => sum + e.amount) ~/
        weeklyData.length;

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
                  Icons.bar_chart_rounded,
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
                      "Weekly Hydration",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: (20 * scale).clamp(18.0, 24.0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 4 * scale),

                    Text(
                      "Average: ${average ~/ 1000}.${(average % 1000) ~/ 100} L/day",
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

          SizedBox(height: 30 * scale),

          //--------------------------------------------------
          // CHART
          //--------------------------------------------------
          SizedBox(
            height: 240 * scale,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyData.map((data) {
                final progress = (data.amount / dailyGoal).clamp(0.0, 1.2);

                final reachedGoal = data.amount >= dailyGoal;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4 * scale),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        //------------------------------------------------
                        // VALUE
                        //------------------------------------------------
                        Text(
                          "${(data.amount / 1000).toStringAsFixed(1)}L",
                          style: TextStyle(
                            color: reachedGoal
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: (11 * scale).clamp(10.0, 12.0),
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        SizedBox(height: 10 * scale),

                        //------------------------------------------------
                        // BAR
                        //------------------------------------------------
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              width: 24 * scale,
                              height: (170 * progress).clamp(12.0, 190.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: reachedGoal
                                      ? [
                                          AppColors.primary,
                                          AppColors.primary.withOpacity(.65),
                                        ]
                                      : [
                                          AppColors.primary.withOpacity(.35),
                                          AppColors.primary.withOpacity(.15),
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(.25),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 12 * scale),

                        //------------------------------------------------
                        // DAY
                        //------------------------------------------------
                        Text(
                          data.day,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: (12 * scale).clamp(11.0, 13.0),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: 24 * scale),

          //--------------------------------------------------
          // SUMMARY
          //--------------------------------------------------
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: "Goal",
                  value: "${dailyGoal ~/ 1000}.${(dailyGoal % 1000) ~/ 100} L",
                  icon: Icons.flag_rounded,
                ),
              ),

              SizedBox(width: 14 * scale),

              Expanded(
                child: _SummaryCard(
                  title: "Average",
                  value: "${average ~/ 1000}.${(average % 1000) ~/ 100} L",
                  icon: Icons.show_chart_rounded,
                ),
              ),
            ],
          ),

          SizedBox(height: 14 * scale),

          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: "Best Day",
                  value:
                      "${(weeklyData.map((e) => e.amount).reduce((a, b) => a > b ? a : b) / 1000).toStringAsFixed(1)} L",
                  icon: Icons.emoji_events_rounded,
                ),
              ),

              SizedBox(width: 14 * scale),

              Expanded(
                child: _SummaryCard(
                  title: "Goal Met",
                  value:
                      "${weeklyData.where((e) => e.amount >= dailyGoal).length}/7",
                  icon: Icons.check_circle_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
//--------------------------------------------------------------
// SUMMARY CARD
//--------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(.12)),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(.10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),

          const SizedBox(height: 12),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
//--------------------------------------------------------------
// WEEK DATA MODEL
//--------------------------------------------------------------

class _WeekWaterData {
  final String day;
  final int amount;

  const _WeekWaterData({required this.day, required this.amount});
}
