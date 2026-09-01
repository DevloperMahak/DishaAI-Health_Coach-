import 'package:get/get.dart';
import '../../data/models/master_data_model.dart';
import '../../data/services/master_data_service.dart';

class MasterDataController extends GetxController {
  final MasterDataService _service = MasterDataService();

  var isLoading = false.obs;
  var masterData = Rxn<MasterDataModel>();

  @override
  void onInit() {
    super.onInit();
    fetchMasterData();
  }

  Future<void> fetchMasterData() async {
    if (masterData.value != null)
      return; // Prevent duplicate fetches if already loaded
    isLoading.value = true;
    try {
      final data = await _service.fetchMasterData();
      if (data != null) {
        masterData.value = data;
      }
    } finally {
      isLoading.value = false;
    }
  }
}
