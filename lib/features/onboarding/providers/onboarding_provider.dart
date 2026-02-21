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

  const OnboardingState({
    this.currentStep = 0,
    this.displayName,
    this.ageRange,
    this.focusAreas = const [],
    this.additionalContext,
    this.isSubmitting = false,
    this.error,
  });

  // Steps: 0=Name+Age, 1=Focus Areas, 2=Additional Context
  int get totalSteps => 3;
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

  /// Submit profile data, generate context, then complete onboarding.
  Future<bool> submitAndComplete() async {
    if (_user == null) return false;
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

      // Step 2: Save profile and mark onboarding complete
      await _client.from('profiles').update({
        'display_name': state.displayName,
        'focus_areas': state.focusAreas,
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
