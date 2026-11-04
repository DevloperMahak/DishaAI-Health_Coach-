import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:disha_ai/app/theme/app_colors.dart';
import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'meal_detail_screen.dart';
import 'meal_session.dart';
import 'package:disha_ai/features/dashboard/presentation/widgets/banner_carousel.dart';

class MealsHomeScreen extends StatefulWidget {
  const MealsHomeScreen({super.key});

  @override
  State<MealsHomeScreen> createState() => _MealsHomeScreenState();
}

class _MealsHomeScreenState extends State<MealsHomeScreen> {
  final AiController _aiController = Get.find<AiController>();
  final GlobalKey<BannerCarouselState> _bannerKey =
      GlobalKey<BannerCarouselState>();

  double _scale(double width) {
    return (width / 390).clamp(0.88, 1.12).toDouble();
  }

  Future<void> _refreshAll() async {
    await Future.wait<void>([
      _aiController.fetchTodayLogs(),
      _bannerKey.currentState?.refreshBanners() ?? Future<void>.value(),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _aiController.fetchTodayLogs();
  }

  Future<void> _navigateToDetail({String defaultMealType = 'snack'}) async {
    final prefilledMeal = MealSession(
      id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Search or Scan Food',
      description: 'Find a food item to log into your daily nutrition.',
      mealType: defaultMealType,
      calories: '0',
      protein: '0',
      carbs: '0',
      fat: '0',
      preparationTime: '0',
      servingSize: '1 serving',
      difficulty: 'Easy',
      imageUrl: '',
      icon: Icons.restaurant_rounded,
      ingredients: [],
      benefits: [],
    );

    try {
      await Get.to<void>(() => MealsdetailScreen(meal: prefilledMeal));

      if (!mounted) return;

      await _aiController.fetchTodayLogs();
    } catch (e, stackTrace) {
      debugPrint('❌ [Meals] Navigation/refresh error: $e');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // CONFIRM & DELETE DIALOG
  // ============================================================
  void _confirmDeleteMeal(int id, String foodName) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Meal Entry",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Text(
          "Are you sure you want to remove \"$foodName\" from today's log?",
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Get.back(); // Dismiss dialog
              final bool success = await _aiController.deleteFoodLog(id);

              if (success) {
                Get.snackbar(
                  "Removed",
                  "Food entry removed and calories updated.",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.surface,
                  colorText: AppColors.textPrimary,
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                );
              } else {
                Get.snackbar(
                  "Error",
                  _aiController.errorMessage.value.isNotEmpty
                      ? _aiController.errorMessage.value
                      : "Failed to remove food entry.",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.redAccent.withOpacity(0.9),
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = _scale(screenWidth);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 32 : 20 * scale,
                        vertical: 14 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ==========================================
                          // MEDITATION-STYLE HEADER
                          // ==========================================
                          _buildMealsHeader(scale),

                          SizedBox(height: 26 * scale),

                          // ==========================================
                          // GREETING
                          // ==========================================
                          _buildMealsGreeting(scale),

                          SizedBox(height: 28 * scale),

                          // ==========================================
                          // MEALS API BANNER
                          // ==========================================
                          BannerCarousel(
                            key: _bannerKey,
                            category: 'Meals',
                            title: 'Healthy Eating Inspiration',
                            subtitle: 'Nourish your body, one meal at a time',
                            height: 175,
                            autoSlideDuration: const Duration(seconds: 5),
                            showSectionTitle: true,
                          ),

                          SizedBox(height: 22 * scale),

                          // ==========================================
                          // TODAY'S CALORIE PROGRESS
                          // ==========================================
                          _buildMealsCalorieProgress(scale),

                          SizedBox(height: 26 * scale),

                          // ==========================================
                          // EXISTING MEAL ACTIONS AND LOGS
                          // ==========================================
                          _buildMealsQuickActions(scale),

                          SizedBox(height: 28 * scale),

                          _buildMealsLoggedMeals(scale),

                          SizedBox(height: 28 * scale),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  // ============================================================
  // HEADER — SAME STYLE AS MEDITATION
  // ============================================================

  Widget _buildMealsHeader(double scale) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(21 * scale),
            child: Container(
              width: 42 * scale,
              height: 42 * scale,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.16)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 19.3 * scale,
              ),
            ),
          ),
        ),

        SizedBox(width: 14 * scale),

        Expanded(
          child: Text(
            'Nutrition & Meals',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GREETING — SAME STYLE AS MEDITATION
  // ============================================================

  Widget _buildMealsGreeting(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eat Well, Feel Better',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 24 * scale,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),

        SizedBox(height: 7 * scale),

        Text(
          'Fuel your day with balanced, nourishing meals.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5 * scale,
            height: 1.45,
          ),
        ),
      ],
    );
  }
  // ============================================================
  // TODAY'S CALORIE PROGRESS
  // ============================================================

  Widget _buildMealsCalorieProgress(double scale) {
    return Obx(() {
      final totalCalories = _aiController.todayTotalCalories.value;
      final targetCalories = _aiController.targetCalories.value;

      final progress = _aiController.calorieProgressPercentage.value
          .clamp(0.0, 1.0)
          .toDouble();

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18 * scale),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary.withOpacity(0.13), AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18 * scale),
          border: Border.all(color: AppColors.primary.withOpacity(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.primary,
                  size: 22 * scale,
                ),

                SizedBox(width: 8 * scale),

                Expanded(
                  child: Text(
                    "Today's Progress",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10 * scale),

            Text(
              '$totalCalories / $targetCalories kcal',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 15 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 12 * scale),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9 * scale,
                backgroundColor: AppColors.background,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),

            SizedBox(height: 17 * scale),

            SizedBox(
              width: double.infinity,
              height: 44 * scale,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToDetail(defaultMealType: 'snack'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                ),
                icon: Icon(Icons.add_rounded, size: 20 * scale),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Scan or Search to Log Meal',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5 * scale,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ============================================================
  // QUICK MEAL ACTIONS
  // ============================================================

  Widget _buildMealsQuickActions(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Meal Actions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),

        SizedBox(height: 13 * scale),

        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.breakfast_dining_rounded,
                title: 'Breakfast',
                onTap: () => _navigateToDetail(defaultMealType: 'breakfast'),
              ),
            ),

            SizedBox(width: 12 * scale),

            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.lunch_dining_rounded,
                title: 'Lunch',
                onTap: () => _navigateToDetail(defaultMealType: 'lunch'),
              ),
            ),
          ],
        ),

        SizedBox(height: 12 * scale),

        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.dinner_dining_rounded,
                title: 'Dinner',
                onTap: () => _navigateToDetail(defaultMealType: 'dinner'),
              ),
            ),

            SizedBox(width: 12 * scale),

            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.local_dining_rounded,
                title: 'Snacks',
                onTap: () => _navigateToDetail(defaultMealType: 'snack'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMealsLoggedMeals(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Logged Meals",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),

        SizedBox(height: 12 * scale),

        // Paste the original Obx(() { ... }) block
        // that displays loggedMeals here.
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
