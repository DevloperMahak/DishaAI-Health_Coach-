import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../data/models/banner_model.dart';
import '../../data/services/banner_service.dart';

class BannerController extends GetxController {
  final BannerService _service;
  BannerController({BannerService? service})
    : _service = service ?? BannerService();

  final RxList<BannerModel> banners = <BannerModel>[].obs;
  final RxList<BannerCategoryModel> categories = <BannerCategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingCategories = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString categoryError = ''.obs;
  int _requestSerial = 0;

  Future<void> fetchBanners({int? categoryId, String? category}) async {
    final serial = ++_requestSerial;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final result = await _service.fetchBanners(
        categoryId: categoryId,
        category: category,
      );
      if (serial != _requestSerial || isClosed) return;
      banners.assignAll(
        result.data.where((item) => item.isActive && item.hasImage),
      );
    } catch (error) {
      if (serial != _requestSerial || isClosed) return;
      errorMessage.value = _friendlyError(error);
      // Preserve the previous banners on a transient refresh error.
    } finally {
      if (serial == _requestSerial && !isClosed) isLoading.value = false;
    }
  }

  Future<void> fetchCategories() async {
    isLoadingCategories.value = true;
    categoryError.value = '';
    try {
      final result = await _service.fetchCategories();
      if (isClosed) return;
      categories.assignAll(
        result.data.where((item) => item.status.toLowerCase() == 'active'),
      );
    } catch (error) {
      if (!isClosed) categoryError.value = _friendlyError(error);
    } finally {
      if (!isClosed) isLoadingCategories.value = false;
    }
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401) return 'Session expired. Please log in again.';
      if (status == 403) return 'You do not have permission to view banners.';
      return 'Unable to load banners (${status ?? 'network error'}).';
    }
    return error.toString().replaceFirst('Bad state: ', '');
  }
}
