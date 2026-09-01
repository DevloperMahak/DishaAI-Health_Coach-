import 'package:get/get.dart';

import '../../data/models/dashboard_model.dart';
import '../../data/models/today_summary_model.dart';
import '../../data/services/dashboard_service.dart';

class DashboardController extends GetxController {
  final DashboardService _service = DashboardService();

  // ============================================================
  // STATE
  // ============================================================

  final Rxn<DashboardModel> dashboard = Rxn<DashboardModel>();

  final Rxn<TodaySummaryModel> todaySummary = Rxn<TodaySummaryModel>();

  final RxBool isLoadingDashboard = false.obs;

  final RxBool isLoadingTodaySummary = false.obs;

  final RxString errorMessage = ''.obs;

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<bool> fetchDashboard() async {
    try {
      isLoadingDashboard.value = true;
      errorMessage.value = '';

      final result = await _service.getDashboard();

      dashboard.value = result;

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);

      return false;
    } finally {
      isLoadingDashboard.value = false;
    }
  }

  // ============================================================
  // LOAD TODAY SUMMARY
  // ============================================================

  Future<bool> fetchTodaySummary() async {
    try {
      isLoadingTodaySummary.value = true;
      errorMessage.value = '';

      final result = await _service.getTodaySummary();

      todaySummary.value = result;

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);

      return false;
    } finally {
      isLoadingTodaySummary.value = false;
    }
  }

  // ============================================================
  // LOAD EVERYTHING
  // ============================================================

  Future<void> loadDashboard() async {
    await Future.wait([fetchDashboard(), fetchTodaySummary()]);
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }
}
