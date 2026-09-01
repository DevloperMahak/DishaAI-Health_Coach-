import 'package:disha_ai/features/onboarding/data/models/health_nutrition_model.dart';
import 'package:disha_ai/features/onboarding/data/services/health_nutrition_service.dart';
import 'package:get/get.dart';

class HealthNutritionController extends GetxController {
  final HealthNutritionService _service = HealthNutritionService();

  var isLoading = false.obs;
  var healthLog = Rxn<HealthLogModel>();
  var nutritionSummary = Rxn<NutritionSummaryModel>();
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await Future.wait([fetchHealthLogs(), fetchNutritionSummary()]);
    } catch (e) {
      errorMessage.value = "Failed to load data: $e";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchHealthLogs() async {
    final result = await _service.getHealthLogs();
    if (result != null) {
      healthLog.value = result;
    }
  }

  Future<bool> postHealthMetrics({
    required int steps,
    required double sleepHours,
    required int caloriesConsumed,
    required int caloriesBurned,
    required double weightKg,
    required String mood,
    required String stressLevel,
  }) async {
    isLoading.value = true;
    final metrics = HealthLogModel(
      steps: steps,
      sleepHours: sleepHours,
      caloriesConsumed: caloriesConsumed,
      caloriesBurned: caloriesBurned,
      weightKg: weightKg,
      mood: mood,
      stressLevel: stressLevel,
    );

    final success = await _service.logHealthMetrics(metrics);
    if (success) {
      await fetchHealthLogs();
    }
    isLoading.value = false;
    return success;
  }

  Future<bool> updateMetrics(Map<String, dynamic> data) async {
    isLoading.value = true;
    final success = await _service.updateHealthMetrics(data);
    if (success) {
      await fetchHealthLogs();
    }
    isLoading.value = false;
    return success;
  }

  Future<bool> deleteMetrics() async {
    isLoading.value = true;
    final success = await _service.deleteHealthMetrics();
    if (success) {
      healthLog.value = null;
    }
    isLoading.value = false;
    return success;
  }

  Future<void> fetchNutritionSummary() async {
    final result = await _service.getNutritionSummary();
    if (result != null) {
      nutritionSummary.value = result;
    }
  }

  Future<bool> logMeal({
    required String mealType,
    required String foodName,
    required int calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required String servingSize,
  }) async {
    isLoading.value = true;
    final mealData = {
      "meal_type": mealType,
      "food_name": foodName,
      "calories": calories,
      "protein_g": proteinG,
      "carbs_g": carbsG,
      "fat_g": fatG,
      "serving_size": servingSize,
    };

    final success = await _service.logMealItem(mealData);
    if (success) {
      await fetchNutritionSummary();
    }
    isLoading.value = false;
    return success;
  }
}
