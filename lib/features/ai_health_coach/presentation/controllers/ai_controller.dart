import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/models/ai_response_model.dart';
import '../../data/services/ai_service.dart';

class AiController extends GetxController {
  final AiService _service = AiService();

  // ============================================================
  // STATE: LOADING BOOLEANS
  // ============================================================

  final RxBool isChatLoading = false.obs;
  final RxBool isHistoryLoading = false.obs;
  final RxBool isClearingChat = false.obs;
  final RxBool isProfileAnalyzing = false.obs;
  final RxBool isFoodScanning = false.obs;
  final RxBool isVitalsAnalyzing = false.obs;
  final RxBool isLabAnalyzing = false.obs;
  final RxBool isRecommending = false.obs;
  final RxBool isGeneratingPlan = false.obs;
  final RxBool isCheckingSymptoms = false.obs;
  final RxBool isExplainingReport = false.obs;
  final RxBool isMedicineUploading = false.obs;
  final RxBool isLoggingFood = false.obs;
  final RxBool isSchedulingCheckin = false.obs;
  final RxBool isFetchingSchedule = false.obs;
  final RxBool isLoadingLogs = false.obs;
  final RxBool isDeletingFoodLog = false.obs;

  // ============================================================
  // RHEA AI VOICE CALL STATE
  // ============================================================

  final RxBool isStartingVoiceSession = false.obs;
  final RxBool isSendingVoiceMessage = false.obs;
  final RxBool isEndingVoiceSession = false.obs;

  final RxString voiceSessionId = ''.obs;
  final RxString voiceGreeting = ''.obs;
  final RxString voiceLanguage = ''.obs;
  final RxString voiceStatus = ''.obs;

  final RxString voiceUserName = ''.obs;

  final RxString lastVoiceUserText = ''.obs;
  final RxString lastVoiceReply = ''.obs;

  final RxInt voiceTurnNumber = 0.obs;

  // ------------------------------------------------------------
  // VOICE AUDIO URLS
  //
  // voiceGreetingAudioUrl:
  // Audio returned when a new voice session starts.
  //
  // voiceAudioUrl:
  // Current audio to play.
  // Initially greeting audio, then each AI reply audio.
  // ------------------------------------------------------------

  final RxString voiceGreetingAudioUrl = ''.obs;
  final RxString voiceAudioUrl = ''.obs;

  // Whether the backend returned an audio URL.
  final RxBool hasVoiceAudio = false.obs;

  final Rxn<AiResponseModel> voiceStartResponse = Rxn<AiResponseModel>();

  final Rxn<AiResponseModel> voiceMessageResponse = Rxn<AiResponseModel>();

  final Rxn<AiResponseModel> voiceEndResponse = Rxn<AiResponseModel>();

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  final RxString errorMessage = ''.obs;

  // ============================================================
  // STATE: API RESPONSES
  // ============================================================

  final Rxn<AiResponseModel> chatResponse = Rxn<AiResponseModel>();

  final Rxn<AiResponseModel> chatHistory = Rxn<AiResponseModel>();

  final Rxn<AiResponseModel> profileAnalysis = Rxn<AiResponseModel>();

  final Rxn<AiResponseModel> foodAnalysis = Rxn<AiResponseModel>();

  final Rxn<AiResponseModel> vitalsAnalysis = Rxn<AiResponseModel>();

  final Rxn<AiResponseModel> labAnalysis = Rxn<AiResponseModel>();

  final Rxn<AiResponseModel> recommendations = Rxn<AiResponseModel>();

  final Rxn<AiResponseModel> healthPlan = Rxn<AiResponseModel>();

  final Rxn<AiResponseModel> symptomAnalysis = Rxn<AiResponseModel>();

  final Rxn<AiResponseModel> reportExplanation = Rxn<AiResponseModel>();

  final Rxn<AiResponseModel> medicineResponse = Rxn<AiResponseModel>();

  final Rxn<AiResponseModel> foodLogResponse = Rxn<AiResponseModel>();

  final Rxn<AiResponseModel> checkinScheduleResponse = Rxn<AiResponseModel>();

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
  // RHEA AI VOICE - START SESSION
  //
  // POST /api/rhea-ai/voice/start
  // ============================================================

