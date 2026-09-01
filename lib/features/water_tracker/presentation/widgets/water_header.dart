import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class WaterHeader extends StatelessWidget {
  const WaterHeader({
    super.key,
    required this.goal,
    required this.current,
    required this.onBack,
  });

  final int goal;
  final int current;
  final VoidCallback onBack;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.15);
  }

  String _formatMl(int ml) {
    if (ml >= 1000) {
      final litre = ml / 1000;
      return "${litre.toStringAsFixed(litre % 1 == 0 ? 0 : 1)} L";
    }

    return "$ml ml";
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    return Container(
      margin: EdgeInsets.fromLTRB(20 * scale, 16 * scale, 20 * scale, 0),
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withOpacity(.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(color: AppColors.primary.withOpacity(.08), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          //------------------------------------------------------
          // TOP ROW
          //------------------------------------------------------
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 46 * scale,
                  height: 46 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),

              SizedBox(width: 16 * scale),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Water Tracker",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: (24 * scale).clamp(20.0, 28.0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      "Stay hydrated throughout your day 💧",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: (13 * scale).clamp(12.0, 15.0),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 14 * scale,
                  vertical: 8 * scale,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.flag_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6 * scale),
                    Text(
                      _formatMl(goal),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 26 * scale),

          //------------------------------------------------------
          // CURRENT INTAKE CARD
          //------------------------------------------------------
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20 * scale),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: AppColors.background,
              border: Border.all(color: AppColors.primary.withOpacity(.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 62 * scale,
                  height: 62 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(.12),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),

                SizedBox(width: 18 * scale),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Intake",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: (13 * scale).clamp(12.0, 15.0),
                        ),
                      ),
                      SizedBox(height: 6 * scale),
                      Text(
                        _formatMl(current),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: (30 * scale).clamp(26.0, 34.0),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14 * scale,
                    vertical: 10 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    "Hydrate",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
