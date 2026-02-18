import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../models/profile.dart';
import '../../../models/translation_result.dart';
import '../../profile/providers/profile_provider.dart';

class TranslateState {
  final bool isLoading;
  final TranslationResult? result;
  final String? error;
  final bool isSaving;
  final bool saved;

  const TranslateState({
    this.isLoading = false,
    this.result,
    this.error,
    this.isSaving = false,
    this.saved = false,
  });

  TranslateState copyWith({
    bool? isLoading,
    TranslationResult? result,
    String? error,
    bool? isSaving,
    bool? saved,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return TranslateState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
      saved: saved ?? this.saved,
    );
  }
}

class TranslateNotifier extends StateNotifier<TranslateState> {
  final SupabaseClient _client;
  final User? _user;
  final Profile? _profile;

  TranslateNotifier(this._client, this._user, this._profile)
      : super(const TranslateState());

  Future<void> translate(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    state = state.copyWith(
      isLoading: true,
      clearResult: true,
      clearError: true,
      saved: false,
    );

    try {
      final response = await _client.functions.invoke(
        'translate',
        body: {
          'text': trimmed,
          'user_context_summary': _profile?.contextSummary,
          'user_context_tags': _profile?.contextTags,
        },
      );

      if (response.status != 200) {
        throw Exception('Translation failed (${response.status})');
      }

      final rawData = response.data;
      final Map<String, dynamic> data = rawData is String
          ? jsonDecode(rawData) as Map<String, dynamic>
          : rawData as Map<String, dynamic>;
      final result = TranslationResult.fromJson(data);

      state = state.copyWith(
        isLoading: false,
        result: result,
      );
    } on FunctionException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:
            'Translation failed: ${e.details?['message'] ?? e.reasonPhrase ?? 'Unknown error'}',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> saveToDict() async {
    final result = state.result;
    if (result == null || _user == null) return false;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final response = await _client.functions.invoke(
        'save-word',
        body: {
          'english': result.english,
          'chinese': result.chinese,
          'pinyin': result.pinyin,
          'meaning': result.meaning ?? '',
          'notes': result.notes ?? '',
          'examples': result.examples.map((e) => e.toJson()).toList(),
          'segments': result.segments.map((s) => s.toJson()).toList(),
          'categories': result.tagsSuggested,
        },
      );

      if (response.status != 200) {
        throw Exception('Save failed');
      }

      state = state.copyWith(isSaving: false, saved: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clear() {
    state = const TranslateState();
  }
}

final translateNotifierProvider =
    StateNotifierProvider<TranslateNotifier, TranslateState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  final profile = ref.watch(profileProvider).value;
  return TranslateNotifier(client, user, profile);
});
