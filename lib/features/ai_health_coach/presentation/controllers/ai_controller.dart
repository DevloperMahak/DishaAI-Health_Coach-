import 'dart:io';
import 'package:get/get.dart';

import '../../data/models/ai_response_model.dart';
import '../../data/services/ai_service.dart';

class AiController extends GetxController {
  final AiService _service = AiService();

  // ============================================================
  // STATE: LOADING BOOLEANS
  // ============================================================
  final RxBool isChatLoading = false.obs;
  final RxBool isHistoryLoading = false.obs; // <-- ADDED
  final RxBool isClearingChat = false.obs; // <-- ADDED
  final RxBool isProfileAnalyzing = false.obs;
  final RxBool isFoodScanning = false.obs;
  final RxBool isVitalsAnalyzing = false.obs;
  final RxBool isLabAnalyzing = false.obs;
  final RxBool isRecommending = false.obs;
  final RxBool isGeneratingPlan = false.obs;
  final RxBool isCheckingSymptoms = false.obs;
  final RxBool isExplainingReport = false.obs;

  // Error Message
  final RxString errorMessage = ''.obs;

  // ============================================================
  // STATE: API RESPONSES
  // ============================================================
  final Rxn<AiResponseModel> chatResponse = Rxn<AiResponseModel>();
  final Rxn<AiResponseModel> chatHistory = Rxn<AiResponseModel>(); // <-- ADDED
  final Rxn<AiResponseModel> profileAnalysis = Rxn<AiResponseModel>();
  final Rxn<AiResponseModel> foodAnalysis = Rxn<AiResponseModel>();
  final Rxn<AiResponseModel> vitalsAnalysis = Rxn<AiResponseModel>();
  final Rxn<AiResponseModel> labAnalysis = Rxn<AiResponseModel>();
  final Rxn<AiResponseModel> recommendations = Rxn<AiResponseModel>();
  final Rxn<AiResponseModel> healthPlan = Rxn<AiResponseModel>();
  final Rxn<AiResponseModel> symptomAnalysis = Rxn<AiResponseModel>();
  final Rxn<AiResponseModel> reportExplanation = Rxn<AiResponseModel>();

  // ============================================================
  // 1. AI HEALTH COACH CHAT
  // ============================================================
  Future<bool> sendChatMessage(String message) async {
    try {
      isChatLoading.value = true;
      errorMessage.value = '';
      final result = await _service.sendChatMessage(message);
      chatResponse.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isChatLoading.value = false;
    }
  }

  // ============================================================
  // 1B. GET CHAT HISTORY
  // ============================================================
  Future<bool> getChatHistory() async {
    try {
      isHistoryLoading.value = true;
      errorMessage.value = '';
      final result = await _service.getChatHistory();
      chatHistory.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isHistoryLoading.value = false;
    }
  }

  // ============================================================
  // 1C. CLEAR CHAT HISTORY
  // ============================================================
  Future<bool> clearChatHistory() async {
    try {
      isClearingChat.value = true;
      errorMessage.value = '';
      await _service.clearChatHistory();

      // Clear the local state on success
      chatHistory.value = null;
      chatResponse.value = null;

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isClearingChat.value = false;
    }
  }

  // ============================================================
  // 2. AI PROFILE ANALYZER
  // ============================================================
  Future<bool> analyzeProfile() async {
    try {
      isProfileAnalyzing.value = true;
      errorMessage.value = '';
      final result = await _service.analyzeProfile();
      profileAnalysis.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isProfileAnalyzing.value = false;
    }
  }

  // ============================================================
  // 3. AI SCAN FOOD IMAGE
  // ============================================================
  Future<bool> scanFoodImage(File imageFile) async {
    try {
      isFoodScanning.value = true;
      errorMessage.value = '';
      final result = await _service.scanFoodImage(imageFile);
      foodAnalysis.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isFoodScanning.value = false;
    }
  }

  // ============================================================
  // 14. LOG FOOD (NEW ADDITION)
  // ============================================================
  final RxBool isLoggingFood = false.obs;
  final Rxn<AiResponseModel> foodLogResponse = Rxn<AiResponseModel>();

