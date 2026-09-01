import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class ProgressAppBar extends StatelessWidget {
  const ProgressAppBar({
    super.key,
    this.selectedPeriod = "This Week",
    this.onPeriodChanged,
  });

  final String selectedPeriod;
  final ValueChanged<String>? onPeriodChanged;

  static const List<String> _periods = [
    "Today",
    "This Week",
    "This Month",
    "This Year",
  ];

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.15);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //----------------------------------------------------------
        // Back Button
        //----------------------------------------------------------
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.back(),
          child: Container(
            width: 46 * scale,
            height: 46 * scale,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(.15)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),

        SizedBox(height: 22 * scale),

        //----------------------------------------------------------
        // Title + Dropdown
        //----------------------------------------------------------
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //------------------------------------------------------
            // Title
            //------------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Progress",
                    style: TextStyle(
                      fontSize: (28 * scale).clamp(24.0, 32.0),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),

                  SizedBox(height: 6 * scale),

                  Text(
                    "Health analytics & trends",
                    style: TextStyle(
                      fontSize: (13 * scale).clamp(12.0, 15.0),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            //------------------------------------------------------
            // Dropdown
            //------------------------------------------------------
            Container(
              height: 40 * scale,
              padding: EdgeInsets.symmetric(horizontal: 14 * scale),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.primary.withOpacity(.35)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedPeriod,
                  dropdownColor: AppColors.surface,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                  ),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  items: _periods.map((period) {
                    return DropdownMenuItem(value: period, child: Text(period));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onPeriodChanged?.call(value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
