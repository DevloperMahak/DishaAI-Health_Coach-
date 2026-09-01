import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class ScheduleItem extends StatelessWidget {
  const ScheduleItem({
    super.key,
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
    this.completed = false,
    this.onTap,
  });

  final String title;
  final String time;
  final IconData icon;
  final Color color;
  final bool completed;
  final VoidCallback? onTap;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.12);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10 * scale),
        child: Row(
          children: [
            //-----------------------------------------
            // Timeline
            //-----------------------------------------
            SizedBox(
              width: 34,
              child: Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed ? Colors.green : color,
                    ),
                    child: completed
                        ? const Icon(Icons.check, size: 9, color: Colors.white)
                        : null,
                  ),

                  Container(
                    width: 2,
                    height: 54,
                    color: AppColors.primary.withOpacity(.15),
                  ),
                ],
              ),
            ),

            //-----------------------------------------
            // Card
            //-----------------------------------------
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16 * scale),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withOpacity(.18)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(.12),
                      ),
                      child: Icon(icon, color: color),
                    ),

                    SizedBox(width: 14 * scale),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: (14 * scale).clamp(13.0, 16.0),
                              color: AppColors.textPrimary,
                            ),
                          ),

                          SizedBox(height: 4 * scale),

                          Text(
                            time,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: (12 * scale).clamp(11.0, 13.0),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      completed ? Icons.check_circle : Icons.arrow_forward_ios,
                      size: 18,
                      color: completed ? Colors.green : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
