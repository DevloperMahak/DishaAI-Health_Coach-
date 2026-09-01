import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

enum ProgressPeriod { today, week, month, year }

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onChanged,
  });

  final ProgressPeriod selectedPeriod;
  final ValueChanged<ProgressPeriod> onChanged;

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.15);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);

    final periods = ProgressPeriod.values;

    return Container(
      padding: EdgeInsets.all(5 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(.15)),
      ),
      child: Row(
        children: periods.map((period) {
          final selected = period == selectedPeriod;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: EdgeInsets.symmetric(vertical: 12 * scale),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: selected
                      ? const LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
                        )
                      : null,
                  color: selected ? null : Colors.transparent,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontSize: (13 * scale).clamp(12.0, 15.0),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.black : AppColors.textSecondary,
                  ),
                  child: Text(_label(period), textAlign: TextAlign.center),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(ProgressPeriod period) {
    switch (period) {
      case ProgressPeriod.today:
        return "Today";

      case ProgressPeriod.week:
        return "Week";

      case ProgressPeriod.month:
        return "Month";

      case ProgressPeriod.year:
        return "Year";
    }
  }
}
