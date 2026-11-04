class BannerCategoryModel {
  final int id;
  final String name;
  final String status;
  final int bannersCount;
  final DateTime? createdAt;

  const BannerCategoryModel({
    required this.id,
    required this.name,
    required this.status,
    required this.bannersCount,
    this.createdAt,
  });

  factory BannerCategoryModel.fromJson(Map<String, dynamic> json) =>
      BannerCategoryModel(
        id: int.tryParse('${json['id'] ?? 0}') ?? 0,
        name: (json['name'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        bannersCount: int.tryParse('${json['banners_count'] ?? 0}') ?? 0,
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      );
}

class BannerModel {
  final int id;
  final int categoryId;
  final String categoryName;
  final BannerCategoryModel? category;
  final String imagePath;
  final String imageUrl;
  final String status;
  final DateTime? createdAt;

  const BannerModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.category,
    required this.imagePath,
    required this.imageUrl,
    required this.status,
    this.createdAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get hasImage =>
      Uri.tryParse(imageUrl)?.hasAbsolutePath == true &&
      (imageUrl.startsWith('https://') || imageUrl.startsWith('http://'));

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'];
    final category = rawCategory is Map
        ? BannerCategoryModel.fromJson(Map<String, dynamic>.from(rawCategory))
        : null;
    return BannerModel(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      categoryId: int.tryParse('${json['category_id'] ?? 0}') ?? 0,
      categoryName: (json['category_name'] ?? category?.name ?? '').toString(),
      category: category,
      imagePath: (json['image_path'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString().trim(),
      status: (json['status'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}

class BannerListResponse {
  final bool success;
  final String message;
  final int count;
  final List<BannerModel> data;
  const BannerListResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });

  factory BannerListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final items = raw is List
        ? raw
              .whereType<Map>()
              .map(
                (item) => BannerModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <BannerModel>[];
    return BannerListResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      count: int.tryParse('${json['count'] ?? items.length}') ?? items.length,
      data: items,
    );
  }
}

class BannerCategoriesResponse {
  final bool success;
  final String message;
  final int count;
  final List<BannerCategoryModel> data;
  const BannerCategoriesResponse({
    required this.success,
    required this.message,
    required this.count,
    required this.data,
  });
  factory BannerCategoriesResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final items = raw is List
        ? raw
              .whereType<Map>()
              .map(
                (item) => BannerCategoryModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <BannerCategoryModel>[];
    return BannerCategoriesResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      count: int.tryParse('${json['count'] ?? items.length}') ?? items.length,
      data: items,
    );
  }
}
