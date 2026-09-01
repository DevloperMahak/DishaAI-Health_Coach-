import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../widgets/ai_generated_plan_illustration.dart';

class GeneratedPlanScreen extends StatefulWidget {
  const GeneratedPlanScreen({super.key});

  @override
  State<GeneratedPlanScreen> createState() => _GeneratedPlanScreenState();
}

class _GeneratedPlanScreenState extends State<GeneratedPlanScreen>
    with TickerProviderStateMixin {
  //==============================================================
  // CONTROLLERS
  //==============================================================

  final AiController _aiController = Get.find<AiController>();

  //==============================================================
  // ANIMATION
  //==============================================================

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween(begin: const Offset(0, .08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  //==============================================================
  // RESPONSIVE HELPERS
  //==============================================================

  double _scale(double width) => (width / 390).clamp(.88, 1.12);
  double _spacing(double width, double value) => value * _scale(width);
  double _horizontalPadding(double width) {
    if (width <= 340) return 16;
    if (width <= 380) return 20;
    if (width <= 430) return 22;
    return 28;
  }

  //==============================================================
  // START (Navigation to Journey Ahead Screen)
  //==============================================================

  void _startJourney() {
    FocusScope.of(context).unfocus();
    // 💡 FIX: Navigate to JourneyAheadScreen before going to dashboard
    Get.toNamed(AppRoutes.journeyAhead);
  }

  //==============================================================
  // BUILD
  //==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            if (width >= 700 || width > height) {
              return _buildWideLayout(width: width, height: height);
            }

            return _buildPhoneLayout(width: width, height: height);
          },
        ),
      ),
    );
  }

  //==============================================================
  // PHONE LAYOUT
  //==============================================================

  Widget _buildPhoneLayout({required double width, required double height}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _horizontalPadding(width),
            vertical: 24,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(width),
                  SizedBox(height: _spacing(width, 8)),
                  _buildSubtitle(width),
                  SizedBox(height: _spacing(width, 24)),
                  const Center(child: AIGeneratedPlanIllustration()),
                  SizedBox(height: _spacing(width, 26)),
                  _buildDynamicPlanContent(width), // Shows the actual plan!
                  SizedBox(height: _spacing(width, 28)),
                  _buildStartButton(width),
                  SizedBox(height: _spacing(width, 20)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //==============================================================
  // TABLET LAYOUT
  //==============================================================

  Widget _buildWideLayout({required double width, required double height}) {
    final horizontalPadding = width >= 1200
        ? 100.0
        : width >= 900
        ? 70.0
        : 40.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 30,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(width),
                    const SizedBox(height: 8),
                    _buildSubtitle(width),
                    const SizedBox(height: 28),
                    const Center(child: AIGeneratedPlanIllustration()),
                    const SizedBox(height: 30),
                    _buildDynamicPlanContent(width),
                    const SizedBox(height: 32),
                    _buildStartButton(width),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(double width) {
    final scale = _scale(width);
    return Text(
      "Your personalized\nplan is ready ✨",
      style: TextStyle(
        fontSize: (27 * scale).clamp(23.0, 32.0),
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.15,
      ),
    );
  }

  Widget _buildSubtitle(double width) {
    final scale = _scale(width);
    return Text(
      "Here is a sneak peek of your daily wellness plan before we take you to your journey ahead.",
      style: TextStyle(
        fontSize: (13 * scale).clamp(12.0, 15.0),
        color: AppColors.textSecondary,
        height: 1.55,
      ),
    );
  }

  //==============================================================
  // DYNAMIC PLAN RENDERER
  //==============================================================

  Widget _buildDynamicPlanContent(double width) {
    final scale = _scale(width);
    final response = _aiController.healthPlan.value;
    final dynamic data = response?.data;

    if (data == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18 * scale),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withOpacity(.35)),
        ),
        child: const Text(
          "Your personalized plan has been configured and saved securely. Click below to view your journey ahead.",
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
      );
    }

    if (data is Map<String, dynamic>) {
      final Map<String, dynamic> planData = (data['plan'] is Map)
          ? data['plan']
          : data;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18 * scale),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withOpacity(.35)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: planData.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIconForSection(entry.key),
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key.replaceAll('_', ' ').capitalizeFirst ??
                              entry.key,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15 * scale,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.value.toString(),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5 * scale,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.4,
      ),
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withOpacity(.35)),
      ),
      child: RawScrollbar(
        thumbColor: AppColors.primary.withOpacity(0.5),
        radius: const Radius.circular(8),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Text(
            data.toString(),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14 * scale,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForSection(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('diet') ||
        lowerKey.contains('meal') ||
        lowerKey.contains('food'))
      return Icons.restaurant_menu_rounded;
    if (lowerKey.contains('workout') ||
        lowerKey.contains('exercise') ||
        lowerKey.contains('fitness'))
      return Icons.fitness_center_rounded;
    if (lowerKey.contains('water') || lowerKey.contains('hydration'))
      return Icons.water_drop_rounded;
    if (lowerKey.contains('sleep') || lowerKey.contains('rest'))
      return Icons.bedtime_rounded;
    if (lowerKey.contains('mind') || lowerKey.contains('stress'))
      return Icons.self_improvement_rounded;
    return Icons.check_circle_outline_rounded;
  }

  //==============================================================
  // BUTTON
  //==============================================================

  Widget _buildStartButton(double width) {
    final scale = _scale(width);
    final radius = (10 * scale).clamp(8.0, 12.0);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(.20),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _startJourney,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.rocket_launch_rounded, color: Colors.black),
              SizedBox(width: 10),
              Text(
                "Continue Journey",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
