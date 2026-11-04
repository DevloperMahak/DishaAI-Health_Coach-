import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import '../models/banner_model.dart';

class BannerService {
  // Override with --dart-define=BANNER_API_BASE_URL=https://YOUR_HOST/api
  // Use the SAME API host as your existing CategoryHubService.
  static const String _baseUrl = String.fromEnvironment(
    'BANNER_API_BASE_URL',
    defaultValue: 'https://rhea-ai.acttconnect.com/api',
  );

  final Dio _dio;
  final GetStorage _storage;

  BannerService({Dio? dio, GetStorage? storage})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
            ),
          ),
      _storage = storage ?? GetStorage();

  // If your project uses AuthStorage, replace ONLY this getter with
  // the same token retrieval used by your existing authenticated API service.
  String get _accessToken {
    final token = _storage.read('access_token') ?? _storage.read('token');
    return (token ?? '').toString().trim();
  }

  Options get _authOptions {
    final token = _accessToken;
    if (token.isEmpty) {
      throw StateError(
        'Login token unavailable. Connect BannerService to your existing AuthStorage.',
      );
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<BannerListResponse> fetchBanners({
    int? categoryId,
    String? category,
  }) async {
    final response = await _dio.get<dynamic>(
      '/banners',
      options: _authOptions,
      queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
      },
    );
    final raw = response.data;
    if (raw is! Map) throw const FormatException('Invalid banners response');
    final parsed = BannerListResponse.fromJson(Map<String, dynamic>.from(raw));
    if (!parsed.success)
      throw StateError(
        parsed.message.isEmpty ? 'Could not fetch banners' : parsed.message,
      );
    return parsed;
  }

  Future<BannerCategoriesResponse> fetchCategories() async {
    final response = await _dio.get<dynamic>(
      '/banners/categories',
      options: _authOptions,
    );
    final raw = response.data;
    if (raw is! Map)
      throw const FormatException('Invalid banner categories response');
    final parsed = BannerCategoriesResponse.fromJson(
      Map<String, dynamic>.from(raw),
    );
    if (!parsed.success)
      throw StateError(
        parsed.message.isEmpty
            ? 'Could not fetch banner categories'
            : parsed.message,
      );
    return parsed;
  }
}
