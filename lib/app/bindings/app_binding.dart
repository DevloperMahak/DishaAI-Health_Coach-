import 'package:get/get.dart';

import 'package:disha_ai/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:disha_ai/features/ai_health_coach/presentation/controllers/ai_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Dashboard controller
    if (!Get.isRegistered<DashboardController>()) {
      Get.put<DashboardController>(DashboardController(), permanent: true);
    }

    // AI controller
    if (!Get.isRegistered<AiController>()) {
      Get.put<AiController>(AiController(), permanent: true);
    }
  }
}
