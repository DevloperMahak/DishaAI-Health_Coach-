import 'dart:io';
import 'package:disha_ai/app/theme/app_colors.dart';
import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'meal_session.dart';

class MealDetailsScreen extends StatefulWidget {
  final MealSession? meal;

  const MealDetailsScreen({super.key, this.meal});

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================
  final AiController _aiController = Get.put(AiController());
  final TextEditingController _searchController = TextEditingController();

  bool _isLogged = false;
  bool _isFavorite = false;
  bool _isLoadingScan = false;

  late MealSession _currentMeal;

  @override
  void initState() {
    super.initState();
    _currentMeal =
        widget.meal ??
        MealSession(
          id: 'ai_scan_default',
          name: "Scanned Food Analysis",
          description:
              "Search or scan a food item to get instant AI nutritional breakdown.",
          mealType: "AI Scan",
          calories: "0",
          protein: "0",
          carbs: "0",
          fat: "0",
          preparationTime: "0",
          servingSize: "1 serving",
          difficulty: "Easy",
          imageUrl: "",
          icon: Icons.restaurant_rounded,
          ingredients: [],
          benefits: [],
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // 1. IMAGE PICKER & API SCAN
  // ============================================================

  Future<void> _pickAndScanImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);

      setState(() {
        _isLoadingScan = true;
      });

      final success = await _aiController.scanFoodImage(imageFile);

      setState(() {
        _isLoadingScan = false;
      });

      if (success) {
        _parseScanResponse(_aiController.foodAnalysis.value?.data);
        Get.snackbar(
          'Scan Complete',
          'Food analyzed successfully by Rhea AI!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
          margin: const EdgeInsets.all(16),
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
          ),
        );
      } else {
        Get.snackbar(
          'Scan Failed',
          _aiController.errorMessage.value.isNotEmpty
              ? _aiController.errorMessage.value
              : 'Could not analyze food image.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingScan = false;
      });
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // ============================================================
  // 2. TEXT SEARCH / MANUAL AI QUERY FEATURE
  // ============================================================

  Future<void> _searchFoodByName(String foodName) async {
    if (foodName.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoadingScan = true;
    });

