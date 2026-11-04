import 'dart:convert';

import 'package:disha_ai/features/meditation/data/models/category_hub_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_constants.dart';
import '../../../../core/storage/auth_storage.dart';

class CategoryHubController extends GetxController {
  final AuthStorage _storage = AuthStorage.instance;

  // ============================================================
  // CATEGORY DATA
  // ============================================================

  final Rxn<CategoryHubModel> hubData = Rxn<CategoryHubModel>();

  final RxBool isLoading = false.obs;

  final RxString errorMessage = ''.obs;

  // ============================================================
  // SELECTED SUBCATEGORY
  // null = show all contents
  // ============================================================

  final RxnInt selectedSubcategoryId = RxnInt();

  // ============================================================
  // FETCH CATEGORY DETAILS
  // GET /api/quick-actions/{slug}
  // ============================================================

  Future<void> fetchCategoryDetails(String slug) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Reset previous category filter when opening
      // another category.
      selectedSubcategoryId.value = null;

      final token = _storage.accessToken;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/quick-actions/$slug'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token?.trim() ?? ''}',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        hubData.value = CategoryHubModel.fromJson(decoded);
      } else {
        errorMessage.value =
            'Failed to load category details (${response.statusCode})';
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // FILTERED CATEGORY CONTENT
  // ============================================================

  List<ContentItem> get filteredContents {
    final allContents = hubData.value?.contents ?? [];

    final selectedId = selectedSubcategoryId.value;

    if (selectedId == null) {
      return allContents;
    }

    return allContents
        .where((item) => item.subcategoryId == selectedId)
        .toList();
  }

  // ============================================================
  // SUGGESTED VIDEOS
  // ============================================================

  SuggestedVideosModel? get suggestedVideos {
    return hubData.value?.suggestedVideos;
  }

  List<SuggestedVideoItem> get suggestedVideoItems {
    return hubData.value?.suggestedVideos?.items ?? [];
  }

  String get suggestedVideosTitle {
    return hubData.value?.suggestedVideos?.title ?? 'Suggested For You';
  }

  String get suggestedVideosSubtitle {
    return hubData.value?.suggestedVideos?.subtitle ??
        'Recommended sessions from other categories';
  }

  // ============================================================
  // CATEGORY HELPERS
  // ============================================================

  CategoryInfo? get category {
    return hubData.value?.category;
  }

  ContentItem? get heroFeatured {
    return hubData.value?.heroFeatured;
  }

  GuidedVideoSection? get guidedVideoSessions {
    return hubData.value?.guidedVideoSessions;
  }

  List<SubcategoryItem> get subcategories {
    return hubData.value?.subcategories ?? [];
  }

  UserProgress? get userProgress {
    return hubData.value?.userProgress;
  }

  RheaRecommendation? get rheaRecommendation {
    return hubData.value?.rheaRecommendation;
  }
}
