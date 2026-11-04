class HealthProfileModel {
  final String? id;
  final String? name;
  final String? email;
  final String? mobile;
  final int? age;
  final String? gender;

  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;

  final String? activityLevel;
  final double? sleepHoursTarget;
  final String? stressLevel;

  final List<String> goals;
  final List<String> conditions;
  final List<String> challenges;
  final String? sleepQuality;

  final String? dietType;
  final List<String> allergies;
  final List<String> avoidedFoods;

  final String? sexualWellness;
  final String? habitAddiction;
  final int? healthScore; // 💡 Added healthScore field

  HealthProfileModel({
    this.id,
    this.name,
    this.email,
    this.mobile,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.activityLevel,
    this.sleepHoursTarget,
    this.stressLevel,
    this.goals = const [],
    this.conditions = const [],
    this.challenges = const [],
    this.sleepQuality,
    this.dietType,
    this.allergies = const [],
    this.avoidedFoods = const [],
    this.sexualWellness,
    this.habitAddiction,
    this.healthScore, // 💡 Added to constructor
  });

  factory HealthProfileModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] is Map<String, dynamic> ? json['user'] : json;

    final healthProfileData = userData['health_profile'] is Map<String, dynamic>
        ? userData['health_profile']
        : json;

    List<String> parsedGoals = [];
    final rawGoals =
        json['goals'] ?? userData['goals'] ?? healthProfileData['goals'];
    if (rawGoals is List) {
      parsedGoals = rawGoals
          .map((e) {
            if (e is Map) {
              return e['name']?.toString() ?? e['slug']?.toString() ?? '';
            }
            return e.toString();
          })
          .where((element) => element.isNotEmpty)
          .toList();
    }

    return HealthProfileModel(
      id:
          userData['id']?.toString() ??
          json['id']?.toString() ??
          json['_id']?.toString(),

      name: userData['name']?.toString() ?? json['name']?.toString(),

      email: userData['email']?.toString() ?? json['email']?.toString(),

      mobile: userData['mobile']?.toString() ?? json['mobile']?.toString(),

      age: _toInt(healthProfileData['age'] ?? json['age']),

      gender:
          healthProfileData['gender']?.toString() ?? json['gender']?.toString(),

      heightCm: _toDouble(
        healthProfileData['height_cm'] ??
            healthProfileData['heightCm'] ??
            json['height_cm'] ??
            json['heightCm'],
      ),

      weightKg: _toDouble(
        healthProfileData['weight_kg'] ??
            healthProfileData['weightKg'] ??
            json['weight_kg'] ??
            json['weightKg'],
      ),

      targetWeightKg: _toDouble(
        healthProfileData['target_weight_kg'] ??
            healthProfileData['targetWeightKg'] ??
            json['target_weight_kg'] ??
            json['targetWeightKg'],
      ),

      activityLevel:
          healthProfileData['activity_level']?.toString() ??
          healthProfileData['activityLevel']?.toString() ??
          json['activity_level']?.toString() ??
          json['activityLevel']?.toString(),

      sleepHoursTarget: _toDouble(
        healthProfileData['sleep_hours_target'] ??
            healthProfileData['sleepHoursTarget'] ??
            json['sleep_hours_target'] ??
            json['sleepHoursTarget'],
      ),

      stressLevel:
          healthProfileData['stress_level']?.toString() ??
          healthProfileData['stressLevel']?.toString() ??
          json['stress_level']?.toString() ??
          json['stressLevel']?.toString(),

      goals: parsedGoals,

      conditions: _toStringList(
        json['conditions'] ??
            userData['conditions'] ??
            healthProfileData['conditions'],
      ),

      challenges: _toStringList(
        healthProfileData['challenges'] ??
            json['challenges'] ??
            userData['challenges'],
      ),

      sleepQuality:
          healthProfileData['sleep_quality']?.toString() ??
          healthProfileData['sleepQuality']?.toString() ??
          json['sleep_quality']?.toString(),

      dietType:
          // 💡 1. Check inside 'food_preference' at root or user level
          json['food_preference']?['diet_type']?.toString() ??
          json['food_preference']?['dietType']?.toString() ??
          userData['food_preference']?['diet_type']?.toString() ??
          userData['food_preference']?['dietType']?.toString() ??
          // 💡 2. Check inside 'health_profile'
          healthProfileData['diet_type']?.toString() ??
          healthProfileData['dietType']?.toString() ??
          userData['diet_type']?.toString() ??
          json['diet_type']?.toString() ??
          json['dietType']?.toString(),

      allergies: _toStringList(
        json['allergies'] ??
            userData['allergies'] ??
            healthProfileData['allergies'],
      ),

      avoidedFoods: _toStringList(
        json['avoided_foods'] ??
            json['avoidedFoods'] ??
            userData['avoided_foods'] ??
            healthProfileData['avoided_foods'],
      ),

      sexualWellness:
          healthProfileData['sexual_wellness']?.toString() ??
          healthProfileData['sexualWellness']?.toString() ??
          json['sexual_wellness']?.toString(),

      habitAddiction:
          healthProfileData['habit_addiction']?.toString() ??
          healthProfileData['habitAddiction']?.toString() ??
          json['habit_addiction']?.toString(),

      // 💡 Parse health_score from JSON (supporting multiple key variations)
      healthScore: _toInt(
        healthProfileData['health_score'] ??
            healthProfileData['healthScore'] ??
            userData['health_score'] ??
            json['health_score'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (mobile != null) 'mobile': mobile,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
      if (activityLevel != null) 'activity_level': activityLevel,
      if (sleepHoursTarget != null) 'sleep_hours_target': sleepHoursTarget,
      if (stressLevel != null) 'stress_level': stressLevel,
      'goals': goals,
      'conditions': conditions,
      'challenges': challenges,
      if (sleepQuality != null) 'sleep_quality': sleepQuality,
      if (dietType != null) 'diet_type': dietType,
      'allergies': allergies,
      'avoided_foods': avoidedFoods,
      if (sexualWellness != null) 'sexual_wellness': sexualWellness,
      if (habitAddiction != null) 'habit_addiction': habitAddiction,
      if (healthScore != null) 'health_score': healthScore,
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) {
            if (e is Map) return e['name']?.toString() ?? '';
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }
}
