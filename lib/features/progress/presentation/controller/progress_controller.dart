import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';

import '../../data/models/progress_model.dart';
import '../../data/services/progress_service.dart';

class ProgressController extends GetxController {
  // ============================================================
  // SERVICE
  // ============================================================

  final ProgressService _service = ProgressService();

  // ============================================================
  // STATE
  // ============================================================

  final Rxn<ProgressModel> progress = Rxn<ProgressModel>();

  final RxBool isLoading = false.obs;

  final RxString errorMessage = ''.obs;

  final RxString selectedFilter = 'week'.obs;

  // ============================================================
  // FETCH PROGRESS
  // ============================================================

  Future<void> fetchProgress({required String filter, String? date}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      selectedFilter.value = filter;

      final result = await _service.getProgress(filter: filter, date: date);

      progress.value = result;
    } catch (e) {
      errorMessage.value = _cleanError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // CHANGE FILTER
  // ============================================================

  Future<void> changeFilter(String filter) async {
    await fetchProgress(filter: filter);
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshProgress() async {
    await fetchProgress(filter: selectedFilter.value);
  }

  // ============================================================
  // CALORIES
  // ============================================================

  double get caloriesAverage {
    return progress.value?.calories.average ?? 0.0;
  }

  double get caloriesTarget {
    return progress.value?.calories.target ?? 0.0;
  }

  double get caloriesGoalPercentage {
    return progress.value?.calories.goalPercentage ?? 0.0;
  }

  String get caloriesDisplay {
    return caloriesAverage.toStringAsFixed(0);
  }

  // ============================================================
  // STEPS
  // ============================================================

  double get stepsAverage {
    return progress.value?.steps.average ?? 0.0;
  }

  double get stepsTarget {
    return progress.value?.steps.target ?? 0.0;
  }

  double get stepsGoalPercentage {
    return progress.value?.steps.goalPercentage ?? 0.0;
  }

  String get stepsDisplay {
    return stepsAverage.toStringAsFixed(0);
  }

  // ============================================================
  // SLEEP
  // ============================================================

  double get sleepAverage {
    return progress.value?.sleep.averageHours ?? 0.0;
  }

  double get sleepTarget {
    return progress.value?.sleep.targetHours ?? 0.0;
  }

  double get sleepGoalPercentage {
    return progress.value?.sleep.goalPercentage ?? 0.0;
  }

  String get sleepDisplay {
    return sleepAverage.toStringAsFixed(1);
  }

  // ============================================================
  // WATER
  // ============================================================

  double get waterAverageMl {
    return progress.value?.water.averageMl ?? 0.0;
  }

  double get waterAverageLiters {
    return waterAverageMl / 1000.0;
  }

  double get waterTargetMl {
    return progress.value?.water.targetMl ?? 0.0;
  }

  double get waterGoalPercentage {
    return progress.value?.water.goalPercentage ?? 0.0;
  }

  String get waterDisplay {
    return waterAverageLiters.toStringAsFixed(1);
  }

  // ============================================================
  // WEIGHT
  // ============================================================

  double get currentWeight {
    return progress.value?.weight.currentKg ?? 0.0;
  }

  double get startingWeight {
    return progress.value?.weight.startKg ?? 0.0;
  }

  double get targetWeight {
    return progress.value?.weight.targetKg ?? 0.0;
  }

  double get weightChange {
    return progress.value?.weight.changeKg ?? 0.0;
  }

  String get weightUnit {
    return progress.value?.weight.unit ?? 'kg';
  }

  // ============================================================
  // WEIGHT CHART
  // ============================================================

  List<FlSpot> get weightSpots {
    final data = progress.value;

    if (data == null || data.chart.isEmpty) {
      return [];
    }

    final spots = <FlSpot>[];

    for (int i = 0; i < data.chart.length; i++) {
      final weight = data.chart[i].weightKg;

      // According to the API contract, 0 means no value
      // for that bucket.
      if (weight > 0) {
        spots.add(FlSpot(i.toDouble(), weight));
      }
    }

    return spots;
  }

  // ============================================================
  // CHART LABELS
  // ============================================================

  List<String> get chartLabels {
    final data = progress.value;

    if (data == null || data.chart.isEmpty) {
      return [];
    }

    return data.chart.map((point) => point.label).toList();
  }

  // ============================================================
  // FULL CHART DATA
  // ============================================================

  List<ProgressChartPoint> get chartData {
    return progress.value?.chart ?? [];
  }

  // ============================================================
  // PERIOD INFORMATION
  // ============================================================

  String get startDate {
    return progress.value?.startDate ?? '';
  }

  String get endDate {
    return progress.value?.endDate ?? '';
  }

  String get filter {
    return progress.value?.filter ?? selectedFilter.value;
  }

  // ============================================================
  // DAYS LOGGED
  // ============================================================

  int get caloriesDaysLogged {
    return progress.value?.calories.daysLogged ?? 0;
  }

  int get stepsDaysLogged {
    return progress.value?.steps.daysLogged ?? 0;
  }

  int get sleepDaysLogged {
    return progress.value?.sleep.daysLogged ?? 0;
  }

  int get waterDaysLogged {
    return progress.value?.water.daysLogged ?? 0;
  }

  // ============================================================
  // ERROR CLEANER
  // ============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clearProgress() {
    progress.value = null;
    errorMessage.value = '';
  }
}
