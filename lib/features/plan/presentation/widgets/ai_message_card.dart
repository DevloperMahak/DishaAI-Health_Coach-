import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class AiMessageCard extends StatelessWidget {
  const AiMessageCard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bool tablet = width > 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: tablet ? width * .05 : 0),

      padding: EdgeInsets.all(tablet ? 22 : 16),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(tablet ? 18 : 14),

        border: Border.all(color: AppColors.primaryDark.withOpacity(.6)),
      ),

      child: Row(
        children: [
          Container(
            height: tablet ? 55 : 45,

            width: tablet ? 55 : 45,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: AppColors.primary.withOpacity(.15),
            ),

            child: Icon(
              Icons.auto_awesome,

              color: AppColors.primary,

              size: tablet ? 30 : 24,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  "Rhea AI",

                  style: TextStyle(
                    color: AppColors.primary,

                    fontSize: tablet ? 16 : 14,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  "You are doing great! "
                  "Keep following your wellness plan.",

                  style: TextStyle(
                    color: AppColors.textPrimary,

                    fontSize: tablet ? 15 : width * .038,

                    height: 1.4,
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
