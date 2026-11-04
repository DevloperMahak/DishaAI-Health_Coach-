class CategoryHubModel {
  final CategoryInfo? category;
  final ContentItem? heroFeatured;
  final GuidedVideoSection? guidedVideoSessions;
  final List<SubcategoryItem> subcategories;
  final List<ContentItem> contents;
  final SuggestedVideosModel? suggestedVideos;
  final UserProgress? userProgress;
  final RheaRecommendation? rheaRecommendation;

  CategoryHubModel({
    this.category,
    this.heroFeatured,
    this.guidedVideoSessions,
    this.subcategories = const [],
    this.contents = const [],
    this.suggestedVideos,
    this.userProgress,
    this.rheaRecommendation,
  });

  factory CategoryHubModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : json;

    return CategoryHubModel(
      category: data['category'] != null
          ? CategoryInfo.fromJson(Map<String, dynamic>.from(data['category']))
          : null,

      heroFeatured: data['hero_featured'] != null
          ? ContentItem.fromJson(
              Map<String, dynamic>.from(data['hero_featured']),
            )
          : null,

      guidedVideoSessions: data['guided_video_sessions'] != null
          ? GuidedVideoSection.fromJson(
              Map<String, dynamic>.from(data['guided_video_sessions']),
            )
          : null,

      subcategories: data['subcategories'] is List
          ? (data['subcategories'] as List)
                .whereType<Map>()
                .map(
                  (e) => SubcategoryItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : [],

      contents: data['contents'] is List
          ? (data['contents'] as List)
                .whereType<Map>()
                .map((e) => ContentItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : [],

      // NEW
      suggestedVideos: data['suggested_videos'] != null
          ? SuggestedVideosModel.fromJson(
              Map<String, dynamic>.from(data['suggested_videos']),
            )
          : null,

      userProgress: data['your_progress'] != null
          ? UserProgress.fromJson(
              Map<String, dynamic>.from(data['your_progress']),
            )
          : null,

      rheaRecommendation: data['rhea_recommendation'] != null
          ? RheaRecommendation.fromJson(
              Map<String, dynamic>.from(data['rhea_recommendation']),
            )
          : null,
    );
  }
}

// ============================================================
// CATEGORY INFO
// ============================================================

class CategoryInfo {
  final int id;
  final String title;
  final String slug;
  final String? description;

  CategoryInfo({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
    );
  }
}

// ============================================================
// SUBCATEGORY
// ============================================================

class SubcategoryItem {
  final int id;
  final String name;
  final String slug;
  final int order;

  SubcategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.order,
  });

  factory SubcategoryItem.fromJson(Map<String, dynamic> json) {
    return SubcategoryItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}

// ============================================================
// CONTENT ITEM
// ============================================================

class ContentItem {
  final int id;
  final int categoryId;
  final int subcategoryId;
  final String subcategoryName;
  final String title;
  final String? description;
  final String contentType;
  final String sourceType;
  final String? playbackUrl;
  final String? thumbnailUrl;
  final int durationMinutes;
  final String durationText;
  final String level;
  final bool isFeatured;
  final bool isLocked;
  final bool isGuidedSession;

  ContentItem({
    required this.id,
    required this.categoryId,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.title,
    this.description,
    required this.contentType,
    required this.sourceType,
    this.playbackUrl,
    this.thumbnailUrl,
    required this.durationMinutes,
    required this.durationText,
    required this.level,
    required this.isFeatured,
    required this.isLocked,
    required this.isGuidedSession,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      subcategoryId: json['subcategory_id'] ?? 0,
      subcategoryName: json['subcategory_name'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      contentType: json['content_type'] ?? 'audio',
      sourceType: json['source_type'] ?? 'url',
      playbackUrl: json['playback_url'],
      thumbnailUrl: json['thumbnail_url'],
      durationMinutes: json['duration_minutes'] ?? 0,
      durationText: json['duration_text'] ?? '',
      level: json['level'] ?? 'Beginner',
      isFeatured: json['is_featured'] ?? false,
      isLocked: json['is_locked'] ?? false,
      isGuidedSession: json['is_guided_session'] ?? false,
    );
  }
}

// ============================================================
// GUIDED VIDEO SESSIONS
// ============================================================

class GuidedVideoSection {
  final String title;
  final String subtitle;
  final List<ContentItem> items;

