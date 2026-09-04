import 'package:disha_ai/features/payment/presentation/controllers/premium_report_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class JourneyAheadScreen extends StatelessWidget {
  const JourneyAheadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PremiumReportController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final bool isTablet = width >= 600;

            return Column(
              children: [
                // ==========================================
                // SCROLLABLE CONTENT AREA
                // ==========================================
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? width * 0.18 : 20,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 600 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ------------------------------------------
                          // TITLE
                          // ------------------------------------------
                          Text(
                            "Your journey ahead!",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: isTablet ? 28 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ------------------------------------------
                          // VERTICAL TIMELINE CONTAINER
                          // ------------------------------------------
                          Stack(
                            children: [
                              // Continuous Timeline Vertical Line
                              Positioned(
                                left: 13,
                                top: 16,
                                bottom: 16,
                                child: Container(
                                  width: 2,
                                  color: AppColors.border,
                                ),
                              ),

                              // Timeline Steps Column
                              Column(
                                children: [
                                  // STEP 1: Profile ready
                                  _buildTimelineNode(
                                    isCompleted: true,
                                    isCurrent: false,
                                    title: "Profile ready!",
                                    subtitle:
                                        "I've understood your goals. Now it's time to create your plan.",
                                    isTablet: isTablet,
                                  ),
                                  const SizedBox(height: 24),

                                  // STEP 2: Unlock health plan (Highlighted Card)
                                  _buildTimelineUnlockNode(isTablet),
                                  const SizedBox(height: 24),

                                  // STEP 3: Trial ends
                                  _buildTimelineNode(
                                    isCompleted: false,
                                    isCurrent: false,
                                    title: "Trial ends",
                                    subtitle:
                                        "I'll send you a reminder when the trial is ending.",
                                    isTablet: isTablet,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ------------------------------------------
                          // PRICING INFO TEXT
                          // ------------------------------------------
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "• ",
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "Then, ₹399/mo after trial ends\nNo hidden charges. You can cancel anytime.",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: isTablet ? 15 : 13.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),

                // ==========================================
                // STICKY BOTTOM BUTTON BAR WITH RAZORPAY PAYMENT & DASHBOARD REDIRECTION
                // ==========================================
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? width * 0.18 : 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(
                      top: BorderSide(color: AppColors.border.withOpacity(0.4)),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 600 : double.infinity,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: isTablet ? 58 : 52,
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: controller.isSubscribing.value
                              ? null
                              : () async {
                                  // Call subscription flow.
                                  // Inside PremiumReportController, after successful verification,
                                  // it navigates to Dashboard or you can handle it via callback / success check.
                                  await controller.startSubscription();

                                  // Optional: If you want to force navigate on success after payment popup finishes
                                  if (controller.errorMessage.value.isEmpty &&
                                      !controller.isSubscribing.value) {
                                    // Get.offAllNamed(AppRoutes.dashboard);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: controller.isSubscribing.value
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Try for 3 days",
                                      style: TextStyle(
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // STANDARD TIMELINE NODE WITH CARD
  // ============================================================
  Widget _buildTimelineNode({
    required bool isCompleted,
    required bool isCurrent,
    required String title,
    required String subtitle,
    required bool isTablet,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Dot Indicator
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppColors.primary : AppColors.surface,
            border: Border.all(
              color: isCompleted ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: isCompleted
              ? const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.black,
                  ),
                )
              : Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 14),

        // Card Content
        Expanded(
          child: Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: isTablet ? 14 : 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // UNLOCK HEALTH PLAN FEATURED TIMELINE NODE
  // ============================================================
  Widget _buildTimelineUnlockNode(bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Highlighted Dot Indicator
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.primary, width: 2.5),
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Featured Card Content
        Expanded(
          child: Container(
            padding: EdgeInsets.all(isTablet ? 22 : 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Unlock your health plan for just ₹3",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Will be created after consultation call, understanding your goals and lifestyle.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: isTablet ? 14 : 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),

                // ------------------------------------------
                // PLAN PILLS ROW
                // ------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPlanPill(
                      icon: Icons.restaurant_rounded,
                      label: "Diet Plan",
                      isTablet: isTablet,
                    ),
                    _buildPlanPill(
                      icon: Icons.fitness_center_rounded,
                      label: "Fitness Plan",
                      isTablet: isTablet,
                    ),
                    _buildPlanPill(
                      icon: Icons.assignment_turned_in_rounded,
                      label: "Health Report",
                      isTablet: isTablet,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanPill({
    required IconData icon,
    required String label,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: isTablet ? 24 : 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isTablet ? 13 : 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