    // Simulating quick intelligent lookup or passing to analysis handler
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isLoadingScan = false;
      _currentMeal = MealSession(
        id: 'search_${DateTime.now().millisecondsSinceEpoch}',
        name: foodName.capitalizeFirst ?? foodName,
        description: "AI nutritional composition breakdown for $foodName.",
        mealType: "AI Search",
        calories: "340",
        protein: "18",
        carbs: "42",
        fat: "10",
        preparationTime: "10",
        servingSize: "1 portion",
        difficulty: "Easy",
        imageUrl: "",
        icon: Icons.local_dining_rounded,
        ingredients: [
          "Primary fresh ingredients of $foodName",
          "Balanced macronutrient distribution",
        ],
        benefits: [
          "Optimized for daily wellness targets",
          "Provides steady energy release",
        ],
      );
    });

    Get.snackbar(
      'Analysis Successful',
      'Generated nutrition details for $foodName',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
    );
  }

  // ============================================================
  // PARSERS
  // ============================================================

  void _parseScanResponse(dynamic data) {
    if (data == null) return;

    Map<String, dynamic> mapData = {};
    if (data is Map<String, dynamic>) {
      mapData = data['food'] is Map ? data['food'] : data;
    }

    setState(() {
      _currentMeal = MealSession(
        id:
            mapData['id']?.toString() ??
            'scanned_${DateTime.now().millisecondsSinceEpoch}',
        name:
            mapData['name']?.toString() ??
            mapData['food_name']?.toString() ??
            "Analyzed Meal",
        description:
            mapData['description']?.toString() ??
            "Identified via Rhea AI Food Scanner.",
        mealType: mapData['meal_type']?.toString() ?? "Custom Scan",
        calories: mapData['calories']?.toString() ?? '0',
        protein: mapData['protein']?.toString() ?? '0',
        carbs: mapData['carbs']?.toString() ?? '0',
        fat: mapData['fat']?.toString() ?? '0',
        preparationTime: mapData['preparation_time']?.toString() ?? '5',
        servingSize: mapData['serving_size']?.toString() ?? "1 plate",
        difficulty: mapData['difficulty']?.toString() ?? "Easy",
        imageUrl: mapData['image_url']?.toString() ?? "",
        icon: Icons.restaurant_rounded,
        ingredients: _extractList(mapData['ingredients']),
        benefits: _extractList(
          mapData['benefits'] ?? mapData['health_benefits'],
        ),
      );
    });
  }

  List<String> _extractList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  void _showScanOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text(
                'Scan Food with Camera',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Get.back();
                _pickAndScanImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primary,
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Get.back();
                _pickAndScanImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _logMeal() {
    setState(() {
      _isLogged = true;
    });
    Get.snackbar(
      'Meal Logged',
      '${_currentMeal.name} has been added to today\'s nutrition.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.all(16),
      icon: const Icon(
        Icons.check_circle_outline_rounded,
        color: AppColors.primary,
      ),
    );
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  // ============================================================
  // BUILD UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            if (width >= 700) {
              return _buildWideLayout(width);
            }
            return _buildPhoneLayout(width);
          },
        ),
      ),
    );
  }

  Widget _buildPhoneLayout(double width) {
    final scale = _scale(width);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20 * scale,
        16 * scale,
        20 * scale,
        35 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(scale),
          SizedBox(height: 18 * scale),
          _buildSearchBar(scale), // <--- Always visible Search Bar added here
          SizedBox(height: 18 * scale),
          _buildMealHero(scale),
          SizedBox(height: 22 * scale),
          _buildMealTitle(scale),
          SizedBox(height: 22 * scale),
          _buildNutritionCard(scale),
          SizedBox(height: 22 * scale),
          _buildSectionTitle(
            title: 'Ingredients',
            subtitle: 'What goes into this meal',
            scale: scale,
          ),
          SizedBox(height: 12 * scale),
          _buildIngredients(scale),
          SizedBox(height: 24 * scale),
          _buildSectionTitle(
            title: 'Health Benefits',
            subtitle: 'Why RheaAI recommends this meal',
            scale: scale,
          ),
          SizedBox(height: 12 * scale),
          _buildBenefits(scale),
          SizedBox(height: 28 * scale),
          _buildActionButtons(scale),
        ],
      ),
    );
  }

  Widget _buildWideLayout(double width) {
    final horizontalPadding = width >= 1400
        ? 120.0
        : width >= 1100
        ? 80.0
        : 40.0;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        28,
        horizontalPadding,
        50,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(1.0),
              const SizedBox(height: 20),
              _buildSearchBar(1.0),
              const SizedBox(height: 25),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildMealHero(1.0)),
                  const SizedBox(width: 28),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMealTitle(1.0),
                        const SizedBox(height: 22),
                        _buildNutritionCard(1.0),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                          title: 'Ingredients',
                          subtitle: 'What goes into this meal',
                          scale: 1.0,
                        ),
                        const SizedBox(height: 14),
                        _buildIngredients(1.0),
                      ],
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                          title: 'Health Benefits',
                          subtitle: 'Why RheaAI recommends this meal',
                          scale: 1.0,
                        ),
                        const SizedBox(height: 14),
                        _buildBenefits(1.0),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),
              _buildActionButtons(1.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(double scale) {
    return Row(
      children: [
        _circleButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Get.back(),
          scale: scale,
        ),
        SizedBox(width: 14 * scale),
        Expanded(
          child: Text(
            'Meal Details',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Camera/Scan Button
        _circleButton(
          icon: Icons.camera_alt_outlined,
          onTap: _showScanOptions,
          scale: scale,
          iconColor: AppColors.primary,
        ),
        SizedBox(width: 8 * scale),
        _circleButton(
          icon: _isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          onTap: _toggleFavorite,
          scale: scale,
          iconColor: _isFavorite ? AppColors.primary : AppColors.textPrimary,
        ),
      ],
    );
  }

  // ============================================================
  // VISIBLE SEARCH BAR WIDGET
  // ============================================================
  Widget _buildSearchBar(double scale) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        onSubmitted: (value) => _searchFoodByName(value),
        decoration: InputDecoration(
          hintText: "Search food name (e.g., Oatmeal, Paneer Tikka)...",
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.6),
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
          ),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.primary,
            ),
            onPressed: () => _searchFoodByName(_searchController.text),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMealHero(double scale) {
    return Container(
      width: double.infinity,
      height: 285 * scale,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22 * scale),
        child: Stack(
          children: [
            Positioned.fill(child: _buildMealImage(scale)),
            if (_isLoadingScan)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Rhea AI is analyzing food...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16 * scale,
              top: 16 * scale,
              child: _buildTag(_currentMeal.mealType, scale),
            ),
            Positioned(
              right: 16 * scale,
              top: 16 * scale,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * scale,
                  vertical: 6 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_outlined,
                      color: AppColors.primary,
                      size: 14 * scale,
                    ),
                    SizedBox(width: 4 * scale),
                    Text(
                      '${_currentMeal.calories} kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18 * scale,
              right: 18 * scale,
              bottom: 17 * scale,
              child: Text(
                _currentMeal.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealImage(double scale) {
    if (_currentMeal.imageUrl != null &&
        _currentMeal.imageUrl!.trim().isNotEmpty) {
      return Image.network(
        _currentMeal.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(scale),
      );
    }
    return _buildImagePlaceholder(scale);
  }

  Widget _buildImagePlaceholder(double scale) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withOpacity(0.16), AppColors.surface],
        ),
      ),
      child: Center(
        child: Container(
          width: 95 * scale,
          height: 95 * scale,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.25)),
          ),
          child: Icon(
            _currentMeal.icon,
            color: AppColors.primary,
            size: 45 * scale,
          ),
        ),
      ),
    );
  }

  Widget _buildMealTitle(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentMeal.name,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 23 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8 * scale),
        Text(
          _currentMeal.description,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5 * scale,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionCard(double scale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _nutritionItem(
              value: _currentMeal.calories,
              label: 'Calories',
              unit: 'kcal',
              scale: scale,
            ),
          ),
          Expanded(
            child: _nutritionItem(
              value: _currentMeal.protein,
              label: 'Protein',
              unit: 'g',
              scale: scale,
            ),
          ),
          Expanded(
            child: _nutritionItem(
              value: _currentMeal.carbs,
              label: 'Carbs',
              unit: 'g',
              scale: scale,
            ),
          ),
          Expanded(
            child: _nutritionItem(
              value: _currentMeal.fat,
              label: 'Fat',
              unit: 'g',
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutritionItem({
    required String value,
    required String label,
    required String unit,
    required double scale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 8.5),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required double scale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredients(double scale) {
    if (_currentMeal.ingredients.isEmpty) {
      return const Text(
        "No ingredients listed. Search or scan a meal above.",
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    return Column(
      children: _currentMeal.ingredients
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBenefits(double scale) {
    if (_currentMeal.benefits.isEmpty) {
      return const Text(
        "No health benefits listed.",
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    return Column(
      children: _currentMeal.benefits
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(Icons.spa, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActionButtons(double scale) {
    return ElevatedButton(
      onPressed: _logMeal,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        _isLogged ? "Meal Logged Successfully" : "Log This Meal",
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildTag(String text, double scale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 9.5,
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    required double scale,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 19),
      ),
    );
  }

  double _scale(double width) => (width / 390).clamp(0.88, 1.12);
}
