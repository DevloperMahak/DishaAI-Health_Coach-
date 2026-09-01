import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class ProgressInsightsCard extends StatelessWidget {
  const ProgressInsightsCard({
    super.key,
    this.title = "Rhea AI Insights",
    this.insight =
        "Excellent progress! Your consistency has improved by 18% this week. Keep maintaining your sleep schedule and hydration to reach your health goal even faster.",
    this.buttonText = "View Detailed Analysis",
    this.onPressed,
  });

  final String title;
  final String insight;
  final String buttonText;
  final VoidCallback? onPressed;

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
        border: Border.all(color: AppColors.primary.withOpacity(.20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.08),
            blurRadius: 20,
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
                width: 54 * scale,
                height: 54 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(.12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),

              SizedBox(width: 14 * scale),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: (18 * scale).clamp(16.0, 21.0),
                      ),
                    ),

                    SizedBox(height: 4 * scale),

                    Text(
                      "Powered by Rhea AI",
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

          SizedBox(height: 22 * scale),

          //----------------------------------------------------------
          // INSIGHT BOX
          //----------------------------------------------------------
          Container(
            padding: EdgeInsets.all(18 * scale),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withOpacity(.10)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),

                SizedBox(width: 12 * scale),

                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: (13 * scale).clamp(12.0, 15.0),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 22 * scale),

          //----------------------------------------------------------
          // AI METRICS
          //----------------------------------------------------------
          Row(
            children: const [
              Expanded(
                child: _MetricTile(value: "+18%", label: "Consistency"),
              ),

              SizedBox(width: 12),

              Expanded(
                child: _MetricTile(value: "92%", label: "Prediction"),
              ),

              SizedBox(width: 12),

              Expanded(
                child: _MetricTile(value: "7 Days", label: "Streak"),
              ),
            ],
          ),

          SizedBox(height: 24 * scale),

          //----------------------------------------------------------
          // BUTTON
          //----------------------------------------------------------
          SizedBox(
            width: double.infinity,
            height: (50 * scale).clamp(48.0, 56.0),
            child: ElevatedButton.icon(
              onPressed: onPressed ?? () {},
              icon: const Icon(Icons.analytics_outlined, color: Colors.black),
              label: Text(
                buttonText,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: (13 * scale).clamp(12.0, 15.0),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(.10)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
