class Profile {
  final String id;
  final String? displayName;
  final List<String> focusAreas;
  final String? additionalContext;
  final String? contextSummary;
  final List<String> contextTags;
  final bool onboardingCompleted;
  final int dailyWordGoal;
  final String themePreference;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Profile({
    required this.id,
    this.displayName,
    this.focusAreas = const [],
    this.additionalContext,
    this.contextSummary,
    this.contextTags = const [],
    this.onboardingCompleted = false,
    this.dailyWordGoal = 20,
    this.themePreference = 'light',
    required this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        displayName: json['display_name'] as String?,
        focusAreas: (json['focus_areas'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        additionalContext: json['additional_context'] as String?,
        contextSummary: json['context_summary'] as String?,
        contextTags: (json['context_tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
        dailyWordGoal: json['daily_word_goal'] as int? ?? 20,
        themePreference: json['theme_preference'] as String? ?? 'light',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'focus_areas': focusAreas,
        'additional_context': additionalContext,
        'context_summary': contextSummary,
        'context_tags': contextTags,
        'onboarding_completed': onboardingCompleted,
        'daily_word_goal': dailyWordGoal,
        'theme_preference': themePreference,
      };
}
