import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../models/user_word.dart';

class DictionaryState {
  final bool isLoading;
  final List<UserWord> words;
  final String searchQuery;
  final bool showArchived;
  final String? error;

  const DictionaryState({
    this.isLoading = false,
    this.words = const [],
    this.searchQuery = '',
    this.showArchived = false,
    this.error,
  });

  DictionaryState copyWith({
    bool? isLoading,
    List<UserWord>? words,
    String? searchQuery,
    bool? showArchived,
    String? error,
    bool clearError = false,
  }) {
    return DictionaryState(
      isLoading: isLoading ?? this.isLoading,
      words: words ?? this.words,
      searchQuery: searchQuery ?? this.searchQuery,
      showArchived: showArchived ?? this.showArchived,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DictionaryNotifier extends StateNotifier<DictionaryState> {
  final SupabaseClient _client;
  final User? _user;

  DictionaryNotifier(this._client, this._user)
      : super(const DictionaryState()) {
    loadWords();
  }

  Future<void> loadWords() async {
    if (_user == null) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _client
          .from('user_words')
          .select()
          .eq('user_id', _user.id)
          .eq('is_archived', state.showArchived)
          .order('created_at', ascending: false);

      final words = (response as List)
          .map((row) => UserWord.fromJson(row as Map<String, dynamic>))
          .toList();

      state = state.copyWith(isLoading: false, words: words);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    if (_user == null) return;

    if (query.trim().isEmpty) {
      loadWords();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _client.rpc('search_user_words', params: {
        'p_user_id': _user.id,
        'p_query': query.trim(),
        'p_archived': state.showArchived,
      });

      final words = (response as List)
          .map((row) => UserWord.fromJson(row as Map<String, dynamic>))
          .toList();

      state = state.copyWith(isLoading: false, words: words);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> archiveWord(String id) async {
    try {
      await _client
          .from('user_words')
          .update({
            'is_archived': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
      loadWords();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> unarchiveWord(String id) async {
    try {
      await _client
          .from('user_words')
          .update({
            'is_archived': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
      loadWords();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteWord(String id) async {
    try {
      await _client.from('user_words').delete().eq('id', id);
      loadWords();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void toggleArchiveView() {
    state = state.copyWith(showArchived: !state.showArchived, searchQuery: '');
    loadWords();
  }
}

final dictionaryNotifierProvider =
    StateNotifierProvider<DictionaryNotifier, DictionaryState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return DictionaryNotifier(client, user);
});
