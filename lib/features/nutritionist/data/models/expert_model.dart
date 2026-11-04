class ExpertModel {
  // ============================================================
  // BASIC DETAILS
  // ============================================================

  final int id;
  final String name;
  final String? email;
  final String? designation;
  final String? specialization;

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  final String? imageUrl;
  final String? thumbnailImageUrl;
  final String? imageUpdatedAt;

  // ============================================================
  // PROFESSIONAL DETAILS
  // ============================================================

  final int experienceYears;
  final String? bio;
  final double? rating;

  // ============================================================
  // CONSULTATION DETAILS
  // ============================================================

  // Existing property preserved for compatibility.
  final String? fee;

  // New API duration fields.
  final int durationValue;
  final String durationUnit;
  final String durationFormatted;

  // ============================================================
  // LANGUAGES AND WORKING SCHEDULE
  // ============================================================

  final List<String> languages;
  final List<String> workingDays;

  final String? startTime;
  final String? endTime;
  final String? workingHours;

  // ============================================================
  // AVAILABILITY
  // ============================================================

  final bool isAvailable;
  final String? availabilityStatus;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  ExpertModel({
    required this.id,
    required this.name,
    this.email,
    this.designation,
    this.specialization,
    this.imageUrl,
    this.thumbnailImageUrl,
    this.imageUpdatedAt,
    this.experienceYears = 0,
    this.bio,
    this.rating,
    this.fee,
    this.durationValue = 0,
    this.durationUnit = '',
    this.durationFormatted = '',
    this.languages = const [],
    this.workingDays = const [],
    this.startTime,
    this.endTime,
    this.workingHours,
    this.isAvailable = false,
    this.availabilityStatus,
  });

  // ============================================================
  // HELPER: READ STRING
  // ============================================================

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  // ============================================================
  // HELPER: READ INTEGER
  // ============================================================

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;

    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? fallback;
  }

  // ============================================================
  // HELPER: READ DOUBLE
  // ============================================================

  static double _readDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;

    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? fallback;
  }

  // ============================================================
  // HELPER: READ BOOLEAN
  // ============================================================

  static bool _readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;

    if (value is num) return value != 0;

    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
        case 'yes':
          return true;

        case 'false':
        case '0':
        case 'no':
          return false;
      }
    }

    return fallback;
  }

  // ============================================================
  // HELPER: READ STRING LIST
  // ============================================================

  static List<String> _readStringList(
    dynamic value, {
    List<String> fallback = const [],
  }) {
    if (value is! List) {
      return List<String>.from(fallback);
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  // ============================================================
  // FROM JSON
  //
  // Supports:
  // 1. Latest flat API response
  // 2. Previous nested expert_profile response
  // ============================================================

  factory ExpertModel.fromJson(Map<String, dynamic> json) {
    // ----------------------------------------------------------
    // EXPERT PROFILE
    // ----------------------------------------------------------

    final Map<String, dynamic> profile = json['expert_profile'] is Map
        ? Map<String, dynamic>.from(json['expert_profile'] as Map)
        : <String, dynamic>{};

    // ----------------------------------------------------------
    // PROFILE IMAGE
    // ----------------------------------------------------------

    final String profileImage = _readString(json['profile_image_url']);

    final String profilePhoto = _readString(json['profile_photo']);

    final String legacyImage = _readString(json['image_url']);

    final String thumbnailImage = _readString(
      json['profile_image_thumbnail_url'],
    );

    final String finalImage = [
      profileImage,
      profilePhoto,
      legacyImage,
      thumbnailImage,
    ].firstWhere((image) => image.isNotEmpty, orElse: () => '');

    // ----------------------------------------------------------
    // SPECIALIZATION
    // ----------------------------------------------------------

    final String specialty = _readString(
      json['specialization'],
      fallback: _readString(
        profile['specialty'],
        fallback: 'Nutrition & Wellness',
      ),
    );

    // ----------------------------------------------------------
    // DESIGNATION
    // ----------------------------------------------------------

    final String designation = _readString(
      json['designation'],
      fallback: _readString(
        profile['credentials'],
        fallback: 'Nutrition Specialist',
      ),
    );

    // ----------------------------------------------------------
    // EXPERIENCE
    // ----------------------------------------------------------

    final int experienceYears = _readInt(
      json['experience_years'] ?? profile['years_experience'],
    );

    // ----------------------------------------------------------
    // CONSULTATION FEE
    //
    // Latest API:
    // "consultation_fee": 300
    //
    // Existing UI uses expert.fee.
    // ----------------------------------------------------------

    final String fee = _readString(
      json['consultation_fee'] ?? profile['consultation_fee'] ?? json['fee'],
      fallback: '600.00',
    );

    // ----------------------------------------------------------
    // CONSULTATION DURATION
    //
    // Latest API:
    // "duration_value": 30
    // "duration_unit": "days"
    // "duration_formatted": "30 Days"
    // ----------------------------------------------------------

    final int durationValue = _readInt(
      json['duration_value'] ?? profile['duration_value'],
    );

    final String durationUnit = _readString(
      json['duration_unit'] ?? profile['duration_unit'],
    );

    final String apiDurationFormatted = _readString(
      json['duration_formatted'] ?? profile['duration_formatted'],
    );

    // Prefer backend-formatted duration.
    // Generate a fallback only when it is missing.

    final String durationFormatted = apiDurationFormatted.isNotEmpty
        ? apiDurationFormatted
        : durationValue > 0 && durationUnit.isNotEmpty
        ? '$durationValue '
              '${durationValue == 1 && durationUnit.endsWith('s') ? durationUnit.substring(0, durationUnit.length - 1) : durationUnit}'
        : '';

    // ----------------------------------------------------------
    // RATING
    // ----------------------------------------------------------

    final double rating = _readDouble(json['rating'] ?? profile['rating']);

    // ----------------------------------------------------------
    // BIO
    // ----------------------------------------------------------

    final String bio = _readString(json['bio'] ?? profile['bio']);

    // ----------------------------------------------------------
    // LANGUAGES
    // ----------------------------------------------------------

    final List<String> languages = _readStringList(
      json['languages'] ?? profile['languages'],
      fallback: const ['English', 'Hindi'],
    );

    // ----------------------------------------------------------
    // WORKING DAYS
    // ----------------------------------------------------------

    final List<String> workingDays = _readStringList(
      json['working_days'],
      fallback: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    );

    // ----------------------------------------------------------
    // WORKING HOURS
    // ----------------------------------------------------------

    final String startTime = _readString(json['start_time']);

    final String endTime = _readString(json['end_time']);

    final String workingHours = _readString(
      json['working_hours'],
      fallback: '10:00 AM - 07:00 PM',
    );

    // ----------------------------------------------------------
    // AVAILABILITY
    // ----------------------------------------------------------

    final bool isAvailable = _readBool(
      json['is_available'] ?? json['is_active'],
    );

    final String availabilityStatus = _readString(
      json['availability_status'],
      fallback: isAvailable ? 'Available Now' : 'Offline',
    );

    // ----------------------------------------------------------
    // RETURN MODEL
    // ----------------------------------------------------------

    return ExpertModel(
      id: _readInt(json['id']),
      name: _readString(json['name'], fallback: 'Nutrition Expert'),
      email: json['email']?.toString(),
      designation: designation,
      specialization: specialty,
      imageUrl: finalImage.isNotEmpty ? finalImage : null,
      thumbnailImageUrl: thumbnailImage.isNotEmpty ? thumbnailImage : null,
      imageUpdatedAt: json['image_updated_at']?.toString(),
      experienceYears: experienceYears,
      bio: bio.isNotEmpty ? bio : null,
      rating: rating,
      fee: fee,
      durationValue: durationValue,
      durationUnit: durationUnit,
      durationFormatted: durationFormatted,
      languages: languages,
      workingDays: workingDays,
      startTime: startTime.isNotEmpty ? startTime : null,
      endTime: endTime.isNotEmpty ? endTime : null,
      workingHours: workingHours,
      isAvailable: isAvailable,
      availabilityStatus: availabilityStatus,
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'designation': designation,
      'specialization': specialization,

      // Images
      'image_url': imageUrl,
      'profile_image_url': imageUrl,
      'profile_photo': imageUrl,
      'profile_image_thumbnail_url': thumbnailImageUrl,
      'image_updated_at': imageUpdatedAt,

      // Professional details
      'experience_years': experienceYears,
      'bio': bio,
      'rating': rating,

      // Consultation details
      'fee': fee,
      'consultation_fee': fee,
      'duration_value': durationValue,
      'duration_unit': durationUnit,
      'duration_formatted': durationFormatted,

      // Schedule
      'languages': languages,
      'working_days': workingDays,
      'start_time': startTime,
      'end_time': endTime,
      'working_hours': workingHours,

      // Availability
      'is_available': isAvailable,
      'availability_status': availabilityStatus,
    };
  }

  // ============================================================
  // ADDITIONAL GETTERS
  // ============================================================

  /// Returns the consultation fee as a number.
  double get consultationFee {
    return double.tryParse(fee ?? '') ?? 0.0;
  }

  /// Returns the formatted consultation fee.
  String get formattedFee {
    return '₹${consultationFee.toStringAsFixed(0)}';
  }

  /// Returns the consultation duration.
  String get consultationDuration {
    return durationFormatted;
  }

  /// Returns experience as readable text.
  String get formattedExperience {
    if (experienceYears <= 0) {
      return 'Experience not specified';
    }

    return '$experienceYears ${experienceYears == 1 ? 'Year' : 'Years'} Experience';
  }

  /// Returns availability text.
  String get availabilityText {
    final status = availabilityStatus?.trim() ?? '';

    if (status.isNotEmpty) {
      return status;
    }

    return isAvailable ? 'Available Now' : 'Offline';
  }
}
