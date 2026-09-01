import 'package:disha_ai/features/onboarding/presentation/controllers/health_nutrition_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:disha_ai/app/theme/app_colors.dart';

class SleepCheckinScreen extends StatefulWidget {
  const SleepCheckinScreen({super.key});

  @override
  State<SleepCheckinScreen> createState() => _SleepCheckinScreenState();
}

class _SleepCheckinScreenState extends State<SleepCheckinScreen> {
  final HealthNutritionController _healthController = Get.put(
    HealthNutritionController(),
  );

  double _sleepHours = 7.5;
  String _selectedQuality = "good";
  bool _isSubmitting = false;

  final List<Map<String, String>> _qualities = [
    {"label": "Great", "value": "great", "emoji": "🌟"},
    {"label": "Good", "value": "good", "emoji": "😊"},
    {"label": "Fair", "value": "fair", "emoji": "😐"},
    {"label": "Poor", "value": "poor", "emoji": "😴"},
  ];

  Future<void> _saveSleepData() async {
    setState(() => _isSubmitting = true);

    // Fetch existing log values to preserve other metrics like steps or calories
    final currentLog = _healthController.healthLog.value;

    final success = await _healthController.postHealthMetrics(
      steps: currentLog?.steps ?? 0,
      sleepHours: _sleepHours,
      caloriesConsumed: currentLog?.caloriesConsumed ?? 1800,
      caloriesBurned: currentLog?.caloriesBurned ?? 350,
      weightKg: currentLog?.weightKg ?? 58.0,
      mood: currentLog?.mood ?? "energetic",
      stressLevel: currentLog?.stressLevel ?? "low",
    );

    setState(() => _isSubmitting = false);

    if (success) {
      Get.back();
      Get.snackbar(
        "Sleep Logged",
        "Your sleep of $_sleepHours hours was saved successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
      );
    } else {
      Get.snackbar(
        "Failed",
        "Could not save sleep metrics. Please try again.",
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
          "Sleep & Rest Check-in",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How many hours did you sleep?",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Track your nightly rest duration to analyze your recovery.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 30),

            // SLEEP HOURS DISPLAY & SLIDER
            Center(
              child: Column(
                children: [
                  Text(
                    "${_sleepHours.toStringAsFixed(1)} hrs",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.surface,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _sleepHours,
                      min: 1.0,
                      max: 14.0,
                      divisions: 26,
                      label: "${_sleepHours.toStringAsFixed(1)} hrs",
                      onChanged: (val) => setState(() => _sleepHours = val),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),
            const Text(
              "How was your sleep quality?",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // SLEEP QUALITY GRID
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 2.3,
              ),
              itemCount: _qualities.length,
              itemBuilder: (context, index) {
                final item = _qualities[index];
                final isSelected = _selectedQuality == item['value'];

                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedQuality = item['value']!),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.15),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Text(
                          item['emoji']!,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item['label']!,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 50),

            // SUBMIT BUTTON
            ElevatedButton(
              onPressed: _isSubmitting ? null : _saveSleepData,
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
                      "Save Sleep Record",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
