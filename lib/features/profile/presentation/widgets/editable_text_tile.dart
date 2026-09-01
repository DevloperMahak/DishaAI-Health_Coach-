import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class EditableTextTile extends StatelessWidget {
  const EditableTextTile({
    super.key,
    required this.title,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.hintText = "",
    this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final tablet = width >= 700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //------------------------------------------------------
          // TITLE
          //------------------------------------------------------
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: tablet ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          //------------------------------------------------------
          // FIELD
          //------------------------------------------------------
          TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            onChanged: onChanged,

            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: tablet ? 16 : 15,
            ),

            decoration: InputDecoration(
              hintText: hintText,

              hintStyle: const TextStyle(color: AppColors.textSecondary),

              prefixIcon: Icon(icon, color: AppColors.primary),

              suffixIcon: enabled
                  ? const Icon(Icons.edit_outlined, color: AppColors.primary)
                  : null,

              filled: true,
              fillColor: AppColors.surface,

              contentPadding: EdgeInsets.symmetric(
                horizontal: tablet ? 20 : 16,
                vertical: tablet ? 20 : 16,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primary, width: 1.8),
              ),

              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
