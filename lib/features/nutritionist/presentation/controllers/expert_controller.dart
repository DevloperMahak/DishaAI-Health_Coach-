import 'package:disha_ai/features/nutritionist/data/services/export_service.dart';
import 'package:get/get.dart';
import 'package:disha_ai/features/ai_health_coach/data/models/ai_response_model.dart';
import 'package:disha_ai/features/nutritionist/data/models/expert_model.dart';

class ExpertController extends GetxController {
  final ExpertService _service = ExpertService();

  // ============================================================
  // EXPERTS STATE
  // ============================================================
  final RxBool isExpertsLoading = false.obs;
  final RxBool isConsulting = false.obs;
  final RxList<ExpertModel> expertsList = <ExpertModel>[].obs;
  final Rxn<AiResponseModel> enquiryResponse = Rxn<AiResponseModel>();
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchExperts();
  }

  // Fetch Experts
  Future<void> fetchExperts() async {
    try {
      isExpertsLoading.value = true;
      errorMessage.value = '';
      final result = await _service.getExperts();
      expertsList.value = result;
    } catch (e) {
      errorMessage.value = _cleanError(e);
    } finally {
      isExpertsLoading.value = false;
    }
  }

  // Submit Enquiry / Consult Now
  Future<bool> consultExpert({
    required int expertId,
    required String message,
  }) async {
    try {
      isConsulting.value = true;
      errorMessage.value = '';
      final result = await _service.consultExpert(
        expertId: expertId,
        message: message,
      );
      enquiryResponse.value = result;
      return true;
    } catch (e) {
      errorMessage.value = _cleanError(e);
      return false;
    } finally {
      isConsulting.value = false;
    }
  }

  String _cleanError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }
}
