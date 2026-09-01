import 'package:disha_ai/features/onboarding/presentation/controllers/health_profile_controller.dart';
import 'package:get/get.dart';

class HealthProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HealthProfileController>(() => HealthProfileController());
  }
}
