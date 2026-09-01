import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PhoneNumberTile extends StatelessWidget {
  const PhoneNumberTile({
    super.key,
    required this.controller,
    this.countryCode = "+91",
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool tablet = width >= 700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //--------------------------------------------------
          // TITLE
          //--------------------------------------------------
          Text(
            "Mobile Number",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: tablet ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          //--------------------------------------------------
          // FIELD
          //--------------------------------------------------
          Row(
            children: [
              //------------------------------------------------
              // COUNTRY CODE
              //------------------------------------------------
              Container(
                width: tablet ? 100 : 88,
                height: tablet ? 60 : 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  countryCode,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: tablet ? 16 : 15,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              //------------------------------------------------
              // NUMBER FIELD
              //------------------------------------------------
              Expanded(
                child: TextFormField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  onChanged: onChanged,

                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: tablet ? 16 : 15,
                  ),

                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "Enter mobile number",

                    hintStyle: const TextStyle(color: AppColors.textSecondary),

                    prefixIcon: const Icon(
                      Icons.phone_android_rounded,
                      color: AppColors.primary,
                    ),

                    suffixIcon: enabled
                        ? const Icon(
                            Icons.edit_outlined,
                            color: AppColors.primary,
                          )
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
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 1.8,
                      ),
                    ),

                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
