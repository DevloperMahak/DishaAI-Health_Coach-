import 'package:disha_ai/features/onboarding/data/models/health_nutrition_model.dart';
import 'package:disha_ai/features/onboarding/data/services/health_nutrition_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class HealthNutritionController extends GetxController {
  final HealthNutritionService _service = HealthNutritionService();

  final RxBool isLoading = false.obs;
  final Rxn<HealthLogModel> healthLog = Rxn<HealthLogModel>();
  final Rxn<NutritionSummaryModel> nutritionSummary =
      Rxn<NutritionSummaryModel>();
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();

    debugPrint('');
    debugPrint('══════════════════════════════════════════');
    debugPrint('🩺 [HEALTH CONTROLLER] onInit()');
    debugPrint('══════════════════════════════════════════');

    fetchAllData();
  }

  Future<void> fetchAllData() async {
    debugPrint('');
    debugPrint('🔄 [HEALTH CONTROLLER] fetchAllData() START');

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await Future.wait([fetchHealthLogs(), fetchNutritionSummary()]);

      debugPrint('✅ [HEALTH CONTROLLER] fetchAllData() SUCCESS');
    } catch (e, stackTrace) {
      errorMessage.value = "Failed to load data: $e";

      debugPrint('❌ [HEALTH CONTROLLER] fetchAllData() ERROR: $e');
      debugPrint('📚 StackTrace:\n$stackTrace');
    } finally {
      isLoading.value = false;

      debugPrint('🏁 [HEALTH CONTROLLER] fetchAllData() END');
    }
  }

  Future<void> fetchHealthLogs() async {
    debugPrint('📥 [HEALTH CONTROLLER] fetchHealthLogs() START');

    try {
      final HealthLogModel? result = await _service.getHealthLogs();

      if (result != null) {
        healthLog.value = result;

        debugPrint('✅ [HEALTH CONTROLLER] Health logs received');
        debugPrint('📊 [HEALTH CONTROLLER] Health log: $result');
      } else {
        debugPrint('⚠️ [HEALTH CONTROLLER] getHealthLogs() returned null');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [HEALTH CONTROLLER] fetchHealthLogs ERROR: $e');
      debugPrint('📚 StackTrace:\n$stackTrace');

      rethrow;
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
    debugPrint('');
    debugPrint('📤 [HEALTH CONTROLLER] postHealthMetrics() START');

    debugPrint('steps: $steps');
    debugPrint('sleepHours: $sleepHours');
    debugPrint('caloriesConsumed: $caloriesConsumed');
    debugPrint('caloriesBurned: $caloriesBurned');
    debugPrint('weightKg: $weightKg');
    debugPrint('mood: $mood');
    debugPrint('stressLevel: $stressLevel');

    isLoading.value = true;

    try {
      final HealthLogModel metrics = HealthLogModel(
        steps: steps,
        sleepHours: sleepHours,
        caloriesConsumed: caloriesConsumed,
        caloriesBurned: caloriesBurned,
        weightKg: weightKg,
        mood: mood,
        stressLevel: stressLevel,
      );

      debugPrint('📦 [HEALTH CONTROLLER] Metrics model created: $metrics');

      final bool success = await _service.logHealthMetrics(metrics);

      debugPrint('⬅️ [HEALTH CONTROLLER] logHealthMetrics returned: $success');

      if (success) {
        debugPrint('🔄 [HEALTH CONTROLLER] Refreshing health logs...');

        await fetchHealthLogs();
      }

      return success;
    } catch (e, stackTrace) {
      debugPrint('🔥 [HEALTH CONTROLLER] postHealthMetrics ERROR: $e');
      debugPrint('📚 StackTrace:\n$stackTrace');

      return false;
    } finally {
      isLoading.value = false;

      debugPrint('🏁 [HEALTH CONTROLLER] postHealthMetrics() END');
    }
  }

  Future<bool> updateMetrics(Map<String, dynamic> data) async {
    debugPrint('');
    debugPrint('══════════════════════════════════════════');
    debugPrint('📤 [HEALTH CONTROLLER] updateMetrics()');
    debugPrint('══════════════════════════════════════════');

    debugPrint('📦 Data received from UI: $data');

    isLoading.value = true;

    try {
      debugPrint(
        '➡️ [HEALTH CONTROLLER] Calling '
        'HealthNutritionService.updateHealthMetrics()...',
      );

      final bool success = await _service.updateHealthMetrics(data);

      debugPrint('⬅️ [HEALTH CONTROLLER] Service returned: $success');

      if (success) {
        debugPrint('🔄 [HEALTH CONTROLLER] Update successful.');
        debugPrint('🔄 [HEALTH CONTROLLER] Fetching latest health log...');

        await fetchHealthLogs();

        debugPrint('✅ [HEALTH CONTROLLER] Health log refreshed.');
      } else {
        debugPrint('❌ [HEALTH CONTROLLER] Service returned FALSE.');
      }

      return success;
    } catch (e, stackTrace) {
      debugPrint('🔥 [HEALTH CONTROLLER] updateMetrics ERROR: $e');
      debugPrint('📚 StackTrace:\n$stackTrace');

      errorMessage.value = e.toString();

      return false;
    } finally {
      isLoading.value = false;

      debugPrint('🏁 [HEALTH CONTROLLER] updateMetrics() END');
    }
  }

  Future<bool> deleteMetrics() async {
    debugPrint('🗑️ [HEALTH CONTROLLER] deleteMetrics() START');

    isLoading.value = true;

    try {
      final bool success = await _service.deleteHealthMetrics();

      debugPrint(
        '⬅️ [HEALTH CONTROLLER] deleteHealthMetrics returned: $success',
      );

      if (success) {
        healthLog.value = null;

        debugPrint('✅ [HEALTH CONTROLLER] Local healthLog cleared.');
      }

      return success;
    } catch (e, stackTrace) {
      debugPrint('❌ [HEALTH CONTROLLER] deleteMetrics ERROR: $e');
      debugPrint('📚 StackTrace:\n$stackTrace');

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchNutritionSummary() async {
    debugPrint('🥗 [HEALTH CONTROLLER] fetchNutritionSummary() START');

    try {
      final NutritionSummaryModel? result = await _service
          .getNutritionSummary();

      if (result != null) {
        nutritionSummary.value = result;

        debugPrint('✅ [HEALTH CONTROLLER] Nutrition summary received.');
        debugPrint('📊 Nutrition summary: $result');
      } else {
        debugPrint('⚠️ [HEALTH CONTROLLER] Nutrition summary is null.');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [HEALTH CONTROLLER] fetchNutritionSummary ERROR: $e');
      debugPrint('📚 StackTrace:\n$stackTrace');

      rethrow;
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
    debugPrint('');
    debugPrint('🍽️ [HEALTH CONTROLLER] logMeal()');
    debugPrint('mealType: $mealType');
    debugPrint('foodName: $foodName');
    debugPrint('calories: $calories');
    debugPrint('proteinG: $proteinG');
    debugPrint('carbsG: $carbsG');
    debugPrint('fatG: $fatG');
    debugPrint('servingSize: $servingSize');

    isLoading.value = true;

    try {
      final Map<String, dynamic> mealData = {
        "meal_type": mealType,
        "food_name": foodName,
        "calories": calories,
        "protein_g": proteinG,
        "carbs_g": carbsG,
        "fat_g": fatG,
        "serving_size": servingSize,
      };

      debugPrint('📦 [HEALTH CONTROLLER] Meal payload: $mealData');

      final bool success = await _service.logMealItem(mealData);

      debugPrint('⬅️ [HEALTH CONTROLLER] logMealItem returned: $success');

      if (success) {
        await fetchNutritionSummary();
      }

      return success;
    } catch (e, stackTrace) {
      debugPrint('❌ [HEALTH CONTROLLER] logMeal ERROR: $e');
      debugPrint('📚 StackTrace:\n$stackTrace');

      return false;
    } finally {
      isLoading.value = false;
    }
  }
  // ================= SLEEP =================

  final Rxn<SleepLogModel> sleepLog = Rxn<SleepLogModel>();

  Future<bool> logSleep({required double sleepHours}) async {
    debugPrint('');
    debugPrint('══════════════════════════════════════════');
    debugPrint('🌙 [HEALTH CONTROLLER] logSleep()');
    debugPrint('══════════════════════════════════════════');

    final String date = DateTime.now().toIso8601String().split('T').first;

    debugPrint('📅 Date: $date');
    debugPrint('😴 Sleep hours: $sleepHours');

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final SleepLogModel? result = await _service.logSleep(
        date: date,
        sleepHours: double.parse(sleepHours.toStringAsFixed(2)),
      );

      if (result != null) {
        sleepLog.value = result;

        debugPrint('✅ [HEALTH CONTROLLER] Sleep logged successfully');
        debugPrint('📊 Sleep hours: ${result.sleepHours}');
        debugPrint('⭐ Sleep quality: ${result.sleepQuality}');
        debugPrint('😊 Emoji: ${result.emoji}');

        // Refresh existing health data because sleep may also
        // appear in the health dashboard/history.
        await fetchHealthLogs();

        return true;
      }

      debugPrint('❌ [HEALTH CONTROLLER] Sleep API returned null');

      errorMessage.value = 'Unable to save sleep data.';

      return false;
    } catch (e, stackTrace) {
      debugPrint('🔥 [HEALTH CONTROLLER] logSleep ERROR: $e');
      debugPrint('📚 StackTrace:\n$stackTrace');

      errorMessage.value = e.toString();

      return false;
    } finally {
      isLoading.value = false;

      debugPrint('🏁 [HEALTH CONTROLLER] logSleep() END');
    }
  }
}
