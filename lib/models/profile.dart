class Profile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? chineseLevel;
  final List<String> learningPurposes;
  final String? industry;
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
    this.avatarUrl,
    this.chineseLevel,
    this.learningPurposes = const [],
    this.industry,
    this.additionalContext,
    this.contextSummary,
    this.contextTags = const [],
    this.onboardingCompleted = false,
    this.dailyWordGoal = 20,
    this.themePreference = 'dark',
    required this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        chineseLevel: json['chinese_level'] as String?,
        learningPurposes: (json['learning_purposes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        industry: json['industry'] as String?,
        additionalContext: json['additional_context'] as String?,
        contextSummary: json['context_summary'] as String?,
        contextTags: (json['context_tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
        dailyWordGoal: json['daily_word_goal'] as int? ?? 20,
        themePreference: json['theme_preference'] as String? ?? 'dark',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'chinese_level': chineseLevel,
        'learning_purposes': learningPurposes,
        'industry': industry,
        'additional_context': additionalContext,
        'context_summary': contextSummary,
        'context_tags': contextTags,
        'onboarding_completed': onboardingCompleted,
        'daily_word_goal': dailyWordGoal,
        'theme_preference': themePreference,
      };
}
