import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/water_log_model.dart';
import '../../data/services/water_tracker_service.dart';

class WaterTrackerController extends GetxController {
  // ===============================================================
  // SERVICE
  // ===============================================================

  final WaterTrackerService _waterService = WaterTrackerService();

  // ===============================================================
  // DAILY SUMMARY
  // ===============================================================

  final Rxn<WaterDailySummary> dailySummary = Rxn<WaterDailySummary>();

  // ===============================================================
  // TODAY'S LOGS
  // ===============================================================

  final RxList<WaterLogModel> waterLogs = <WaterLogModel>[].obs;

  // ===============================================================
  // WEEKLY WATER
  // ===============================================================

  /// Key = YYYY-MM-DD
  /// Value = consumed ml
  final RxMap<String, int> weeklyWater = <String, int>{}.obs;

  /// Key = YYYY-MM-DD
  /// Value = target ml
  final RxMap<String, int> weeklyTargets = <String, int>{}.obs;

  // ===============================================================
  // LOADING
  // ===============================================================

  final RxBool isLoading = false.obs;

  final RxBool isAddingWater = false.obs;

  final RxString errorMessage = ''.obs;

  final RxString deletingLogId = ''.obs;

  // ===============================================================
  // REMINDER
  // ===============================================================

  /// Reminder is currently local because the supplied API
  /// documentation does not provide a reminder endpoint.
  final RxBool reminderEnabled = true.obs;

  final RxInt reminderInterval = 120.obs;

  // ===============================================================
  // LIFECYCLE
  // ===============================================================

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  // ===============================================================
  // DAILY GETTERS
  // ===============================================================

  int get dailyGoal {
    return dailySummary.value?.targetMl ?? 2500;
  }

  int get todayIntake {
    return dailySummary.value?.consumedMl ?? 0;
  }

  int get remainingWater {
    return dailySummary.value?.remainingMl ??
        _calculateRemaining(dailyGoal, todayIntake);
  }

  double get progress {
    final apiProgress = dailySummary.value?.progressPercentage;

    if (apiProgress != null) {
      return (apiProgress / 100).clamp(0.0, 1.0);
    }

    if (dailyGoal <= 0) {
      return 0;
    }

    return (todayIntake / dailyGoal).clamp(0.0, 1.0);
  }

  int get percentage {
    final apiProgress = dailySummary.value?.progressPercentage;

    if (apiProgress != null) {
      return apiProgress.round().clamp(0, 100);
    }

    return (progress * 100).round();
  }

  bool get goalCompleted {
    return todayIntake >= dailyGoal;
  }

  // ===============================================================
  // TODAY'S LOGS
  // ===============================================================

  List<WaterLogModel> get todayLogs {
    final logs = List<WaterLogModel>.from(waterLogs);

    logs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    return logs;
  }

  // ===============================================================
  // STATISTICS
  // ===============================================================

  // ===============================================================
  // STATISTICS
  // ===============================================================

  int get averageWater {
    if (weeklyWater.isEmpty) {
      return 0;
    }

    final total = weeklyWater.values.fold<int>(0, (sum, value) => sum + value);

    return (total / weeklyWater.length).round();
  }

  int get bestWater {
    if (weeklyWater.isEmpty) {
      return 0;
    }

    return weeklyWater.values.reduce((a, b) => a > b ? a : b);
  }

