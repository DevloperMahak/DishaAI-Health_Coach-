import 'package:get/get.dart';

import '../../data/models/today_progress_model.dart';
import '../../data/services/today_progress_service.dart';

class TodayProgressController extends GetxController {
  final TodayProgressService _service = TodayProgressService();

  final Rxn<TodayProgressModel> todayProgress = Rxn<TodayProgressModel>();

  final RxBool isLoading = false.obs;

  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();

    fetchTodayProgress();
  }

  // ============================================================
  // FETCH TODAY'S PROGRESS
  // ============================================================

  Future<void> fetchTodayProgress({String? date}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _service.getTodayProgress(
        date: date ?? _formatDate(DateTime.now()),
      );

      todayProgress.value = result;
    } catch (e) {
      errorMessage.value = _cleanError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshTodayProgress() async {
    await fetchTodayProgress();
  }

  // ============================================================
  // GETTERS
  // ============================================================

  int get totalTasks {
    return todayProgress.value?.totalTasks ?? 0;
  }

  int get completedTasks {
    return todayProgress.value?.completedTasks ?? 0;
  }

  int get pendingTasks {
    return todayProgress.value?.pendingTasks ?? 0;
  }

  double get progressPercentage {
    return todayProgress.value?.progressPercentage ?? 0.0;
  }

  double get progress {
    return todayProgress.value?.progress ?? 0.0;
  }

  String get percentageText {
    return todayProgress.value?.percentageText ?? '0%';
  }

  String get taskProgressText {
    return todayProgress.value?.taskProgressText ?? '0 / 0 Tasks Completed';
  }

  String get selectedDate {
    return todayProgress.value?.date ?? '';
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
