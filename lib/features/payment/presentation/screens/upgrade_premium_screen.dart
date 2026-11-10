import 'package:disha_ai/features/payment/presentation/controllers/premium_report_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class UpgradePremiumScreen extends StatelessWidget {
  const UpgradePremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<PremiumReportController>()
        ? Get.find<PremiumReportController>()
        : Get.put(PremiumReportController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Upgrade to Premium",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PREMIUM HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Unlock Ultimate AI Health Power",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Get unlimited food scans, expert priority consultations, and advanced health report analytics.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Premium Benefits",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _buildBenefitRow(
                Icons.bolt_rounded,
                "Unlimited AI Food & Image Analysis",
              ),

              _buildBenefitRow(
                Icons.support_agent_rounded,
                "Priority Expert Nutritionist Access",
              ),

              _buildBenefitRow(
                Icons.analytics_rounded,
                "Comprehensive Weekly & Monthly Reports",
              ),

              const SizedBox(height: 30),

              // PREMIUM PRICE
              const Center(
                child: Column(
                  children: [
                    Text(
                      '₹399',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'per month',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // PREMIUM SUBSCRIPTION BUTTON
              Obx(() {
                final isPaying = controller.isSubscribing.value;

                return SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    // Available during active ₹3 trial too.
                    // Disabled only while payment is processing.
                    onPressed: isPaying
                        ? null
                        : () async {
                            debugPrint(
                              '========== RHEAAI PREMIUM UPGRADE ==========',
                            );

                            debugPrint('Selected plan: premium_monthly');

                            await controller.startSubscription(
                              planCode: 'premium_monthly',
                              description:
                                  'Monthly AI Health Coaching Subscription',
                              onSuccess: () {
                                debugPrint(
                                  'Premium payment verified. Opening dashboard...',
                                );

                                Future<void>.delayed(Duration.zero, () {
                                  Get.offAllNamed<void>(AppRoutes.dashboard);
                                });
                              },
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppColors.primary.withOpacity(
                        0.65,
                      ),
                      disabledForegroundColor: Colors.black.withOpacity(0.7),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isPaying
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Subscribe Now (₹399/month)",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              const Center(
                child: Text(
                  "Upgrade anytime, even during your active trial.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // BENEFIT ROW
  Widget _buildBenefitRow(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
