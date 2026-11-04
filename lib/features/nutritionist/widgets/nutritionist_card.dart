import 'package:disha_ai/features/nutritionist/data/models/expert_model.dart';
import 'package:disha_ai/features/nutritionist/presentation/screens/nutritionist_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class NutritionistCard extends StatelessWidget {
  const NutritionistCard({super.key, required this.expert});

  final ExpertModel expert;

  // ============================================================
  // FORMAT CONSULTATION FEE WITH INDIAN RUPEE SYMBOL
  // ============================================================

  String get formattedFee {
    final String fee = expert.fee?.trim() ?? '';

    // Do not display an incorrect static consultation fee.
    if (fee.isEmpty) {
      return 'Fee unavailable';
    }

    // If the API already returns ₹, use it directly.
    if (fee.contains('₹')) {
      return fee;
    }

    // Convert Rs. or INR into ₹.
    final String cleanedFee = fee
        .replaceFirst(RegExp(r'^(Rs\.?|INR)\s*', caseSensitive: false), '')
        .trim();

    if (cleanedFee.isEmpty) {
      return 'Fee unavailable';
    }

    return '₹$cleanedFee';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.14),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // =====================================================
          // EXPERT PROFILE
          // =====================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expert profile image
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.background,
                backgroundImage:
                    expert.imageUrl != null && expert.imageUrl!.isNotEmpty
                    ? NetworkImage(expert.imageUrl!)
                    : const AssetImage('assets/images/Profile.png')
                          as ImageProvider,
                onBackgroundImageError: (_, __) {},
              ),

              const SizedBox(width: 12),

              // Expert name and specialization
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expert name
                    Text(
                      expert.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Expert specialization
                    Text(
                      expert.specialization ??
                          expert.designation ??
                          'Health Specialist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Divider(color: AppColors.primary.withOpacity(.1), height: 1),

          const SizedBox(height: 12),

          // =====================================================
          // CONSULTATION FEE + CONSULT BUTTON
          // =====================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // =================================================
              // DYNAMIC CONSULTATION FEE WITH ₹ SYMBOL
              // =================================================
              Flexible(
                child: Text(
                  formattedFee,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // =================================================
              // CONSULT NOW BUTTON
              // =================================================
              ElevatedButton(
                onPressed: () {
                  Get.to(() => NutritionistDetailScreen(expert: expert));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Consult Now',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
