import 'package:disha_ai/features/dashboard/data/models/quick_action_category_model.dart';
import 'package:get/get.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

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
  // PEDOMETER
  // ============================================================

  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;

  final RxString stepCountValue = '0'.obs;
  final RxString pedestrianStatus = 'stopped'.obs;

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  final RxList<QuickActionCategoryModel> quickActions =
      <QuickActionCategoryModel>[].obs;

  final RxBool isLoadingQuickActions = false.obs;

  // ============================================================
  // QUICK ACTION CATEGORY DETAILS
  // ============================================================

  final Rxn<Map<String, dynamic>> quickActionCategoryDetails =
      Rxn<Map<String, dynamic>>();

  final RxBool isLoadingQuickActionCategory = false.obs;

  final RxString quickActionCategoryError = ''.obs;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void onInit() {
    super.onInit();
    initPlatformState();
  }

  // ============================================================
  // PEDOMETER INITIALIZATION
  // ============================================================

  Future<void> initPlatformState() async {
    try {
      final status = await Permission.activityRecognition.request();

      if (!status.isGranted) {
        errorMessage.value = 'Activity recognition permission denied.';
        return;
      }

      _pedestrianStatusStream = Pedometer.pedestrianStatusStream;

      _pedestrianStatusStream
          .listen(onPedestrianStatusChanged)
          .onError(onPedestrianStatusError);

      _stepCountStream = Pedometer.stepCountStream;

      _stepCountStream.listen(onStepCount).onError(onStepCountError);
    } catch (e) {
      errorMessage.value = 'Unable to initialize step counter: $e';
    }
  }

  // ============================================================
  // STEP COUNT
  // ============================================================

  void onStepCount(StepCount event) {
    stepCountValue.value = event.steps.toString();

    if (todaySummary.value != null) {
      // Keep your existing TodaySummary model update
      // here if copyWith(steps: ...) is available.
    }
  }

  // ============================================================
  // PEDESTRIAN STATUS
  // ============================================================

  void onPedestrianStatusChanged(PedestrianStatus event) {
    pedestrianStatus.value = event.status;
  }

  // ============================================================
  // STEP ERROR
  // ============================================================

  void onStepCountError(dynamic error) {
    errorMessage.value = 'Step Count Error: $error';
  }

  // ============================================================
  // PEDESTRIAN ERROR
  // ============================================================

  void onPedestrianStatusError(dynamic error) {
    pedestrianStatus.value = 'Unknown';
  }

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
  // LOAD QUICK ACTIONS
  // GET /quick-actions
  // ============================================================

  Future<bool> fetchQuickActions() async {
    try {
      isLoadingQuickActions.value = true;
      errorMessage.value = '';

      final result = await _service.getQuickActions();

      quickActions.assignAll(result);

      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);

      return false;
    } finally {
      isLoadingQuickActions.value = false;
    }
  }

  // ============================================================
  // LOAD QUICK ACTION CATEGORY
  //
  // GET /quick-actions/{slug}
  //
  // Example:
  // fetchQuickActionCategory('meditation')
  // ============================================================

  Future<bool> fetchQuickActionCategory(String slug) async {
    try {
      isLoadingQuickActionCategory.value = true;

      quickActionCategoryError.value = '';

      final result = await _service.getQuickActionCategory(slug);

      quickActionCategoryDetails.value = result;

      return true;
    } catch (e) {
      quickActionCategoryError.value = _cleanError(e);

      return false;
    } finally {
      isLoadingQuickActionCategory.value = false;
    }
  }

  // ============================================================
  // GET SUGGESTED VIDEOS
  //
  // This reads suggested_videos from the already-fetched
  // category-detail response.
  // ============================================================

  List<Map<String, dynamic>> get suggestedVideos {
    final data = quickActionCategoryDetails.value;

    if (data == null) {
      return [];
    }

    final suggested = data['suggested_videos'];

    if (suggested is! Map) {
      return [];
    }

    final items = suggested['items'];

    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ============================================================
  // SUGGESTED VIDEOS TITLE
  // ============================================================

  String get suggestedVideosTitle {
    final data = quickActionCategoryDetails.value;

    final suggested = data?['suggested_videos'];

    if (suggested is Map) {
      return suggested['title']?.toString() ?? 'Suggested For You';
    }

    return 'Suggested For You';
  }

  // ============================================================
  // SUGGESTED VIDEOS SUBTITLE
  // ============================================================

  String get suggestedVideosSubtitle {
    final data = quickActionCategoryDetails.value;

    final suggested = data?['suggested_videos'];

    if (suggested is Map) {
      return suggested['subtitle']?.toString() ??
          'Recommended sessions from other categories';
    }

    return 'Recommended sessions from other categories';
  }

  // ============================================================
  // LOAD EVERYTHING
  // ============================================================

  Future<void> loadDashboard() async {
    await Future.wait([
      fetchDashboard(),
      fetchTodaySummary(),
      fetchQuickActions(),
    ]);
  }

  // ============================================================
  // CLEAR CATEGORY DETAILS
  // ============================================================

  void clearQuickActionCategory() {
    quickActionCategoryDetails.value = null;

    quickActionCategoryError.value = '';
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
}
