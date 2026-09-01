import 'package:get/get.dart';

import '../../data/models/health_profile_model.dart';
import '../../data/services/health_profile_service.dart';

class HealthProfileController extends GetxController {
  final HealthProfileService _service = HealthProfileService();

  // ============================================================
  // STATE
  // ============================================================

  /// Complete health profile returned by the API.
  final Rxn<HealthProfileModel> healthProfile = Rxn<HealthProfileModel>();

  /// Loading state for GET profile.
  final RxBool isLoading = false.obs;

  /// Saving state for POST / PUT profile.
  final RxBool isSaving = false.obs;

  /// Error message from API/service.
  final RxString errorMessage = ''.obs;

  /// Selected health goals during onboarding.
  final RxList<String> selectedGoals = <String>[].obs;

  /// Selected challenges during onboarding.
  final RxList<String> selectedChallenges = <String>[].obs;

  /// Sleep quality selection.
  final RxString sleepQuality = 'good'.obs;

  /// Set the primary health goal.
  void setPrimaryHealthGoal(String goal) {
    selectedGoals
      ..clear()
      ..add(goal);
  }

  /// Get the currently selected primary goal.
  String? get primaryHealthGoal {
    if (selectedGoals.isEmpty) {
      return null;
    }
    return selectedGoals.first;
  }

  // ============================================================
  // SAVE HEALTH PROFILE
  // POST /user/health-profile
  // ============================================================

