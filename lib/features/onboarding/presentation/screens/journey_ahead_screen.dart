import 'package:disha_ai/features/payment/presentation/controllers/premium_report_controller.dart';
import 'package:flutter/material.dart';
import 'package:disha_ai/app/routes/app_routes.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class JourneyAheadScreen extends StatelessWidget {
  const JourneyAheadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<PremiumReportController>()
        ? Get.find<PremiumReportController>()
        : Get.put(PremiumReportController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final bool isTablet = width >= 600;

            return Column(
              children: [
                // ============================================================
                // SCROLLABLE CONTENT AREA
                // ============================================================
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? width * 0.18 : 20,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 600 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ------------------------------------------------
                            // TITLE
                            // ------------------------------------------------
                            Text(
                              "Your journey ahead!",
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: isTablet ? 28 : 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ------------------------------------------------
                            // VERTICAL TIMELINE
                            // ------------------------------------------------
                            Stack(
                              children: [
                                Positioned(
                                  left: 13,
                                  top: 16,
                                  bottom: 16,
                                  child: Container(
                                    width: 2,
                                    color: AppColors.border,
                                  ),
                                ),

                                Column(
                                  children: [
                                    // STEP 1: PROFILE READY
                                    _buildTimelineNode(
                                      isCompleted: true,
                                      isCurrent: false,
                                      title: "Profile ready!",
                                      subtitle:
                                          "I've understood your goals. Now it's time to create your plan.",
                                      isTablet: isTablet,
                                    ),

                                    const SizedBox(height: 24),

                                    // STEP 2: UNLOCK HEALTH PLAN
                                    _buildTimelineUnlockNode(isTablet),

                                    const SizedBox(height: 24),

                                    // STEP 3: TRIAL ENDS
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

                            // ------------------------------------------------
                            // PRICING INFORMATION
                            // ------------------------------------------------
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
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
                                      "Then, ₹399/mo after trial ends\n"
                                      "No hidden charges. You can cancel anytime.",
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
                ),

                // ============================================================
                // STICKY BOTTOM BUTTON BAR
                // ============================================================
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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 600 : double.infinity,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: isTablet ? 58 : 52,

                        // ----------------------------------------------------
                        // RAZORPAY PAYMENT BUTTON
                        // ----------------------------------------------------
                        child: Obx(() {
                          final bool isLoading = controller.isSubscribing.value;

                          return ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    debugPrint(
                                      '========== RHEAAI TRIAL BUTTON ==========',
                                    );

                                    debugPrint(
                                      '💳 User clicked Try for 3 days',
                                    );

                                    // ------------------------------------------------
                                    // START ₹3 ONBOARDING TRIAL PAYMENT
                                    // ------------------------------------------------
                                    //
                                    // PremiumReportController handles:
                                    //
                                    // 1. POST /payment/create-order
                                    // 2. Open Razorpay checkout
                                    // 3. Receive payment success callback
                                    // 4. POST /payment/verify
                                    // 5. GET /auth/me
                                    // 6. Confirm onboarding_completed
                                    // 7. Navigate to Dashboard
                                    //
                                    // Navigation occurs in onSuccess after verification.
                                    // ------------------------------------------------

                                    await controller.startSubscription(
                                      amount: 3.0,
                                      description: 'Unlock Health Plan Trial',
                                      // Called by PremiumReportController ONLY
                                      // after payment verification, /auth/me,
                                      // and onboarding_completed validation.
                                      onSuccess: () {
                                        debugPrint(
                                          '✅ Trial verified. Opening dashboard...',
                                        );
                                        // Let Razorpay's callback finish before
                                        // replacing the navigation stack.
                                        Future<void>.delayed(Duration.zero, () {
                                          try {
                                            Get.offAllNamed<void>(
                                              AppRoutes.dashboard,
                                            );
                                          } catch (error, stackTrace) {
                                            debugPrint(
                                              '❌ Dashboard navigation: $error',
                                            );
                                            debugPrint('$stackTrace');
                                          }
                                        });
                                      },
                                    );
                                  },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: AppColors.primary
                                  .withOpacity(0.65),
                              disabledForegroundColor: Colors.black.withOpacity(
                                0.7,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),

                            // ------------------------------------------------
                            // BUTTON CONTENT
                            // ------------------------------------------------
                            child: isLoading
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
                          );
                        }),
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
  // STANDARD TIMELINE NODE
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
        // --------------------------------------------------------
        // TIMELINE DOT
        // --------------------------------------------------------
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

        // --------------------------------------------------------
        // TIMELINE CARD
        // --------------------------------------------------------
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
        // --------------------------------------------------------
        // HIGHLIGHTED TIMELINE DOT
        // --------------------------------------------------------
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

        // --------------------------------------------------------
        // FEATURED CARD
        // --------------------------------------------------------
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
                // ------------------------------------------------
                // TITLE
                // ------------------------------------------------
                Text(
                  "Unlock your health plan for just ₹3",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // ------------------------------------------------
                // DESCRIPTION
                // ------------------------------------------------
                Text(
                  "Will be created after consultation call, "
                  "understanding your goals and lifestyle.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: isTablet ? 14 : 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // PLAN FEATURES
                // ------------------------------------------------
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Wrap avoids overflow inside the highlighted border.
                    final available = constraints.maxWidth;
                    final columns = available >= 300 ? 3 : 2;
                    const gap = 8.0;
                    final pillWidth =
                        (available - gap * (columns - 1)) / columns;

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        _buildPlanPill(
                          icon: Icons.restaurant_rounded,
                          label: 'Diet Plan',
                          isTablet: isTablet,
                          width: pillWidth,
                        ),
                        _buildPlanPill(
                          icon: Icons.fitness_center_rounded,
                          label: 'Fitness Plan',
                          isTablet: isTablet,
                          width: pillWidth,
                        ),
                        _buildPlanPill(
                          icon: Icons.assignment_turned_in_rounded,
                          label: 'Health Report',
                          isTablet: isTablet,
                          width: pillWidth,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PLAN FEATURE PILL
  // ============================================================

  Widget _buildPlanPill({
    required IconData icon,
    required String label,
    required bool isTablet,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
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
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
