class ProfileModel {
  final int id;
  final String name;
  final String? email;
  final String? preferredLanguage;
  final String? profilePhoto;
  final bool onboardingCompleted;

  ProfileModel({
    required this.id,
    required this.name,
    this.email,
    this.preferredLanguage,
    this.profilePhoto,
    required this.onboardingCompleted,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // 💡 Handle all variations of nested structures from backend responses
    final Map<String, dynamic> data = json['data'] is Map
        ? json['data']
        : (json['user'] is Map
              ? json['user']
              : (json['profile'] is Map ? json['profile'] : json));

    // Also check if 'profile_photo' is inside a nested user object within data
    final nestedUser = data['user'] is Map ? data['user'] : null;

    final rawName =
        data['name']?.toString().trim() ??
        nestedUser?['name']?.toString().trim() ??
        '';

    final resolvedName = (rawName.isEmpty || rawName.toLowerCase() == 'user')
        ? 'My Profile'
        : rawName;

    // 💡 Comprehensive fallback mapping for all photo key possibilities
    final resolvedPhoto =
        data['profile_photo']?.toString() ??
        data['photo']?.toString() ??
        data['avatar']?.toString() ??
        data['image']?.toString() ??
        data['profile_image']?.toString() ??
        nestedUser?['profile_photo']?.toString() ??
        nestedUser?['photo']?.toString();

    final rawCompleted =
        data['onboarding_completed'] ?? nestedUser?['onboarding_completed'];

    return ProfileModel(
      id: data['id'] is int
          ? data['id']
          : int.tryParse(
                  data['id']?.toString() ??
                      nestedUser?['id']?.toString() ??
                      '0',
                ) ??
                0,
      name: resolvedName,
      email: data['email']?.toString() ?? nestedUser?['email']?.toString(),
      preferredLanguage: data['preferred_language']?.toString() ?? 'en',
      profilePhoto: resolvedPhoto,
      onboardingCompleted:
          rawCompleted == true || rawCompleted.toString() == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'preferred_language': preferredLanguage,
      'profile_photo': profilePhoto,
      'onboarding_completed': onboardingCompleted,
    };
  }

  ProfileModel copyWith({
    int? id,
    String? name,
    String? email,
    String? preferredLanguage,
    String? profilePhoto,
    bool? onboardingCompleted,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
