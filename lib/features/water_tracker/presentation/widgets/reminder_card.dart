import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.enabled,
    required this.interval,
    required this.onToggle,
    required this.onIntervalChanged,
  });

  final bool enabled;
  final int interval;

  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onIntervalChanged;

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
          //------------------------------------------------
          // HEADER
          //------------------------------------------------
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
                  Icons.notifications_active_rounded,
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
                      "Hydration Reminder",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: (20 * scale).clamp(18, 24),
                      ),
                    ),

                    SizedBox(height: 4 * scale),

                    Text(
                      "Never forget to drink water",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: (13 * scale).clamp(12, 15),
                      ),
                    ),
                  ],
                ),
              ),

              Switch(
                value: enabled,
                activeColor: AppColors.primary,
                onChanged: onToggle,
              ),
            ],
          ),

          SizedBox(height: 24 * scale),

          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: enabled ? 1 : .45,
            child: IgnorePointer(
              ignoring: !enabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reminder Interval",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: (15 * scale).clamp(14, 17),
                    ),
                  ),

                  SizedBox(height: 16 * scale),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _IntervalChip(
                        label: "30 min",
                        value: 30,
                        selected: interval == 30,
                        onTap: () => onIntervalChanged(30),
                      ),
                      _IntervalChip(
                        label: "1 Hour",
                        value: 60,
                        selected: interval == 60,
                        onTap: () => onIntervalChanged(60),
                      ),
                      _IntervalChip(
                        label: "2 Hours",
                        value: 120,
                        selected: interval == 120,
                        onTap: () => onIntervalChanged(120),
                      ),
                      _IntervalChip(
                        label: "3 Hours",
                        value: 180,
                        selected: interval == 180,
                        onTap: () => onIntervalChanged(180),
                      ),
                    ],
                  ),

                  SizedBox(height: 24 * scale),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            "You'll receive a gentle reminder every $interval minutes until you reach today's hydration goal.",
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
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

class _IntervalChip extends StatelessWidget {
  const _IntervalChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primary.withOpacity(.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
