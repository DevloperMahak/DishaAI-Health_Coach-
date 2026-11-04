import 'package:disha_ai/features/dashboard/data/models/mood_checkin_model.dart';
import 'package:disha_ai/features/dashboard/data/services/mood_checkin_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class MoodCheckinController extends GetxController {
  final MoodCheckinService _service = MoodCheckinService();

  // ============================================================
  // STATE
  // ============================================================

  final RxBool isSubmitting = false.obs;

  final RxString selectedMood = ''.obs;

  /// Stress returned by the backend after successful save.
  final RxString calculatedStressLevel = ''.obs;

  final Rxn<MoodCheckinModel> moodCheckin = Rxn<MoodCheckinModel>();

  final RxString errorMessage = ''.obs;

  // ============================================================
  // MOODS
  // ============================================================
  //
  // These exactly match the Mood API document.
  //
  // anxious       -> high
  // overwhelmed   -> high
  // low_sad       -> moderate
  // irritated     -> moderate
  // tired         -> moderate
  // calm          -> low
  // happy         -> low
  // energetic     -> low
  //
  // Stress is NOT sent to backend.
  // Backend calculates it.
  // ============================================================

  final List<Map<String, String>> moods = const [
    {'label': 'Anxious', 'value': 'anxious', 'emoji': '😟'},
    {'label': 'Overwhelmed', 'value': 'overwhelmed', 'emoji': '😵‍💫'},
    {'label': 'Low / Sad', 'value': 'low_sad', 'emoji': '😔'},
    {'label': 'Irritated', 'value': 'irritated', 'emoji': '😤'},
    {'label': 'Tired', 'value': 'tired', 'emoji': '😴'},
    {'label': 'Calm', 'value': 'calm', 'emoji': '🌿'},
    {'label': 'Happy', 'value': 'happy', 'emoji': '😊'},
    {'label': 'Energetic', 'value': 'energetic', 'emoji': '⚡'},
  ];

  // ============================================================
  // SELECT MOOD
  // ============================================================

  void selectMood(String mood) {
    final String normalizedMood = mood.trim().toLowerCase();

    if (normalizedMood.isEmpty) {
      return;
    }

    selectedMood.value = normalizedMood;

    // Clear the previous backend stress result when
    // the user chooses a new mood.
    //
    // This is important because otherwise the UI could
    // continue displaying the stress level belonging to
    // the previously saved mood.
    calculatedStressLevel.value = '';

    errorMessage.value = '';

    debugPrint('');
    debugPrint('🧠 [MOOD CONTROLLER] Mood selected');
    debugPrint('😊 Mood: $normalizedMood');
    debugPrint('🧠 Previous backend stress cleared.');
  }

  // ============================================================
  // SUBMIT MOOD
  // ============================================================

  Future<bool> submitMood() async {
    debugPrint('');
    debugPrint('══════════════════════════════════════════');
    debugPrint('🧠 [MOOD CONTROLLER] submitMood() START');
    debugPrint('══════════════════════════════════════════');

    if (isSubmitting.value) {
      debugPrint('⚠️ [MOOD CONTROLLER] Submission already in progress.');

      return false;
    }

    final String mood = selectedMood.value.trim().toLowerCase();

    if (mood.isEmpty) {
      errorMessage.value = 'Please select your mood.';

      debugPrint('⚠️ [MOOD CONTROLLER] No mood selected.');

      return false;
    }

    isSubmitting.value = true;
    errorMessage.value = '';

    try {
      debugPrint('📤 [MOOD CONTROLLER] Sending mood: $mood');

      debugPrint('📦 Payload will contain: date + mood');

      debugPrint('🚫 Stress level will NOT be sent by Flutter.');

      final MoodCheckinModel result = await _service.submitMood(mood: mood);

      // Store complete backend response.
      moodCheckin.value = result;

      // Backend is the final source of truth.
      selectedMood.value = result.mood;
      calculatedStressLevel.value = result.stressLevel;

      debugPrint('');
      debugPrint('✅ [MOOD CONTROLLER] Mood check-in successful');
      debugPrint('😊 Backend Mood: ${result.mood}');
      debugPrint('🧠 Backend Stress: ${result.stressLevel}');
      debugPrint('══════════════════════════════════════════');

      return true;
    } catch (e, stackTrace) {
      errorMessage.value = _cleanError(e);

      debugPrint('');
      debugPrint('❌ [MOOD CONTROLLER] submitMood ERROR');
      debugPrint('Error: $e');
      debugPrint('StackTrace:\n$stackTrace');
      debugPrint('══════════════════════════════════════════');

      return false;
    } finally {
      isSubmitting.value = false;

      debugPrint('🏁 [MOOD CONTROLLER] submitMood() END');
    }
  }

  // ============================================================
  // CLEAR CHECK-IN
  // ============================================================

  void clearCheckin() {
    selectedMood.value = '';
    calculatedStressLevel.value = '';
    moodCheckin.value = null;
    errorMessage.value = '';

    debugPrint('🧹 [MOOD CONTROLLER] Check-in state cleared.');
  }

  // ============================================================
  // ERROR CLEANUP
  // ============================================================

  String _cleanError(Object error) {
    String message = error.toString();

    if (message.startsWith('Exception: ')) {
      message = message.substring('Exception: '.length);
    }

    return message.trim().isEmpty
        ? 'Unable to save mood check-in. Please try again.'
        : message.trim();
  }
}
