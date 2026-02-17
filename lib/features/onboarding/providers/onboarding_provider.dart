import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';

class OnboardingState {
  final int currentStep;
  final String? chineseLevel;
  final List<String> learningPurposes;
  final String? industry;
  final String? additionalContext;
  final bool isSubmitting;
  final String? error;

  const OnboardingState({
    this.currentStep = 0,
    this.chineseLevel,
    this.learningPurposes = const [],
    this.industry,
    this.additionalContext,
    this.isSubmitting = false,
    this.error,
  });

  bool get needsIndustry =>
      learningPurposes.contains('Work') ||
      learningPurposes.contains('Career Advancement');

  int get totalSteps => needsIndustry ? 4 : 3;

  OnboardingState copyWith({
    int? currentStep,
    String? chineseLevel,
    List<String>? learningPurposes,
    String? industry,
    String? additionalContext,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    bool clearIndustry = false,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      chineseLevel: chineseLevel ?? this.chineseLevel,
      learningPurposes: learningPurposes ?? this.learningPurposes,
      industry: clearIndustry ? null : (industry ?? this.industry),
      additionalContext: additionalContext ?? this.additionalContext,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final SupabaseClient _client;
  final User? _user;

  OnboardingNotifier(this._client, this._user)
      : super(const OnboardingState());

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
    // If removing work/career, clear industry
    final needsIndustry =
        purposes.contains('Work') || purposes.contains('Career Advancement');
    state = state.copyWith(
      learningPurposes: purposes,
      clearIndustry: !needsIndustry,
    );
  }

  void setIndustry(String? industry) {
    state = state.copyWith(industry: industry);
  }

  void setAdditionalContext(String? text) {
    state = state.copyWith(additionalContext: text);
  }

  void nextStep() {
    // Skip industry step if not needed
    int next = state.currentStep + 1;
    if (next == 2 && !state.needsIndustry) {
      next = 3; // Skip to additional context
    }
    state = state.copyWith(currentStep: next);
  }

  void previousStep() {
    int prev = state.currentStep - 1;
    if (prev == 2 && !state.needsIndustry) {
      prev = 1; // Skip back over industry
    }
    if (prev < 0) prev = 0;
    state = state.copyWith(currentStep: prev);
  }

  Future<bool> submit() async {
    if (_user == null) return false;
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      // Call generate-context edge function
      final response = await _client.functions.invoke(
        'generate-context',
        body: {
          'chinese_level': state.chineseLevel,
          'learning_purposes': state.learningPurposes,
          'industry': state.industry,
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

      // Update profile with all onboarding data
      await _client.from('profiles').update({
        'chinese_level': state.chineseLevel,
        'learning_purposes': state.learningPurposes,
        'industry': state.industry,
        'additional_context': state.additionalContext,
        'context_summary': contextSummary,
        'context_tags': contextTags,
        'onboarding_completed': true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _user.id);

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
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