  Future<bool> saveHealthProfile({
    required String name,
    String? email,
    String? mobile,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required double targetWeightKg,
    required String activityLevel,
    required double sleepHoursTarget,
    required String stressLevel,
    required List<String> goals,
    required List<String> conditions,
    required String dietType,
    List<String> allergies = const [],
    List<String> avoidedFoods = const [],
    List<String> challenges = const [],
    String sleepQuality = 'good',
  }) async {
    try {
      isSaving.value = true;
      errorMessage.value = '';

      final profile = HealthProfileModel(
        name: name,
        email: email, // <-- Integrated email
        mobile: mobile, // <-- Integrated mobile
        age: age,
        gender: gender,
        heightCm: heightCm,
        weightKg: weightKg,
        targetWeightKg: targetWeightKg,
        activityLevel: activityLevel,
        sleepHoursTarget: sleepHoursTarget,
        stressLevel: stressLevel,
        goals: goals,
        conditions: conditions,
        dietType: dietType,
        allergies: allergies,
        avoidedFoods: avoidedFoods,
        challenges: challenges,
        sleepQuality: sleepQuality,
      );

      final result = await _service.saveHealthProfile(profile);

      healthProfile.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================
  // GET HEALTH PROFILE
  // GET /user/health-profile
  // ============================================================
  Future<bool> getHealthProfile() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _service.getHealthProfile();

      healthProfile.value = result;

      selectedGoals
        ..clear()
        ..addAll(result.goals);

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // UPDATE HEALTH PROFILE
  // PUT /user/health-profile
  // ============================================================

  Future<bool> updateHealthProfile({
    required String name,
    String? email,
    String? mobile,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required double targetWeightKg,
    required String activityLevel,
    required double sleepHoursTarget,
    required String stressLevel,
    required List<String> goals,
    required List<String> conditions,
    required String dietType,
    List<String> allergies = const [],
    List<String> avoidedFoods = const [],
    List<String> challenges = const [],
    String sleepQuality = 'good',
  }) async {
    try {
      isSaving.value = true;
      errorMessage.value = '';

      final profile = HealthProfileModel(
        name: name,
        email: email, // <-- Integrated email
        mobile: mobile, // <-- Integrated mobile
        age: age,
        gender: gender,
        heightCm: heightCm,
        weightKg: weightKg,
        targetWeightKg: targetWeightKg,
        activityLevel: activityLevel,
        sleepHoursTarget: sleepHoursTarget,
        stressLevel: stressLevel,
        goals: goals,
        conditions: conditions,
        dietType: dietType,
        allergies: allergies,
        avoidedFoods: avoidedFoods,
        challenges: challenges,
        sleepQuality: sleepQuality,
      );

      final result = await _service.updateHealthProfile(profile);

      healthProfile.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================
  // SAVE PERSONAL INFORMATION
  // ============================================================

  Future<bool> savePersonalInfo({
    required String name,
    required String email,
    String? mobile, // <-- Integrated mobile
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
  }) async {
    try {
      isSaving.value = true;
      errorMessage.value = '';

      final payload = {
        'name': name,
        'email': email,
        'age': age,
        'gender': gender.toLowerCase(),
        'height_cm': heightCm,
        'weight_kg': weightKg,
      };

      // Conditionally append mobile if provided so it doesn't send null accidentally
      if (mobile != null && mobile.trim().isNotEmpty) {
        payload['mobile'] = mobile;
      }

      final result = await _service.updateOnboardingProfile(payload);

      healthProfile.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================
  // CLEAR PROFILE
  // ============================================================

  void clearProfile() {
    healthProfile.value = null;
    errorMessage.value = '';
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  String _cleanError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  // ============================================================
  // SAVE PRIMARY HEALTH GOAL
  // ============================================================

  Future<bool> savePrimaryHealthGoal({required String goal}) async {
    try {
      isSaving.value = true;
      errorMessage.value = '';

      final profile = HealthProfileModel(
        goals: [goal],
        conditions: const [],
        allergies: const [],
        avoidedFoods: const [],
      );

      final result = await _service.saveHealthProfile(profile);

      healthProfile.value = result;
      setPrimaryHealthGoal(goal);

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================
  // SAVE CHALLENGES
  // ============================================================

  Future<bool> saveChallenges({
    required List<String> challenges,
    String? notes,
  }) async {
    try {
      isSaving.value = true;
      errorMessage.value = '';

      selectedChallenges.assignAll(challenges);

      final payload = <String, dynamic>{'challenges': challenges};

      if (notes != null && notes.trim().isNotEmpty) {
        payload['notes'] = notes.trim();
      }

      final result = await _service.updateOnboardingProfile(payload);

      healthProfile.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================
  // SAVE CHALLENGES & SLEEP QUALITY
  // ============================================================

  Future<bool> saveChallengesAndSleep({
    required List<String> challenges,
    required String quality,
  }) async {
    try {
      isSaving.value = true;
      errorMessage.value = '';

      selectedChallenges.assignAll(challenges);
      sleepQuality.value = quality;

      final result = await _service.updateOnboardingProfile({
        'challenges': challenges,
        'sleep_quality': quality,
      });

      healthProfile.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> saveHealthConditions({required List<String> conditions}) async {
    try {
      isSaving.value = true;
      errorMessage.value = '';

      final result = await _service.updateOnboardingProfile({
        'conditions': conditions,
      });

      healthProfile.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> saveActivityLevel({required String activityLevel}) async {
    try {
      isSaving.value = true;
      errorMessage.value = '';

      final result = await _service.updateOnboardingProfile({
        'activity_level': activityLevel,
      });

      healthProfile.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> saveLifestyle({
    required double sleepHoursTarget,
    required String stressLevel,
  }) async {
    try {
      isSaving.value = true;
      errorMessage.value = '';

      final result = await _service.updateOnboardingProfile({
        'sleep_hours_target': sleepHoursTarget,
        'stress_level': stressLevel,
      });

      healthProfile.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> saveDietType({required String dietType}) async {
    try {
      isSaving.value = true;
      errorMessage.value = '';

      final result = await _service.updateOnboardingProfile({
        'diet_type': dietType,
      });

      healthProfile.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================
  // SAVE SEXUAL WELLNESS
  // ============================================================
  Future<bool> saveSexualWellness({required String sexualWellness}) async {
    try {
      isSaving.value = true;
      errorMessage.value = '';

      final result = await _service.updateOnboardingProfile({
        'sexual_wellness': sexualWellness,
      });

      healthProfile.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================
  // SAVE HABIT & ADDICTION SUPPORT
  // ============================================================
  Future<bool> saveHabitAddiction({required String habitAddiction}) async {
    try {
      isSaving.value = true;
      errorMessage.value = '';

      final result = await _service.updateOnboardingProfile({
        'habit_addiction': habitAddiction,
      });

      healthProfile.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
