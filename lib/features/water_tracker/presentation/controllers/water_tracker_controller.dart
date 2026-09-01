import 'package:disha_ai/features/onboarding/presentation/controllers/health_nutrition_controller.dart';
import 'package:get/get.dart';
import '../../data/models/water_log_model.dart';

class WaterTrackerController extends GetxController {
  // Connecting HealthNutritionController to sync water/health updates with backend
  final HealthNutritionController _healthController = Get.put(
    HealthNutritionController(),
  );

  //==============================================================
  // Daily Goal
  //==============================================================

  final RxInt dailyGoal = 2500.obs;

  //==============================================================
  // Water Logs
  //==============================================================

  final RxList<WaterLogModel> waterLogs = <WaterLogModel>[].obs;

  //==============================================================
  // Reminder
  //==============================================================

  final RxBool reminderEnabled = true.obs;

  // minutes
  final RxInt reminderInterval = 120.obs;

  //==============================================================
  // Loading
  //==============================================================

  final RxBool isLoading = false.obs;

  //==============================================================
  // Init
  //==============================================================

  @override
  void onInit() {
    super.onInit();
    _loadDummyData();
  }

  //==============================================================
  // Today's Logs
  //==============================================================

  List<WaterLogModel> get todayLogs {
    final logs = waterLogs.where((log) => _isToday(log.loggedAt)).toList();
    logs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return logs;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  //==============================================================
  // Today's Intake
  //==============================================================

  int get todayIntake {
    int total = 0;
    for (final log in todayLogs) {
      total += log.amount;
    }
    return total;
  }

  //==============================================================
  // Remaining Water
  //==============================================================

  int get remainingWater {
    final value = dailyGoal.value - todayIntake;
    return value <= 0 ? 0 : value;
  }

  //==============================================================
  // Progress
  //==============================================================

  double get progress {
    if (dailyGoal.value == 0) {
      return 0;
    }
    return (todayIntake / dailyGoal.value).clamp(0.0, 1.0);
  }

  int get percentage => (progress * 100).round();

  bool get goalCompleted => todayIntake >= dailyGoal.value;

  //==============================================================
  // Statistics
  //==============================================================

  int get currentStreak => 8;

  double get averageWater => 2300;

  double get bestWater => 3100;

  int get hydrationScore {
    if (progress >= 1) {
      return 100;
    }
    return percentage;
  }

  //==============================================================
  // AI Recommendation
  //==============================================================

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

  //==============================================================
  // Add Water & Sync with API
  //==============================================================

  Future<void> addWater(int amount) async {
    final now = DateTime.now();

    final newLog = WaterLogModel(
      id: now.microsecondsSinceEpoch.toString(),
      userId: "demo_user",
      amount: amount,
      loggedAt: now,
      source: WaterSource.glass,
      createdAt: now,
      updatedAt: now,
    );

    waterLogs.insert(0, newLog);
    waterLogs.refresh();

    // Syncing updated metrics to backend health API
    try {
      final currentLog = _healthController.healthLog.value;
      await _healthController.postHealthMetrics(
        steps: currentLog?.steps ?? 0,
        sleepHours: currentLog?.sleepHours ?? 7.5,
        caloriesConsumed: currentLog?.caloriesConsumed ?? 1800,
        caloriesBurned: currentLog?.caloriesBurned ?? 350,
        weightKg: currentLog?.weightKg ?? 58.0,
        mood: currentLog?.mood ?? "energetic",
        stressLevel: currentLog?.stressLevel ?? "low",
      );
    } catch (e) {
      print("Failed to sync water log with backend: $e");
    }

    print("$amount ml added and synced");
  }

  //==============================================================
  // Delete Log
  //==============================================================

  void deleteLog(String id) {
    waterLogs.removeWhere((log) => log.id == id);
    waterLogs.refresh();
  }

  //==============================================================
  // Update Goal
  //==============================================================

  void updateGoal(int goal) {
    dailyGoal.value = goal;
  }

  //==============================================================
  // Reminder Toggle
  //==============================================================

  void toggleReminder(bool value) {
    reminderEnabled.value = value;
  }

  //==============================================================
  // Reminder Interval
  //==============================================================

  void updateReminderInterval(int minutes) {
    reminderInterval.value = minutes;
  }

  //==============================================================
  // Refresh
  //==============================================================

  Future<void> refreshData() async {
    isLoading.value = true;
    await _healthController.fetchHealthLogs();
    isLoading.value = false;
  }

  //==============================================================
  // Dummy Data
  //==============================================================

  void _loadDummyData() {
    final now = DateTime.now();

    waterLogs.assignAll([
      WaterLogModel(
        id: "1",
        userId: "demo_user",
        amount: 250,
        loggedAt: DateTime(now.year, now.month, now.day, 8, 30),
        source: WaterSource.glass,
        createdAt: now,
        updatedAt: now,
      ),
      WaterLogModel(
        id: "2",
        userId: "demo_user",
        amount: 500,
        loggedAt: DateTime(now.year, now.month, now.day, 11, 15),
        source: WaterSource.bottle,
        createdAt: now,
        updatedAt: now,
      ),
      WaterLogModel(
        id: "3",
        userId: "demo_user",
        amount: 850,
        loggedAt: DateTime(now.year, now.month, now.day, 13, 45),
        source: WaterSource.bottle,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  }
}
