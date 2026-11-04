import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class CustomWaterBottomSheet extends StatefulWidget {
  const CustomWaterBottomSheet({super.key, required this.onAdd});

  final ValueChanged<int> onAdd;

  @override
  State<CustomWaterBottomSheet> createState() => _CustomWaterBottomSheetState();
}

class _CustomWaterBottomSheetState extends State<CustomWaterBottomSheet> {
  final TextEditingController controller = TextEditingController();
  final List<int> presets = [150, 200, 300, 750, 1000];
  int? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          // Wrap the Column with SingleChildScrollView
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 55,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(.35),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                const SizedBox(height: 22),

                // Title
                const Text(
                  "Add Custom Water",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),

                // Presets
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: presets.map((ml) {
                    final active = selected == ml;
                    return ChoiceChip(
                      label: Text(
                        "$ml ml",
                        style: TextStyle(
                          color: active ? Colors.black : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      selected: active,
                      onSelected: (_) {
                        setState(() {
                          selected = ml;
                          controller.text = ml.toString();
                        });
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: active
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(.15),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Input
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter water amount (ml)",
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(.7),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    prefixIcon: const Icon(
                      Icons.water_drop_rounded,
                      color: AppColors.primary,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Add Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      final amount = int.tryParse(controller.text);

                      if (amount == null || amount <= 0) {
                        Get.snackbar(
                          "Invalid",
                          "Enter valid amount",
                          backgroundColor: AppColors.surface,
                          colorText: AppColors.textPrimary,
                        );
                        return;
                      }

                      widget.onAdd(amount);
                      Get.back();
                    },
                    child: const Text(
                      "Add Water",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