  Future<bool> logFood({
    required String foodName,
    required String mealType,
    required num calories,
    required num protein,
    required num carbs,
    required num fat,
    required String servingSize,
    required String date,
    String? masterFoodId,
    required bool isVerified,
  }) async {
    try {
      isLoggingFood.value = true;
      errorMessage.value = '';
      final result = await _service.logFood(
        foodName: foodName,
        mealType: mealType,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        servingSize: servingSize,
        date: date,
        masterFoodId: masterFoodId,
        isVerified: isVerified,
      );
      foodLogResponse.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isLoggingFood.value = false;
    }
  }

  // ============================================================
  // 4. AI VITALS ANALYSIS
  // ============================================================
  Future<bool> analyzeVitals() async {
    try {
      isVitalsAnalyzing.value = true;
      errorMessage.value = '';
      final result = await _service.analyzeVitals();
      vitalsAnalysis.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isVitalsAnalyzing.value = false;
    }
  }

  // ============================================================
  // 5. AI LAB REPORT ANALYZER
  // ============================================================
  Future<bool> analyzeLabReport() async {
    try {
      isLabAnalyzing.value = true;
      errorMessage.value = '';
      final result = await _service.analyzeLabReport();
      labAnalysis.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isLabAnalyzing.value = false;
    }
  }

  // ============================================================
  // 6. AI DAILY RECOMMENDATIONS
  // ============================================================
  Future<bool> getRecommendations() async {
    try {
      isRecommending.value = true;
      errorMessage.value = '';
      final result = await _service.getRecommendations();
      recommendations.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isRecommending.value = false;
    }
  }

  // ============================================================
  // 7. AI GENERATE HEALTH PLAN
  // ============================================================
  Future<bool> generateHealthPlan() async {
    try {
      isGeneratingPlan.value = true;
      errorMessage.value = '';
      final result = await _service.generateHealthPlan();
      healthPlan.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isGeneratingPlan.value = false;
    }
  }

  // ============================================================
  // 8. AI SYMPTOM CHECKER
  // ============================================================
  Future<bool> checkSymptoms(String symptoms) async {
    try {
      isCheckingSymptoms.value = true;
      errorMessage.value = '';
      final result = await _service.checkSymptoms(symptoms);
      symptomAnalysis.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isCheckingSymptoms.value = false;
    }
  }

  // ============================================================
  // 9. AI EXPLAIN MEDICAL REPORT
  // ============================================================
  Future<bool> explainMedicalReport(String reportSummary) async {
    try {
      isExplainingReport.value = true;
      errorMessage.value = '';
      final result = await _service.explainMedicalReport(reportSummary);
      reportExplanation.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isExplainingReport.value = false;
    }
  }

  // ============================================================
  // HELPER: CLEAN ERROR MESSAGE
  // ============================================================
  String _cleanError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  // --- ADD TO LOADING STATES ---
  final RxBool isSchedulingCheckin = false.obs;
  final RxBool isFetchingSchedule = false.obs;

  // --- ADD TO RESPONSE VARIABLES ---
  final Rxn<AiResponseModel> checkinScheduleResponse = Rxn<AiResponseModel>();

  // ============================================================
  // 12. SCHEDULE AI CHECK-IN
  // ============================================================
  Future<bool> scheduleCheckin({
    required String time,
    required List<String> days,
  }) async {
    try {
      isSchedulingCheckin.value = true;
      errorMessage.value = '';
      final result = await _service.scheduleCheckin(time: time, days: days);
      checkinScheduleResponse.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isSchedulingCheckin.value = false;
    }
  }

  // ============================================================
  // 13. GET AI CHECK-IN SCHEDULE
  // ============================================================
  Future<bool> getCheckinSchedule() async {
    try {
      isFetchingSchedule.value = true;
      errorMessage.value = '';
      final result = await _service.getCheckinSchedule();
      checkinScheduleResponse.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isFetchingSchedule.value = false;
    }
  }
}
