import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'package:disha_ai/features/onboarding/presentation/widgets/ai_generated_plan_illustration.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';

class GeneratedPlanDashboardScreen extends StatefulWidget {
  const GeneratedPlanDashboardScreen({super.key});

  @override
  State<GeneratedPlanDashboardScreen> createState() =>
      _GeneratedPlanDashboardScreenState();
}

class _GeneratedPlanDashboardScreenState
    extends State<GeneratedPlanDashboardScreen>
    with TickerProviderStateMixin {
  //==============================================================
  // CONTROLLER
  //==============================================================

  late final AiController _aiController;

  //==============================================================
  // ANIMATION
  //==============================================================

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  //==============================================================
  // INITIALIZATION
  //==============================================================

  @override
  void initState() {
    super.initState();

    // Use the already registered AiController when PlanScreen
    // opened this screen.
    //
    // If this screen is opened directly, create the controller.
    if (Get.isRegistered<AiController>()) {
      _aiController = Get.find<AiController>();
    } else {
      _aiController = Get.put(AiController());
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, .08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    // Important:
    // Make this screen responsible for loading the plan if it
    // is not already available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensurePlanLoaded();
    });
  }

  //==============================================================
  // ENSURE PLAN IS AVAILABLE
  //==============================================================

  Future<void> _ensurePlanLoaded() async {
    // If the plan is already available, there is nothing to do.
    if (_aiController.healthPlan.value != null) {
      return;
    }

    // If another screen is already generating the plan, don't
    // start another request.
    if (_aiController.isGeneratingPlan.value) {
      return;
    }

    try {
      await _aiController.generateHealthPlan();
    } catch (e) {
      debugPrint('❌ [GENERATED PLAN] Failed to load plan: $e');
    }
  }

  //==============================================================
  // DISPOSE
  //==============================================================

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  //==============================================================
  // RESPONSIVE HELPERS
  //==============================================================

  double _scale(double width) {
    return (width / 390).clamp(.88, 1.12);
  }

  double _spacing(double width, double value) {
    return value * _scale(width);
  }

  double _horizontalPadding(double width) {
    if (width <= 340) return 16;
    if (width <= 380) return 20;
    if (width <= 430) return 22;
    return 28;
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

                  _buildDynamicPlanContent(width),

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
  // TABLET / WIDE LAYOUT
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

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  //==============================================================
  // TITLE
  //==============================================================

  Widget _buildTitle(double width) {
    final scale = _scale(width);

    return Text(
      'Your personalized\nplan is ready ✨',
      style: TextStyle(
        fontSize: (27 * scale).clamp(23.0, 32.0),
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.15,
      ),
    );
  }

  //==============================================================
  // SUBTITLE
  //==============================================================

  Widget _buildSubtitle(double width) {
    final scale = _scale(width);

    return Text(
      'Here is your personalized wellness plan generated using your health information and preferences.',
      style: TextStyle(
        fontSize: (13 * scale).clamp(12.0, 15.0),
        color: AppColors.textSecondary,
        height: 1.55,
      ),
    );
  }

  //==============================================================
  // DYNAMIC PLAN CONTENT
  //==============================================================

  Widget _buildDynamicPlanContent(double width) {
    final scale = _scale(width);

    return Obx(() {
      final isGenerating = _aiController.isGeneratingPlan.value;
      final response = _aiController.healthPlan.value;
      final dynamic data = response?.data;

      //============================================================
      // LOADING
      //============================================================

      if (isGenerating) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(24 * scale),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.primary.withOpacity(.25)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Creating your personalized plan...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'AI is preparing recommendations based on your profile.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5 * scale,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      }

      //============================================================
      // NO DATA
      //============================================================

      if (data == null) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20 * scale),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.primary.withOpacity(.25)),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(.12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Your plan is not available yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'We could not load your personalized plan. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5 * scale,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _ensurePlanLoaded();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Generate Plan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      //============================================================
      // MAP RESPONSE
      //============================================================

      if (data is Map) {
        final Map<String, dynamic> responseMap = Map<String, dynamic>.from(
          data,
        );

        final dynamic rawPlan = responseMap['plan'];

        final Map<String, dynamic> planData = rawPlan is Map
            ? Map<String, dynamic>.from(rawPlan)
            : responseMap;

        if (planData.isEmpty) {
          return _buildEmptyPlanCard(scale);
        }

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
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(.12),
                          ),
                          child: Icon(
                            _getIconForSection(entry.key),
                            color: AppColors.primary,
                            size: 19,
                          ),
                        ),

                        const SizedBox(width: 10),

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

                    const SizedBox(height: 8),

                    _buildPlanValue(entry.value, scale),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }

      //============================================================
      // OTHER RESPONSE TYPES
      //============================================================

      return Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .45,
        ),
        padding: EdgeInsets.all(18 * scale),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withOpacity(.35)),
        ),
        child: RawScrollbar(
          thumbColor: AppColors.primary.withOpacity(.5),
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
    });
  }

  //==============================================================
  // PLAN VALUE
  //==============================================================

  Widget _buildPlanValue(dynamic value, double scale) {
    // Handle nested maps cleanly.
    if (value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key.toString().replaceAll('_', ' ').capitalizeFirst ??
                      entry.key.toString(),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13 * scale,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.value.toString(),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13 * scale,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Handle lists such as meal plans, workout lists, etc.
    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.asMap().entries.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    item.value.toString(),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5 * scale,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Text(
      value.toString(),
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13.5 * scale,
        height: 1.5,
      ),
    );
  }

  //==============================================================
  // EMPTY PLAN
  //==============================================================

  Widget _buildEmptyPlanCard(double scale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withOpacity(.25)),
      ),
      child: const Text(
        'Your personalized plan is ready, but no plan sections were returned.',
        style: TextStyle(color: AppColors.textSecondary, height: 1.5),
      ),
    );
  }

  //==============================================================
  // SECTION ICONS
  //==============================================================

  IconData _getIconForSection(String key) {
    final lowerKey = key.toLowerCase();

    if (lowerKey.contains('diet') ||
        lowerKey.contains('meal') ||
        lowerKey.contains('food') ||
        lowerKey.contains('nutrition')) {
      return Icons.restaurant_menu_rounded;
    }

    if (lowerKey.contains('workout') ||
        lowerKey.contains('exercise') ||
        lowerKey.contains('fitness') ||
        lowerKey.contains('activity')) {
      return Icons.fitness_center_rounded;
    }

    if (lowerKey.contains('water') || lowerKey.contains('hydration')) {
      return Icons.water_drop_rounded;
    }

    if (lowerKey.contains('sleep') || lowerKey.contains('rest')) {
      return Icons.bedtime_rounded;
    }

    if (lowerKey.contains('mind') ||
        lowerKey.contains('stress') ||
        lowerKey.contains('mental')) {
      return Icons.self_improvement_rounded;
    }

    if (lowerKey.contains('goal') || lowerKey.contains('target')) {
      return Icons.flag_rounded;
    }

    return Icons.check_circle_outline_rounded;
  }
}
