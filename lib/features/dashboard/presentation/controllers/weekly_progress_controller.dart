import 'package:get/get.dart';

import '../../data/models/weekly_progress_model.dart';
import '../../data/services/weekly_progress_service.dart';

class WeeklyProgressController extends GetxController {
  final WeeklyProgressService _service = WeeklyProgressService();

  final Rxn<WeeklyProgressModel> weeklyProgress = Rxn<WeeklyProgressModel>();

  final Rxn<WeeklyDayProgress> selectedDay = Rxn<WeeklyDayProgress>();

  final RxBool isLoading = false.obs;

  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchWeeklyProgress();
  }

  // ============================================================
  // FETCH WEEKLY PROGRESS
  // ============================================================

  Future<void> fetchWeeklyProgress({String? startDate, String? endDate}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final today = DateTime.now();

      final effectiveEndDate = endDate ?? _formatDate(today);

      final effectiveStartDate =
          startDate ?? _formatDate(today.subtract(const Duration(days: 6)));

      final result = await _service.getWeeklyProgress(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );

      weeklyProgress.value = result;

      _selectInitialDay();
    } catch (e) {
      errorMessage.value = _cleanError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // SELECT DAY
  // ============================================================

  void selectDay(WeeklyDayProgress day) {
    selectedDay.value = day;
  }

  void selectDayByIndex(int index) {
    final days = weeklyProgress.value?.dailyProgress ?? [];

    if (index < 0 || index >= days.length) {
      return;
    }

    selectedDay.value = days[index];
  }

  void _selectInitialDay() {
    final days = weeklyProgress.value?.dailyProgress ?? [];

    if (days.isEmpty) {
      selectedDay.value = null;
      return;
    }

    final today = weeklyProgress.value?.today;

    if (today != null) {
      selectedDay.value = today;
      return;
    }

    selectedDay.value = days.last;
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshWeeklyProgress() async {
    await fetchWeeklyProgress();
  }

  // ============================================================
  // SELECTED DAY GETTERS
  // ============================================================

  double get selectedCalories {
    return selectedDay.value?.calories ?? 0;
  }

  double get selectedTargetCalories {
    return selectedDay.value?.targetCalories ?? 0;
  }

  double get selectedCaloriesPercentage {
    return selectedDay.value?.caloriePercentage ?? 0;
  }

  int get selectedSteps {
    return selectedDay.value?.steps ?? 0;
  }

  int get selectedTargetSteps {
    return selectedDay.value?.targetSteps ?? 0;
  }

  double get selectedStepsPercentage {
    return selectedDay.value?.stepsPercentage ?? 0;
  }

  double get selectedSleep {
    return selectedDay.value?.sleepHours ?? 0;
  }

  double get selectedTargetSleep {
    return selectedDay.value?.targetSleepHours ?? 0;
  }

  double get selectedSleepPercentage {
    return selectedDay.value?.sleepPercentage ?? 0;
  }

  double get selectedWaterMl {
    return selectedDay.value?.waterMl ?? 0;
  }

  double get selectedTargetWaterMl {
    return selectedDay.value?.targetWaterMl ?? 0;
  }

  double get selectedWaterPercentage {
    return selectedDay.value?.waterPercentage ?? 0;
  }

  String get selectedDate {
    return selectedDay.value?.date ?? '';
  }

  String get selectedDayName {
    return selectedDay.value?.day ?? '';
  }

  // ============================================================
  // SUMMARY GETTERS
  // ============================================================

  double get averageCalories {
    return weeklyProgress.value?.summary.averageCalories ?? 0;
  }

  double get totalCalories {
    return weeklyProgress.value?.summary.totalCalories ?? 0;
  }

  int get daysLogged {
    return weeklyProgress.value?.summary.daysLogged ?? 0;
  }

  // ============================================================
  // DAYS
  // ============================================================

  List<WeeklyDayProgress> get days {
    return weeklyProgress.value?.dailyProgress ?? const [];
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  void clearError() {
    errorMessage.value = '';
  }
}
