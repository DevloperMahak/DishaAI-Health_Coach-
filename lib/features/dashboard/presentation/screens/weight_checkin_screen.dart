import 'package:disha_ai/features/onboarding/presentation/controllers/health_nutrition_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:disha_ai/app/theme/app_colors.dart';
import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';

class WeightCheckinScreen extends StatefulWidget {
  const WeightCheckinScreen({super.key});

  @override
  State<WeightCheckinScreen> createState() => _WeightCheckinScreenState();
}

class _WeightCheckinScreenState extends State<WeightCheckinScreen> {
  final HealthNutritionController _healthController = Get.put(
    HealthNutritionController(),
  );
  final HealthProfileController _healthProfileController = Get.put(
    HealthProfileController(),
  );

  final TextEditingController _weightController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialWeight();
  }

  void _loadInitialWeight() {
    final currentLogWeight = _healthController.healthLog.value?.weightKg;
    final profileWeight =
        _healthProfileController.healthProfile.value?.weightKg;
    final initial = currentLogWeight ?? profileWeight ?? 65.0;
    _weightController.text = initial.toString();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveWeight() async {
    final parsedWeight = double.tryParse(_weightController.text.trim());
    if (parsedWeight == null || parsedWeight <= 0) {
      Get.snackbar(
        "Invalid Input",
        "Please enter a valid weight in kg.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final currentLog = _healthController.healthLog.value;

    // Syncing updated weight with backend health API
    final success = await _healthController.postHealthMetrics(
      steps: currentLog?.steps ?? 0,
      sleepHours: currentLog?.sleepHours ?? 7.5,
      caloriesConsumed: currentLog?.caloriesConsumed ?? 1800,
      caloriesBurned: currentLog?.caloriesBurned ?? 350,
      weightKg: parsedWeight,
      mood: currentLog?.mood ?? "energetic",
      stressLevel: currentLog?.stressLevel ?? "low",
    );

    setState(() => _isSubmitting = false);

    if (success) {
      Get.back();
      Get.snackbar(
        "Weight Updated",
        "Successfully logged your weight as $parsedWeight kg!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
      );
    } else {
      Get.snackbar(
        "Sync Failed",
        "Could not save weight metrics. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          "Weight Check-in",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // TARGET & GOAL CARD PREVIEW
              Obx(() {
                final targetWeight =
                    _healthProfileController
                        .healthProfile
                        .value
                        ?.targetWeightKg ??
                    58.0;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            "Target Goal",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$targetWeight kg",
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                      Column(
                        children: [
                          const Text(
                            "Goal Status",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "On Track",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 40),

              const Text(
                "Enter your current weight",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Regular logging helps your AI coach fine-tune your nutrition and calorie goals.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 30),

              // WEIGHT INPUT FIELD
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  suffixText: "kg",
                  suffixStyle: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // SUBMIT BUTTON
              ElevatedButton(
                onPressed: _isSubmitting ? null : _saveWeight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "Save Weight Record",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