  GuidedVideoSection({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  factory GuidedVideoSection.fromJson(Map<String, dynamic> json) {
    return GuidedVideoSection(
      title: json['title'] ?? 'Guided Video Sessions',
      subtitle: json['subtitle'] ?? '',
      items: json['items'] is List
          ? (json['items'] as List)
                .whereType<Map>()
                .map((e) => ContentItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : [],
    );
  }
}

// ============================================================
// SUGGESTED VIDEOS
// ============================================================

class SuggestedVideosModel {
  final String title;
  final String subtitle;
  final List<SuggestedVideoItem> items;

  SuggestedVideosModel({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  factory SuggestedVideosModel.fromJson(Map<String, dynamic> json) {
    return SuggestedVideosModel(
      title: json['title']?.toString() ?? 'Suggested For You',
      subtitle:
          json['subtitle']?.toString() ??
          'Recommended sessions from other categories',

      items: json['items'] is List
          ? (json['items'] as List)
                .whereType<Map>()
                .map(
                  (e) =>
                      SuggestedVideoItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : [],
    );
  }
}

// ============================================================
// SUGGESTED VIDEO ITEM
// ============================================================

class SuggestedVideoItem {
  final int id;
  final String title;
  final int categoryId;
  final String categoryTitle;
  final String categorySlug;
  final String? playbackUrl;
  final String? thumbnailUrl;
  final int durationMinutes;
  final String durationText;
  final String level;
  final String contentType;

  SuggestedVideoItem({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryTitle,
    required this.categorySlug,
    this.playbackUrl,
    this.thumbnailUrl,
    required this.durationMinutes,
    required this.durationText,
    required this.level,
    required this.contentType,
  });

  factory SuggestedVideoItem.fromJson(Map<String, dynamic> json) {
    return SuggestedVideoItem(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',

      categoryId: json['category_id'] ?? 0,

      categoryTitle: json['category_title']?.toString() ?? '',

      categorySlug: json['category_slug']?.toString() ?? '',

      playbackUrl: json['playback_url']?.toString(),

      thumbnailUrl: json['thumbnail_url']?.toString(),

      durationMinutes: json['duration_minutes'] ?? 0,

      durationText: json['duration_text']?.toString() ?? '',

      level: json['level']?.toString() ?? 'Beginner',

      contentType: json['content_type']?.toString() ?? 'video',
    );
  }
}

// ============================================================
// USER PROGRESS
// ============================================================

class UserProgress {
  final int sessionsCount;
  final int minutesSpent;
  final int dayStreak;
  final WeeklyGoal? weeklyGoal;

  UserProgress({
    required this.sessionsCount,
    required this.minutesSpent,
    required this.dayStreak,
    this.weeklyGoal,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      sessionsCount: json['sessions_count'] ?? 0,
      minutesSpent: json['minutes_spent'] ?? 0,
      dayStreak: json['day_streak'] ?? 0,
      weeklyGoal: json['weekly_goal'] != null
          ? WeeklyGoal.fromJson(Map<String, dynamic>.from(json['weekly_goal']))
          : null,
    );
  }
}

// ============================================================
// WEEKLY GOAL
// ============================================================

class WeeklyGoal {
  final int target;
  final int completed;
  final int percentage;
  final String display;

  WeeklyGoal({
    required this.target,
    required this.completed,
    required this.percentage,
    required this.display,
  });

  factory WeeklyGoal.fromJson(Map<String, dynamic> json) {
    return WeeklyGoal(
      target: json['target'] ?? 5,
      completed: json['completed'] ?? 0,
      percentage: json['percentage'] ?? 0,
      display: json['display'] ?? '0 / 5 sessions',
    );
  }
}

// ============================================================
// RHEA RECOMMENDATION
// ============================================================

class RheaRecommendation {
  final String title;
  final String message;

  RheaRecommendation({required this.title, required this.message});

  factory RheaRecommendation.fromJson(Map<String, dynamic> json) {
    return RheaRecommendation(
      title: json['title'] ?? 'RheaAI Recommendation',
      message: json['message'] ?? '',
    );
  }
}
