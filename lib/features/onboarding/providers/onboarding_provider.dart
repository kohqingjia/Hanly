import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';

class OnboardingState {
  final int currentStep;
  final String? displayName;
  final String? ageRange;
  final List<String> focusAreas;
  final String? additionalContext;
  final bool isSubmitting;
  final String? error;
  // Suggested words
  final List<Map<String, dynamic>> suggestedWords;
  final Set<int> selectedWordIndices;
  final bool isLoadingSuggestions;
  final bool isSavingWords;
  // Word generation progress (batch-based)
  final int wordGenerationProgress; // batches completed (0..totalWordBatches)
  final int totalWordBatches;

  const OnboardingState({
    this.currentStep = 0,
    this.displayName,
    this.ageRange,
    this.focusAreas = const [],
    this.additionalContext,
    this.isSubmitting = false,
    this.error,
    this.suggestedWords = const [],
    this.selectedWordIndices = const {},
    this.isLoadingSuggestions = false,
    this.isSavingWords = false,
    this.wordGenerationProgress = 0,
    this.totalWordBatches = 3,
  });

  // Steps: 0=Name+Age, 1=Focus Areas, 2=Additional Context, 3=Suggestions
  int get totalSteps => 4;
  int get suggestionsStep => 3;
  int get contextStep => 2;

  OnboardingState copyWith({
    int? currentStep,
    String? displayName,
    String? ageRange,
    List<String>? focusAreas,
    String? additionalContext,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    bool clearAdditionalContext = false,
    bool clearAgeRange = false,
    List<Map<String, dynamic>>? suggestedWords,
    Set<int>? selectedWordIndices,
    bool? isLoadingSuggestions,
    bool? isSavingWords,
    int? wordGenerationProgress,
    int? totalWordBatches,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      displayName: displayName ?? this.displayName,
      ageRange: clearAgeRange ? null : (ageRange ?? this.ageRange),
      focusAreas: focusAreas ?? this.focusAreas,
      additionalContext: clearAdditionalContext
          ? null
          : (additionalContext ?? this.additionalContext),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      suggestedWords: suggestedWords ?? this.suggestedWords,
      selectedWordIndices: selectedWordIndices ?? this.selectedWordIndices,
      isLoadingSuggestions:
          isLoadingSuggestions ?? this.isLoadingSuggestions,
      isSavingWords: isSavingWords ?? this.isSavingWords,
      wordGenerationProgress:
          wordGenerationProgress ?? this.wordGenerationProgress,
      totalWordBatches: totalWordBatches ?? this.totalWordBatches,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final SupabaseClient _client;
  final User? _user;
  bool _generationCancelled = false;

  OnboardingNotifier(this._client, this._user)
      : super(const OnboardingState());

  void setDisplayName(String? name) {
    state = state.copyWith(displayName: name);
  }

  void setAgeRange(String? range) {
    state = state.copyWith(
      ageRange: range,
      clearAgeRange: range == null,
    );
  }

  void toggleFocusArea(String area) {
    final areas = List<String>.from(state.focusAreas);
    if (areas.contains(area)) {
      areas.remove(area);
    } else {
      areas.add(area);
    }
    state = state.copyWith(focusAreas: areas);
  }

  void setAdditionalContext(String? text) {
    state = state.copyWith(
      additionalContext: text,
      clearAdditionalContext: text == null,
    );
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

  /// Submit profile data, generate context, fetch suggestions in iterative batches.
  Future<bool> submitAndFetchSuggestions() async {
    if (_user == null) return false;
    _generationCancelled = false;
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      // Step 1: Generate context
      final response = await _client.functions.invoke(
        'generate-context',
        body: {
          'focus_areas': state.focusAreas,
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
        'focus_areas': state.focusAreas,
        'additional_context': state.additionalContext,
        'context_summary': contextSummary,
        'context_tags': contextTags,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _user.id);

      // Step 3: Advance to suggestions step and start loading
      const int batchSize = 4;
      const int totalBatches = 3;
      state = state.copyWith(
        isSubmitting: false,
        currentStep: state.suggestionsStep,
        isLoadingSuggestions: true,
        wordGenerationProgress: 0,
        totalWordBatches: totalBatches,
        suggestedWords: [],
        selectedWordIndices: {},
      );

      // Step 4: Fetch words in iterative batches
      final List<Map<String, dynamic>> allWords = [];

      for (int batch = 0; batch < totalBatches; batch++) {
        if (_generationCancelled) break;

        final existingWordIdentifiers = allWords
            .map((w) => {
                  'english': w['english'],
                  'chinese': w['chinese'],
                })
            .toList();

        final suggestResponse = await _client.functions.invoke(
          'suggest-words',
          body: {
            'context_summary': contextSummary,
            'context_tags': contextTags,
            'count': batchSize,
            'existing_words': existingWordIdentifiers,
          },
        );

        if (_generationCancelled) break;

        if (suggestResponse.status == 200) {
          final rawData = suggestResponse.data;
          final Map<String, dynamic> data = rawData is String
              ? jsonDecode(rawData) as Map<String, dynamic>
              : rawData as Map<String, dynamic>;
          final newWords = (data['words'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [];

          allWords.addAll(newWords);
          final allIndices =
              List.generate(allWords.length, (i) => i).toSet();

          state = state.copyWith(
            suggestedWords: List.from(allWords),
            selectedWordIndices: allIndices,
            wordGenerationProgress: batch + 1,
            isLoadingSuggestions: batch < totalBatches - 1,
          );
        }
      }

      // Ensure loading is cleared if cancelled mid-way
      if (state.isLoadingSuggestions) {
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

  /// Skip suggestions and just complete onboarding. Cancels any ongoing generation.
  Future<bool> skipAndComplete() async {
    if (_user == null) return false;
    _generationCancelled = true;
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
