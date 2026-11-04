class QuickActionCategoryModel {
  final int id;
  final String title;
  final String slug;
  final String? description;
  final String? iconUrl;
  final int order;
  final int subcategoriesCount;
  final int contentsCount;

  const QuickActionCategoryModel({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.iconUrl,
    required this.order,
    required this.subcategoriesCount,
    required this.contentsCount,
  });

  factory QuickActionCategoryModel.fromJson(Map<String, dynamic> json) {
    return QuickActionCategoryModel(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      iconUrl: json['icon_url']?.toString(),
      order: _toInt(json['order']),
      subcategoriesCount: _toInt(json['subcategories_count']),
      contentsCount: _toInt(json['contents_count']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
