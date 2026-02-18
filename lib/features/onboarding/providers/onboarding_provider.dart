import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';

class OnboardingState {
  final int currentStep;
  final String? displayName;
  final String? chineseLevel;
  final List<String> learningPurposes;
  final List<String> interests;
  final String? additionalContext;
  final String? ageRange;
  final int dailyWordGoal;
  final bool isSubmitting;
  final String? error;
  // Suggested words
  final List<Map<String, dynamic>> suggestedWords;
  final Set<int> selectedWordIndices;
  final bool isLoadingSuggestions;
  final bool isSavingWords;

  const OnboardingState({
    this.currentStep = 0,
    this.displayName,
    this.chineseLevel,
    this.learningPurposes = const [],
    this.interests = const [],
    this.additionalContext,
    this.ageRange,
    this.dailyWordGoal = 20,
    this.isSubmitting = false,
    this.error,
    this.suggestedWords = const [],
    this.selectedWordIndices = const {},
    this.isLoadingSuggestions = false,
    this.isSavingWords = false,
  });

  // Steps: 0=Name, 1=Level, 2=Purposes, 3=Interests, 4=Preferences, 5=Suggestions
  int get totalSteps => 6;
  int get suggestionsStep => 5;
  int get preferencesStep => 4;

  OnboardingState copyWith({
    int? currentStep,
    String? displayName,
    String? chineseLevel,
    List<String>? learningPurposes,
    List<String>? interests,
    String? additionalContext,
    String? ageRange,
    int? dailyWordGoal,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    bool clearAdditionalContext = false,
    bool clearAgeRange = false,
    List<Map<String, dynamic>>? suggestedWords,
    Set<int>? selectedWordIndices,
    bool? isLoadingSuggestions,
    bool? isSavingWords,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      displayName: displayName ?? this.displayName,
      chineseLevel: chineseLevel ?? this.chineseLevel,
      learningPurposes: learningPurposes ?? this.learningPurposes,
      interests: interests ?? this.interests,
      additionalContext: clearAdditionalContext
          ? null
          : (additionalContext ?? this.additionalContext),
      ageRange: clearAgeRange ? null : (ageRange ?? this.ageRange),
      dailyWordGoal: dailyWordGoal ?? this.dailyWordGoal,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      suggestedWords: suggestedWords ?? this.suggestedWords,
      selectedWordIndices: selectedWordIndices ?? this.selectedWordIndices,
      isLoadingSuggestions:
          isLoadingSuggestions ?? this.isLoadingSuggestions,
      isSavingWords: isSavingWords ?? this.isSavingWords,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final SupabaseClient _client;
  final User? _user;

  OnboardingNotifier(this._client, this._user)
      : super(const OnboardingState());

  void setDisplayName(String? name) {
    state = state.copyWith(displayName: name);
  }

  void setChineseLevel(String level) {
    state = state.copyWith(chineseLevel: level);
  }

  void togglePurpose(String purpose) {
    final purposes = List<String>.from(state.learningPurposes);
    if (purposes.contains(purpose)) {
      purposes.remove(purpose);
    } else {
      purposes.add(purpose);
    }
    state = state.copyWith(learningPurposes: purposes);
  }

  void toggleInterest(String interest) {
    final interests = List<String>.from(state.interests);
    if (interests.contains(interest)) {
      interests.remove(interest);
    } else {
      interests.add(interest);
    }
    state = state.copyWith(interests: interests);
  }

  void setAdditionalContext(String? text) {
    state = state.copyWith(
      additionalContext: text,
      clearAdditionalContext: text == null,
    );
  }

  void setAgeRange(String? range) {
    state = state.copyWith(
      ageRange: range,
      clearAgeRange: range == null,
    );
  }

  void setDailyWordGoal(int goal) {
    state = state.copyWith(dailyWordGoal: goal);
  }

  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void previousStep() {
    int prev = state.currentStep - 1;
    if (prev < 0) prev = 0;
    state = state.copyWith(currentStep: prev);
  }

  void toggleWordSelection(int index) {
    final selected = Set<int>.from(state.selectedWordIndices);
    if (selected.contains(index)) {
      selected.remove(index);
    } else {
      selected.add(index);
    }
    state = state.copyWith(selectedWordIndices: selected);
  }

  void selectAllWords() {
    final all = List.generate(state.suggestedWords.length, (i) => i).toSet();
    state = state.copyWith(selectedWordIndices: all);
  }

  void deselectAllWords() {
    state = state.copyWith(selectedWordIndices: {});
  }

  /// Submit profile data, generate context, fetch suggestions, advance to suggestions step.
  Future<bool> submitAndFetchSuggestions() async {
    if (_user == null) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      // Step 1: Generate context
      final response = await _client.functions.invoke(
        'generate-context',
        body: {
          'chinese_level': state.chineseLevel,
          'learning_purposes': state.learningPurposes,
          'interests': state.interests,
          'additional_context': state.additionalContext,
        },
      );

      String? contextSummary;
      List<String> contextTags = [];

      if (response.status == 200) {
        final rawData = response.data;
        final Map<String, dynamic> data = rawData is String
            ? jsonDecode(rawData) as Map<String, dynamic>
            : rawData as Map<String, dynamic>;
        contextSummary = data['context_summary'] as String?;
        contextTags = (data['context_tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [];
      }

      // Step 2: Save profile (but keep onboarding_completed = false)
      await _client.from('profiles').update({
        'display_name': state.displayName,
        'age_range': state.ageRange,
        'chinese_level': state.chineseLevel,
        'learning_purposes': state.learningPurposes,
        'interests': state.interests,
        'additional_context': state.additionalContext,
        'daily_word_goal': state.dailyWordGoal,
        'context_summary': contextSummary,
        'context_tags': contextTags,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _user.id);

      // Step 3: Advance to suggestions step and start loading
      state = state.copyWith(
        isSubmitting: false,
        currentStep: state.suggestionsStep,
        isLoadingSuggestions: true,
      );

      // Step 4: Fetch suggested words
      final suggestResponse = await _client.functions.invoke(
        'suggest-words',
        body: {
          'context_summary': contextSummary,
          'context_tags': contextTags,
          'chinese_level': state.chineseLevel,
        },
      );

      if (suggestResponse.status == 200) {
        final rawData = suggestResponse.data;
        final Map<String, dynamic> data = rawData is String
            ? jsonDecode(rawData) as Map<String, dynamic>
            : rawData as Map<String, dynamic>;
        final words = (data['words'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];

        // Select all by default
        final allIndices = List.generate(words.length, (i) => i).toSet();
        state = state.copyWith(
          suggestedWords: words,
          selectedWordIndices: allIndices,
          isLoadingSuggestions: false,
        );
      } else {
        state = state.copyWith(isLoadingSuggestions: false);
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        isLoadingSuggestions: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Save selected words and complete onboarding.
  Future<bool> saveSelectedAndComplete() async {
    if (_user == null) return false;
    state = state.copyWith(isSavingWords: true, clearError: true);

    try {
      // Build list of selected words
      final wordsToSave = state.selectedWordIndices
          .where((i) => i < state.suggestedWords.length)
          .map((i) {
        final w = state.suggestedWords[i];
        return {
          'english': w['english'],
          'chinese': w['chinese'],
          'pinyin': w['pinyin'],
          'meaning': w['meaning'],
          'examples': w['examples'] ?? [],
          'segments': w['segments'] ?? [],
          'categories': w['tags_suggested'] ?? [],
        };
      }).toList();

      if (wordsToSave.isNotEmpty) {
        await _client.functions.invoke(
          'batch-save-words',
          body: {'words': wordsToSave},
        );
      }

      // Mark onboarding complete
      await _client.from('profiles').update({
        'onboarding_completed': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _user.id);

      state = state.copyWith(isSavingWords: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSavingWords: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Skip suggestions and just complete onboarding.
  Future<bool> skipAndComplete() async {
    if (_user == null) return false;
    state = state.copyWith(isSavingWords: true, clearError: true);

    try {
      await _client.from('profiles').update({
        'onboarding_completed': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _user.id);

      state = state.copyWith(isSavingWords: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSavingWords: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return OnboardingNotifier(client, user);
});
