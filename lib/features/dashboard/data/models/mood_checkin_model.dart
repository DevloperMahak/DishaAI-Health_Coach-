class MoodCheckinModel {
  final String mood;
  final String stressLevel;

  const MoodCheckinModel({required this.mood, required this.stressLevel});

  factory MoodCheckinModel.fromJson(Map<String, dynamic> json) {
    return MoodCheckinModel(
      mood: json['mood']?.toString() ?? '',
      stressLevel: json['stress_level']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'mood': mood, 'stress_level': stressLevel};
  }

  MoodCheckinModel copyWith({String? mood, String? stressLevel}) {
    return MoodCheckinModel(
      mood: mood ?? this.mood,
      stressLevel: stressLevel ?? this.stressLevel,
    );
  }

  @override
  String toString() {
    return 'MoodCheckinModel('
        'mood: $mood, '
        'stressLevel: $stressLevel'
        ')';
  }
}