  int get currentStreak {
    if (weeklyWater.isEmpty) {
      return 0;
    }

    int streak = 0;

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));

      final key = _formatDate(date);
      final consumed = weeklyWater[key] ?? 0;
      final target = weeklyTargets[key] ?? dailyGoal;

      if (consumed >= target && target > 0) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  int get hydrationScore {
    if (percentage >= 100) {
      return 100;
    }

    return percentage.clamp(0, 100);
  }

  // ===============================================================
  // AI RECOMMENDATION
  // ===============================================================

  String get aiRecommendation {
    if (goalCompleted) {
      return "Excellent! 🎉 You've completed today's hydration goal.";
    }

    if (percentage >= 80) {
      return "Great job! Drink another $remainingWater ml to complete your goal.";
    }

    if (percentage >= 50) {
      return "You're halfway through today's hydration target. Keep going.";
    }

    if (todayIntake == 0) {
      return "Good morning! Start your day with a glass of water.";
    }

    return "Drink $remainingWater ml gradually throughout the day.";
  }

  // ===============================================================
  // LOAD EVERYTHING
  // ===============================================================

  Future<void> loadData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await fetchTodayWater();
      await fetchWeeklyWater();
    } finally {
      isLoading.value = false;
    }
  }

  // ===============================================================
  // GET TODAY
  // ===============================================================

  Future<bool> fetchTodayWater() async {
    final date = _formatDate(DateTime.now());

    final response = await _waterService.getWaterLog(date: date);

    if (response['success'] != true) {
      errorMessage.value =
          response['message']?.toString() ?? 'Failed to load water data.';

      return false;
    }

    final data = _extractData(response);

    if (data == null) {
      errorMessage.value = 'Invalid water data received from server.';

      return false;
    }

    final summary = WaterDailySummary.fromJson(data);

    dailySummary.value = summary;

    waterLogs.assignAll(summary.logs);

    return true;
  }

  // ===============================================================
  // GET WEEKLY WATER
  // ===============================================================
  //
  // IMPORTANT:
  // The supplied API document does NOT define a
  // weekly water endpoint.
  //
  // Therefore we request the documented daily water endpoint
  // for the last 7 days.
  // ===============================================================

  Future<void> fetchWeeklyWater() async {
    final today = DateTime.now();

    final dates = List<DateTime>.generate(
      7,
      (index) => DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: 6 - index)),
    );

    final responses = await Future.wait(
      dates.map((date) => _waterService.getWaterLog(date: _formatDate(date))),
    );

    final waterValues = <String, int>{};
    final targetValues = <String, int>{};

    for (int i = 0; i < dates.length; i++) {
      final dateKey = _formatDate(dates[i]);
      final response = responses[i];

      if (response['success'] != true) {
        waterValues[dateKey] = 0;
        targetValues[dateKey] = dailyGoal;
        continue;
      }

      final data = _extractData(response);

      if (data == null) {
        waterValues[dateKey] = 0;
        targetValues[dateKey] = dailyGoal;
        continue;
      }

      final summary = WaterDailySummary.fromJson(data);

      waterValues[dateKey] = summary.consumedMl;

      targetValues[dateKey] = summary.targetMl;
    }

    weeklyWater.assignAll(waterValues);
    weeklyTargets.assignAll(targetValues);
  }

  // ===============================================================
  // ADD WATER
  // ===============================================================

  Future<void> addWater(int amount) async {
    if (amount <= 0) {
      return;
    }

    if (isAddingWater.value) {
      return;
    }

    isAddingWater.value = true;

    try {
      final response = await _waterService.addWater(amountMl: amount);

      if (response['success'] != true) {
        _showError(response['message']?.toString() ?? 'Failed to add water.');
        return;
      }

      final data = _extractData(response);

      if (data != null) {
        // Backend is authoritative for totals.
        final updatedSummary = WaterDailySummary.fromJson(data);

        dailySummary.value = updatedSummary;

        // POST response contains "entry", not "logs".
        final rawEntry = data['entry'];

        if (rawEntry is Map) {
          final entry = WaterLogModel.fromJson(
            Map<String, dynamic>.from(rawEntry),
          );

          final updatedLogs = List<WaterLogModel>.from(waterLogs);

          updatedLogs.removeWhere((log) => log.id == entry.id);

          updatedLogs.insert(0, entry);

          waterLogs.assignAll(updatedLogs);
        }
      }

      // Refresh today's GET so the timeline is always
      // synchronized with the backend.
      await fetchTodayWater();

      // Refresh weekly values because today's day changed.
      await fetchWeeklyWater();

      _showSuccess('Successfully added $amount ml of water.');
    } finally {
      isAddingWater.value = false;
    }
  }

  // ===============================================================
  // DELETE WATER
  // ===============================================================

  Future<void> deleteWater(String id) async {
    if (id.isEmpty || deletingLogId.value.isNotEmpty) {
      return;
    }

    deletingLogId.value = id;

    try {
      final response = await _waterService.deleteWater(id: id);

      if (response['success'] != true) {
        _showError(
          response['message']?.toString() ?? 'Failed to delete water entry.',
        );
        return;
      }

      // Immediately remove the entry locally.
      waterLogs.removeWhere((log) => log.id == id);

      final data = _extractData(response);

      if (data != null) {
        final current = dailySummary.value ?? WaterDailySummary.empty();

        dailySummary.value = current.copyWith(
          date: data['date']?.toString() ?? current.date,
          consumedMl: _toInt(data['consumed_ml']),
          targetMl: _toInt(data['target_ml']),
          remainingMl: _toInt(data['remaining_ml']),
          progressPercentage: _toDouble(data['progress_percentage']),
          unit: data['unit']?.toString() ?? current.unit,
          logs: waterLogs.toList(),
        );
      }

      await fetchTodayWater();
      await fetchWeeklyWater();

      _showSuccess('Water entry removed successfully.');
    } finally {
      deletingLogId.value = '';
    }
  }

  // ===============================================================
  // REFRESH
  // ===============================================================

  Future<void> refreshData() async {
    await loadData();
  }

  // ===============================================================
  // REMINDERS
  // ===============================================================

  void toggleReminder(bool value) {
    reminderEnabled.value = value;
  }

  void updateReminderInterval(int minutes) {
    reminderInterval.value = minutes;
  }

  // ===============================================================
  // HELPERS
  // ===============================================================

  Map<String, dynamic>? _extractData(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return null;
  }

  int _calculateRemaining(int target, int consumed) {
    final remaining = target - consumed;

    return remaining > 0 ? remaining : 0;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Water Tracker',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Water Tracker',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.error_outline_rounded, color: Colors.red),
    );
  }
}
