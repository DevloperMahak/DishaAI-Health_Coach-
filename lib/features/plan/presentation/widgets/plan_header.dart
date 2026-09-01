import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class PlanHeader extends StatelessWidget {
  const PlanHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bool tablet = width > 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tablet ? width * .05 : 16,
        vertical: 18,
      ),

      child: Row(
        children: [
          // Back Button (same as Profile Screen)
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },

            icon: Icon(
              Icons.arrow_back_ios_new,

              color: AppColors.primary,

              size: tablet ? 28 : 22,
            ),
          ),

          const Spacer(),

          // Center Title
          Column(
            children: [
              Text(
                "Today's Plan",

                style: TextStyle(
                  color: AppColors.textPrimary,

                  fontSize: tablet ? 24 : 20,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                "Personalized by Rhea AI",

                style: TextStyle(
                  color: AppColors.textSecondary,

                  fontSize: tablet ? 14 : 12,
                ),
              ),
            ],
          ),

          const Spacer(),

          // AI Icon (right side like profile settings icon)
          Container(
            height: tablet ? 42 : 36,

            width: tablet ? 42 : 36,

            decoration: BoxDecoration(
              shape: BoxShape.circle,

              gradient: LinearGradient(
                colors: [Colors.amber, Colors.orange.shade700],
              ),
            ),

            child: Icon(
              Icons.auto_awesome,

              color: Colors.black,

              size: tablet ? 24 : 20,
            ),
          ),
        ],
      ),
    );
  }
}
