import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class HealthTimeline extends StatelessWidget {
  const HealthTimeline({super.key, required this.events});

  final List<HealthTimelineEvent> events;

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
        border: Border.all(color: AppColors.primary.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //--------------------------------------------------------
          // Header
          //--------------------------------------------------------
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
                  Icons.timeline_rounded,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Text(
                  "Health Timeline",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 24 * scale),

          ...List.generate(
            events.length,
            (index) => _TimelineTile(
              event: events[index],
              isLast: index == events.length - 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event, required this.isLast});

  final HealthTimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //--------------------------------------------------
          // Timeline
          //--------------------------------------------------
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: event.color,
                  ),
                ),

                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: event.color.withOpacity(.30),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          //--------------------------------------------------
          // Card
          //--------------------------------------------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: event.color.withOpacity(.20)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: event.color.withOpacity(.15),
                      ),
                      child: Icon(event.icon, color: event.color),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            event.description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.5,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            event.date,
                            style: TextStyle(
                              color: event.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HealthTimelineEvent {
  final String title;
  final String description;
  final String date;
  final IconData icon;
  final Color color;

  const HealthTimelineEvent({
    required this.title,
    required this.description,
    required this.date,
    required this.icon,
    required this.color,
  });
}
