class ExpertModel {
  final int id;
  final String name;
  final String? designation;
  final String? specialization;
  final String? imageUrl;
  final double? rating;

  ExpertModel({
    required this.id,
    required this.name,
    this.designation,
    this.specialization,
    this.imageUrl,
    this.rating,
  });

  factory ExpertModel.fromJson(Map<String, dynamic> json) {
    return ExpertModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      designation: json['designation']?.toString(),
      specialization: json['specialization']?.toString(),
      imageUrl: json['image_url']?.toString(),
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : 0.0,
    );
  }
}
