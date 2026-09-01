import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class NumberPickerTile extends StatelessWidget {
  const NumberPickerTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.icon,
    required this.onIncrement,
    required this.onDecrement,
    this.minValue = 0,
    this.maxValue = 999,
  });

  final String title;
  final String subtitle;
  final int value;
  final String unit;
  final IconData icon;

  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  final int minValue;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final scale = (width / 390).clamp(.9, 1.15);

        return Container(
          padding: EdgeInsets.all(18 * scale),

          decoration: BoxDecoration(
            color: AppColors.surface,

            borderRadius: BorderRadius.circular(20),

            border: Border.all(color: AppColors.border),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),

          child: Row(
            children: [
              //------------------------------------------------
              // Icon
              //------------------------------------------------
              Container(
                width: 54 * scale,
                height: 54 * scale,

                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.12),
                  shape: BoxShape.circle,
                ),

                child: Icon(icon, color: AppColors.primary, size: 28 * scale),
              ),

              SizedBox(width: 16 * scale),

              //------------------------------------------------
              // Title
              //------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: (16 * scale).clamp(15.0, 18.0),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: (12 * scale).clamp(11.0, 13.0),
                      ),
                    ),
                  ],
                ),
              ),

              //------------------------------------------------
              // Minus
              //------------------------------------------------
              _ActionButton(
                icon: Icons.remove,
                enabled: value > minValue,
                onTap: onDecrement,
              ),

              SizedBox(width: 12 * scale),

              //------------------------------------------------
              // Value
              //------------------------------------------------
              SizedBox(
                width: 70 * scale,
                child: Column(
                  children: [
                    Text(
                      "$value",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: (24 * scale).clamp(22.0, 28.0),
                      ),
                    ),

                    Text(
                      unit,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12 * scale,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 12 * scale),

              //------------------------------------------------
              // Plus
              //------------------------------------------------
              _ActionButton(
                icon: Icons.add,
                enabled: value < maxValue,
                onTap: onIncrement,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: BorderRadius.circular(14),

        onTap: enabled ? onTap : null,

        child: Ink(
          width: 42,
          height: 42,

          decoration: BoxDecoration(
            color: enabled
                ? AppColors.primary.withOpacity(.12)
                : Colors.grey.withOpacity(.08),

            borderRadius: BorderRadius.circular(14),

            border: Border.all(
              color: enabled
                  ? AppColors.primary.withOpacity(.35)
                  : Colors.grey.withOpacity(.20),
            ),
          ),

          child: Icon(icon, color: enabled ? AppColors.primary : Colors.grey),
        ),
      ),
    );
  }
}
