import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/water_log_model.dart';

class TodaysWaterTimeline extends StatelessWidget {
  const TodaysWaterTimeline({super.key, required this.logs});

  final List<WaterLogModel> logs;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.15);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

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
                  Icons.history_rounded,
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
                      "Today's Timeline",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: (20 * scale).clamp(18.0, 24.0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 4 * scale),

                    Text(
                      "${logs.length} water logs today",
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

          SizedBox(height: 24 * scale),

          //--------------------------------------------------
          // EMPTY STATE
          //--------------------------------------------------
          if (logs.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: 40 * scale,
                horizontal: 20 * scale,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.primary.withOpacity(.10)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 54,
                    color: AppColors.primary.withOpacity(.7),
                  ),

                  SizedBox(height: 16 * scale),

                  Text(
                    "No water logged yet",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: (18 * scale).clamp(16.0, 20.0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 8 * scale),

                  Text(
                    "Start your hydration journey by adding your first glass of water.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontSize: (13 * scale).clamp(12.0, 15.0),
                    ),
                  ),
                ],
              ),
            ),

          //--------------------------------------------------
          // TIMELINE
          //--------------------------------------------------
          if (logs.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, __) => SizedBox(height: 18 * scale),
              itemBuilder: (context, index) {
                final log = logs[index];

                return _TimelineTile(
                  log: log,
                  isLast: index == logs.length - 1,
                );
              },
            ),
        ],
      ),
    );
  }
}
//--------------------------------------------------------------
// TIMELINE TILE
//--------------------------------------------------------------

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.log, required this.isLast});

  final WaterLogModel log;
  final bool isLast;

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour == 0
        ? 12
        : dateTime.hour;

    final minute = dateTime.minute.toString().padLeft(2, '0');

    final period = dateTime.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(.45),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.black,
                  size: 11,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(.10),
                    ),
                    child: const Icon(
                      Icons.local_drink_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${log.amount} ml",
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(log.loggedAt),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      "Logged",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