  Future<bool> startVoiceSession() async {
    if (isStartingVoiceSession.value) {
      debugPrint('RHEA VOICE: Session start already in progress.');
      return false;
    }

    try {
      isStartingVoiceSession.value = true;
      errorMessage.value = '';

      // --------------------------------------------------------
      // CLEAR PREVIOUS VOICE SESSION STATE
      // --------------------------------------------------------

      resetVoiceSession();

      // --------------------------------------------------------
      // CALL BACKEND
      // --------------------------------------------------------

      final result = await _service.startVoiceSession();

      voiceStartResponse.value = result;

      // --------------------------------------------------------
      // READ RESPONSE DATA
      // --------------------------------------------------------

      final data = result.data;

      if (data is! Map) {
        throw Exception('Invalid voice start response.');
      }

      final map = Map<String, dynamic>.from(data);

      // --------------------------------------------------------
      // SESSION DETAILS
      // --------------------------------------------------------

      voiceSessionId.value = map['session_id']?.toString() ?? '';

      voiceGreeting.value = map['greeting']?.toString() ?? '';

      voiceLanguage.value = map['language']?.toString() ?? '';

      voiceStatus.value = map['status']?.toString() ?? '';

      // --------------------------------------------------------
      // GREETING AUDIO URL
      //
      // Backend response:
      //
      // greeting_audio_url
      // audio_url
      //
      // Prefer greeting_audio_url.
      // --------------------------------------------------------

      voiceGreetingAudioUrl.value = _readAudioUrl(map['greeting_audio_url']);

      if (voiceGreetingAudioUrl.value.isEmpty) {
        voiceGreetingAudioUrl.value = _readAudioUrl(map['audio_url']);
      }

      // Set current playable audio to greeting.
      voiceAudioUrl.value = voiceGreetingAudioUrl.value;

      hasVoiceAudio.value = voiceAudioUrl.value.isNotEmpty;

      // --------------------------------------------------------
      // USER DETAILS
      // --------------------------------------------------------

      final user = map['user'];

      if (user is Map) {
        final userMap = Map<String, dynamic>.from(user);

        voiceUserName.value = userMap['name']?.toString() ?? '';
      }

      // --------------------------------------------------------
      // VALIDATE SESSION ID
      // --------------------------------------------------------

      if (voiceSessionId.value.trim().isEmpty) {
        throw Exception(
          'Rhea voice session was started but no session ID was returned.',
        );
      }

      // --------------------------------------------------------
      // DEBUG LOGS
      // --------------------------------------------------------

      debugPrint('==========================================');

      debugPrint('RHEA VOICE SESSION STARTED');

      debugPrint('SESSION ID: ${voiceSessionId.value}');

      debugPrint('GREETING: ${voiceGreeting.value}');

      debugPrint('LANGUAGE: ${voiceLanguage.value}');

      debugPrint('STATUS: ${voiceStatus.value}');

      debugPrint('USER: ${voiceUserName.value}');

      debugPrint(
        'GREETING AUDIO URL: '
        '${voiceGreetingAudioUrl.value}',
      );

      debugPrint(
        'HAS GREETING AUDIO: '
        '${hasVoiceAudio.value}',
      );

      debugPrint('==========================================');

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);

      debugPrint(
        'RHEA VOICE START ERROR: '
        '${errorMessage.value}',
      );

      return false;
    } finally {
      isStartingVoiceSession.value = false;
    }
  }

  // ============================================================
  // RHEA AI VOICE - SEND TEXT
  //
  // POST /api/rhea-ai/voice/message
  //
  // Includes:
  // - Duplicate request protection
  // - API response timing
  // - Reply text
  // - Backend-generated audio URL
  // ============================================================

  Future<bool> sendVoiceText(String message) async {
    final cleanedMessage = message.trim();

    if (voiceSessionId.value.trim().isEmpty) {
      errorMessage.value = 'No active Rhea voice session.';
      return false;
    }

    if (cleanedMessage.isEmpty) {
      errorMessage.value = 'Voice message is empty.';
      return false;
    }

    if (isSendingVoiceMessage.value) {
      debugPrint('RHEA VOICE: Request already in progress.');
      return false;
    }

    final stopwatch = Stopwatch()..start();

    try {
      isSendingVoiceMessage.value = true;
      errorMessage.value = '';

      // Clear previous reply audio before requesting
      // a new AI response.
      voiceAudioUrl.value = '';
      hasVoiceAudio.value = false;

      debugPrint('==========================================');

      debugPrint('RHEA VOICE REQUEST STARTED');

      debugPrint('MESSAGE: $cleanedMessage');

      debugPrint('==========================================');

      // --------------------------------------------------------
      // CALL BACKEND
      // --------------------------------------------------------

      final result = await _service.sendVoiceText(
        sessionId: voiceSessionId.value,
        message: cleanedMessage,
      );

      debugPrint(
        'RHEA API RESPONSE TIME: '
        '${stopwatch.elapsedMilliseconds} ms',
      );

      // --------------------------------------------------------
      // VALIDATE RESPONSE
      // --------------------------------------------------------

      final data = result.data;

      if (data is! Map) {
        throw Exception('Invalid voice message response.');
      }

      final map = Map<String, dynamic>.from(data);

      final reply = map['reply_text']?.toString().trim() ?? '';

      if (reply.isEmpty) {
        throw Exception('Rhea returned an empty voice response.');
      }

      // --------------------------------------------------------
      // UPDATE RESPONSE STATE
      // --------------------------------------------------------

      voiceMessageResponse.value = result;

      lastVoiceUserText.value =
          map['transcribed_text']?.toString() ?? cleanedMessage;

      lastVoiceReply.value = reply;

      voiceTurnNumber.value =
          int.tryParse(map['turn_number']?.toString() ?? '0') ?? 0;

      // --------------------------------------------------------
      // AI REPLY AUDIO URL
      // --------------------------------------------------------

      voiceAudioUrl.value = _readAudioUrl(map['audio_url']);

      hasVoiceAudio.value = voiceAudioUrl.value.isNotEmpty;

      // --------------------------------------------------------
      // DEBUG LOGS
      // --------------------------------------------------------

      debugPrint(
        'RHEA VOICE TURN: '
        '${voiceTurnNumber.value}',
      );

      debugPrint('RHEA REPLY: $reply');

      debugPrint(
        'RHEA REPLY AUDIO URL: '
        '${voiceAudioUrl.value}',
      );

      debugPrint(
        'RHEA HAS AUDIO: '
        '${hasVoiceAudio.value}',
      );

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);

      debugPrint(
        'RHEA VOICE MESSAGE ERROR: '
        '${errorMessage.value}',
      );

      return false;
    } finally {
      stopwatch.stop();

      debugPrint(
        'RHEA VOICE REQUEST TOTAL: '
        '${stopwatch.elapsedMilliseconds} ms',
      );

      isSendingVoiceMessage.value = false;
    }
  }

  // ============================================================
  // RHEA AI VOICE - SEND AUDIO
  //
  // POST /api/rhea-ai/voice/message
  //
  // multipart/form-data
  // ============================================================

  Future<bool> sendVoiceAudio(File audioFile) async {
    if (voiceSessionId.value.trim().isEmpty) {
      errorMessage.value = 'No active Rhea voice session.';
      return false;
    }

    if (isSendingVoiceMessage.value) {
      debugPrint('RHEA VOICE: Audio request already in progress.');
      return false;
    }

    try {
      isSendingVoiceMessage.value = true;
      errorMessage.value = '';

      voiceAudioUrl.value = '';
      hasVoiceAudio.value = false;

      // --------------------------------------------------------
      // CALL BACKEND
      // --------------------------------------------------------

      final result = await _service.sendVoiceAudio(
        sessionId: voiceSessionId.value,
        audioFile: audioFile,
      );

      // --------------------------------------------------------
      // VALIDATE RESPONSE
      // --------------------------------------------------------

      final data = result.data;

      if (data is! Map) {
        throw Exception('Invalid voice audio response.');
      }

      final map = Map<String, dynamic>.from(data);

      // --------------------------------------------------------
      // UPDATE RESPONSE STATE
      // --------------------------------------------------------

      voiceMessageResponse.value = result;

      lastVoiceUserText.value = map['transcribed_text']?.toString() ?? '';

      lastVoiceReply.value = map['reply_text']?.toString() ?? '';

      voiceTurnNumber.value =
          int.tryParse(map['turn_number']?.toString() ?? '0') ?? 0;

      // --------------------------------------------------------
      // BACKEND AUDIO
      // --------------------------------------------------------

      voiceAudioUrl.value = _readAudioUrl(map['audio_url']);

      hasVoiceAudio.value = voiceAudioUrl.value.isNotEmpty;

      // --------------------------------------------------------
      // DEBUG LOGS
      // --------------------------------------------------------

      debugPrint('RHEA AUDIO MESSAGE PROCESSED');

      debugPrint('RHEA REPLY: ${lastVoiceReply.value}');

      debugPrint('RHEA AUDIO URL: ${voiceAudioUrl.value}');

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);

      debugPrint(
        'RHEA VOICE AUDIO ERROR: '
        '${errorMessage.value}',
      );

      return false;
    } finally {
      isSendingVoiceMessage.value = false;
    }
  }

  // ============================================================
  // RHEA AI VOICE - END SESSION
  //
  // POST /api/rhea-ai/voice/end
  // ============================================================

  Future<bool> endVoiceSession() async {
    try {
      if (voiceSessionId.value.trim().isEmpty) {
        return true;
      }

      if (isEndingVoiceSession.value) {
        debugPrint('RHEA VOICE: End request already in progress.');
        return false;
      }

      isEndingVoiceSession.value = true;
      errorMessage.value = '';

      // --------------------------------------------------------
      // CALL BACKEND
      // --------------------------------------------------------

      final result = await _service.endVoiceSession(
        sessionId: voiceSessionId.value,
      );

      voiceEndResponse.value = result;

      voiceStatus.value = 'ended';

      debugPrint(
        'RHEA VOICE SESSION ENDED: '
        '${voiceSessionId.value}',
      );

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);

      debugPrint(
        'RHEA VOICE END ERROR: '
        '${errorMessage.value}',
      );

      return false;
    } finally {
      isEndingVoiceSession.value = false;
    }
  }

  // ============================================================
  // RESET RHEA VOICE STATE
  // ============================================================

  void resetVoiceSession() {
    voiceSessionId.value = '';
    voiceGreeting.value = '';
    voiceLanguage.value = '';
    voiceStatus.value = '';

    voiceUserName.value = '';

    lastVoiceUserText.value = '';
    lastVoiceReply.value = '';

    voiceTurnNumber.value = 0;

    voiceGreetingAudioUrl.value = '';
    voiceAudioUrl.value = '';

    hasVoiceAudio.value = false;

    voiceStartResponse.value = null;
    voiceMessageResponse.value = null;
    voiceEndResponse.value = null;
  }

  // ============================================================
  // HELPER: READ VALID AUDIO URL
  //
  // Handles:
  // - null
  // - empty string
  // - "null" string
  // - invalid URLs
  //
  // Accepts HTTPS URLs only.
  // ============================================================

  String _readAudioUrl(dynamic value) {
    if (value == null) {
      return '';
    }

    final url = value.toString().trim();

    if (url.isEmpty || url.toLowerCase() == 'null') {
      return '';
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty) {
      debugPrint('RHEA: Invalid audio URL received: $url');
      return '';
    }

    return url;
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
  // 3B. SEARCH FOOD BY NAME
  // ============================================================

  Future<bool> searchFoodByName(String foodName) async {
    try {
      isFoodScanning.value = true;
      errorMessage.value = '';

      final result = await _service.searchFoodByName(foodName);

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
  // 3C. LOG FOOD
  // POST /api/food-log
  // ============================================================

  Future<bool> logFood({
    required String foodName,
    required String mealType,
    required int calories,
    required num protein,
    required num carbs,
    required num fat,
    required String servingSize,
    required String date,
    String? imageUrl,
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
        imageUrl: imageUrl,
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
  //
  // POST /api/ai/analyze-labs
  // ============================================================

  Future<bool> analyzeLabReport({
    required File reportFile,
    String? labName,
    String? reportDate,
    String? notes,
  }) async {
    try {
      isLabAnalyzing.value = true;
      errorMessage.value = '';

      final result = await _service.analyzeLabReport(
        reportFile: reportFile,
        labName: labName,
        reportDate: reportDate,
        notes: notes,
      );

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
  // 5B. ADD MEDICINE / PRESCRIPTION
  // ============================================================

  Future<bool> addMedicine({
    File? attachment,
    String? name,
    String? dosage,
    String? frequency,
    String? instructions,
  }) async {
    try {
      isMedicineUploading.value = true;
      errorMessage.value = '';

      final result = await _service.addMedicine(
        attachment: attachment,
        name: name,
        dosage: dosage,
        frequency: frequency,
        instructions: instructions,
      );

      medicineResponse.value = result;

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isMedicineUploading.value = false;
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
  // 10. SCHEDULE AI CHECK-IN
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
  // 11. GET AI CHECK-IN SCHEDULE
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

  // ============================================================
  // DELETE LOGGED FOOD ITEM
  // ============================================================

  Future<bool> deleteFoodLog(int id) async {
    try {
      isDeletingFoodLog.value = true;
      errorMessage.value = '';

      final result = await _service.deleteFoodLog(id);

      if (result.data != null && result.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = result.data as Map<String, dynamic>;

        todayTotalCalories.value =
            data['total_calories'] ?? todayTotalCalories.value;

        targetCalories.value = data['target_calories'] ?? targetCalories.value;

        if (data['calorie_percentage'] != null) {
          calorieProgressPercentage.value =
              ((data['calorie_percentage'] as num).toDouble()) / 100.0;
        }

        if (data['macros'] != null) {
          totalProteinG.value = (data['macros']['protein_g'] ?? 0.0).toDouble();

          totalCarbsG.value = (data['macros']['carbs_g'] ?? 0.0).toDouble();

          totalFatG.value = (data['macros']['fat_g'] ?? 0.0).toDouble();
        }

        todayLoggedMeals.removeWhere((item) => item['id'] == id);
      } else {
        await fetchTodayLogs();
      }

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isDeletingFoodLog.value = false;
    }
  }

  // ============================================================
  // 12. FETCH TODAY'S LOGGED MEALS & PROGRESS
  // ============================================================

  final RxList<dynamic> breakfastList = <dynamic>[].obs;

  final RxList<dynamic> lunchList = <dynamic>[].obs;

  final RxList<dynamic> dinnerList = <dynamic>[].obs;

  final RxList<dynamic> snacksList = <dynamic>[].obs;

  final RxList<dynamic> todayLoggedMeals = <dynamic>[].obs;

  // ------------------------------------------------------------
  // DAILY PROGRESS
  // ------------------------------------------------------------

  final RxInt todayTotalCalories = 0.obs;
  final RxInt targetCalories = 2000.obs;

  final RxDouble totalProteinG = 0.0.obs;
  final RxDouble totalCarbsG = 0.0.obs;
  final RxDouble totalFatG = 0.0.obs;

  final RxDouble calorieProgressPercentage = 0.0.obs;

  Future<bool> fetchTodayLogs() async {
    try {
      isLoadingLogs.value = true;
      errorMessage.value = '';

      final String todayDate = DateTime.now().toIso8601String().split('T')[0];

      final result = await _service.getFoodLogs(date: todayDate);

      if (result.data != null) {
        final Map<String, dynamic> data = result.data is Map
            ? Map<String, dynamic>.from(result.data)
            : <String, dynamic>{};

        // ------------------------------------------------------
        // CATEGORIZED MEALS
        // ------------------------------------------------------

        if (data['meals'] != null) {
          breakfastList.value = data['meals']['breakfast'] ?? [];

          lunchList.value = data['meals']['lunch'] ?? [];

          dinnerList.value = data['meals']['dinner'] ?? [];

          snacksList.value = data['meals']['snack'] ?? [];
        }

        // ------------------------------------------------------
        // DAILY CALORIE PROGRESS
        // ------------------------------------------------------

        todayLoggedMeals.value =
            data['todayLoggedMeals'] ?? data['all_logged_meals'] ?? [];

        todayTotalCalories.value = data['total_calories'] ?? 0;

        targetCalories.value = data['target_calories'] ?? 2000;

        calorieProgressPercentage.value =
            (data['calorie_percentage'] ?? 0.0) / 100.0;

        // ------------------------------------------------------
        // MACRONUTRIENTS
        // ------------------------------------------------------

        if (data['macros'] != null) {
          totalProteinG.value = (data['macros']['protein_g'] ?? 0.0).toDouble();

          totalCarbsG.value = (data['macros']['carbs_g'] ?? 0.0).toDouble();

          totalFatG.value = (data['macros']['fat_g'] ?? 0.0).toDouble();
        }
      }

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isLoadingLogs.value = false;
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
}
