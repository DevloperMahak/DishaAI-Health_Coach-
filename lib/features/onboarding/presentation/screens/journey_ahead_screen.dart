import 'package:disha_ai/features/payment/presentation/controllers/premium_report_controller.dart';
import 'package:flutter/material.dart';
import 'package:disha_ai/app/routes/app_routes.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class JourneyAheadScreen extends StatefulWidget {
  const JourneyAheadScreen({super.key});

  @override
  State<JourneyAheadScreen> createState() => _JourneyAheadScreenState();
}

class _JourneyAheadScreenState extends State<JourneyAheadScreen> {
  late final PremiumReportController controller;

  @override
  void initState() {
    super.initState();

    controller = Get.isRegistered<PremiumReportController>()
        ? Get.find<PremiumReportController>()
        : Get.put(PremiumReportController());

    controller.fetchMembershipPlans();
  }

  String _formatPrice(dynamic price) {
    final value = num.tryParse(price?.toString() ?? '');

    if (value == null) return '';

    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  String _formatDuration(Map<String, dynamic>? plan) {
    if (plan == null) return '';

    final value = plan['duration_value']?.toString() ?? '';
    final unit = plan['duration_unit']?.toString().toLowerCase() ?? '';

    if (value.isEmpty || unit.isEmpty) return '';

    final formattedUnit = value == '1' ? unit.replaceAll('s', '') : unit;

    return '$value $formattedUnit';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final trialPlan = controller.getPlanByCode('initial_access');
      final premiumPlan = controller.getPlanByCode('premium_monthly');

      final trialPrice = _formatPrice(trialPlan?['price']);
      final premiumPrice = _formatPrice(premiumPlan?['price']);
      final trialDuration = _formatDuration(trialPlan);

      final isLoading = controller.isMembershipLoading.value;
      final isPaying = controller.isSubscribing.value;
      final planAvailable = trialPlan != null;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final bool isTablet = width >= 600;

              return Column(
                children: [
                  // ========================================================
                  // SCROLLABLE CONTENT AREA
                  // ========================================================
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
                              Text(
                                "Your journey ahead!",
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: isTablet ? 28 : 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 28),

                              // VERTICAL TIMELINE
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
                                      _buildTimelineNode(
                                        isCompleted: true,
                                        isCurrent: false,
                                        title: "Profile ready!",
                                        subtitle:
                                            "I've understood your goals. Now it's time to create your plan.",
                                        isTablet: isTablet,
                                      ),

                                      const SizedBox(height: 24),

                                      _buildTimelineUnlockNode(
                                        isTablet,
                                        trialPrice: trialPrice,
                                        trialDuration: trialDuration,
                                      ),

                                      const SizedBox(height: 24),

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

                              // PRICING INFORMATION
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
                                        premiumPrice.isNotEmpty
                                            ? "Then, ₹$premiumPrice/mo after trial ends\n"
                                                  "No hidden charges. You can cancel anytime."
                                            : "Your membership pricing will be shown before payment.",
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

                  // ========================================================
                  // STICKY BOTTOM BUTTON BAR
                  // ========================================================
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? width * 0.18 : 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.border.withOpacity(0.4),
                        ),
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
                          child: ElevatedButton(
                            onPressed: isLoading || isPaying || !planAvailable
                                ? null
                                : () async {
                                    debugPrint(
                                      '========== RHEAAI TRIAL BUTTON ==========',
                                    );

                                    debugPrint(
                                      'User selected initial_access plan',
                                    );

                                    await controller.startSubscription(
                                      planCode: 'initial_access',
                                      description: 'Unlock Health Plan Trial',
                                      onSuccess: () {
                                        debugPrint(
                                          'Trial verified. Opening dashboard...',
                                        );

                                        Future<void>.delayed(Duration.zero, () {
                                          Get.offAllNamed<void>(
                                            AppRoutes.dashboard,
                                          );
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
                            child: isLoading || isPaying
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
                                        !planAvailable
                                            ? 'Trial plan unavailable'
                                            : trialDuration.isNotEmpty
                                            ? 'Try for $trialDuration'
                                            : trialPrice.isNotEmpty
                                            ? 'Continue for ₹$trialPrice'
                                            : 'Continue',
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
    });
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

  Widget _buildTimelineUnlockNode(
    bool isTablet, {
    required String trialPrice,
    required String trialDuration,
  }) {
    final priceText = trialPrice.isNotEmpty ? '₹$trialPrice' : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  priceText.isNotEmpty
                      ? "Unlock your health plan for just $priceText"
                      : "Unlock your health plan",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (trialDuration.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Access duration: $trialDuration',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: isTablet ? 13 : 12,
                    ),
                  ),
                ],

                const SizedBox(height: 4),

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

                LayoutBuilder(
                  builder: (context, constraints) {
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
