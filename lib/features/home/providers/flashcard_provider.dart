import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/utils/fsrs.dart';
import '../../../models/review_card.dart';

class FlashcardState {
  final bool isLoading;
  final List<ReviewCardWithWord> dueCards;
  final int currentIndex;
  final bool isFlipped;
  final String? error;
  final String? categoryFilter;

  const FlashcardState({
    this.isLoading = false,
    this.dueCards = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.error,
    this.categoryFilter,
  });

  int get dueCount => dueCards.length;

  ReviewCardWithWord? get currentCard =>
      dueCards.isEmpty ? null : dueCards[currentIndex];

  bool get isEmpty => dueCards.isEmpty && !isLoading;

  FlashcardState copyWith({
    bool? isLoading,
    List<ReviewCardWithWord>? dueCards,
    int? currentIndex,
    bool? isFlipped,
    String? error,
    String? categoryFilter,
    bool clearCategory = false,
  }) {
    return FlashcardState(
      isLoading: isLoading ?? this.isLoading,
      dueCards: dueCards ?? this.dueCards,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      error: error,
      categoryFilter:
          clearCategory ? null : (categoryFilter ?? this.categoryFilter),
    );
  }
}

class FlashcardNotifier extends StateNotifier<FlashcardState> {
  final SupabaseClient _client;
  final User? _user;

  FlashcardNotifier(this._client, this._user)
      : super(const FlashcardState()) {
    loadDueCards();
  }

  Future<void> loadDueCards() async {
    if (_user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _client.rpc('get_due_cards', params: {
        'p_user_id': _user.id,
        'p_category': state.categoryFilter,
      });

      final cards = (response as List)
          .map((row) =>
              ReviewCardWithWord.fromRpcJson(row as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        dueCards: cards,
        currentIndex: 0,
        isFlipped: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void flipCard() {
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  Future<void> gradeCard(FSRSGrade grade) async {
    final card = state.currentCard;
    if (card == null) return;

    final result = calculateFSRS(
      currentStability: card.card.stability,
      currentDifficulty: card.card.difficulty,
      reps: card.card.reps,
      lapses: card.card.lapses,
      state: card.card.state,
      grade: grade,
    );

    try {
      await _client.from('review_cards').update({
        'stability': result.stability,
        'difficulty': result.difficulty,
        'reps': result.reps,
        'lapses': result.lapses,
        'state': result.state,
        'last_grade': result.grade,
        'next_review_at': result.nextReviewAt.toUtc().toIso8601String(),
        'last_reviewed_at': result.lastReviewedAt.toUtc().toIso8601String(),
      }).eq('id', card.card.id);

      final updatedCards = List<ReviewCardWithWord>.from(state.dueCards)
        ..removeAt(state.currentIndex);

      final nextIndex =
          updatedCards.isEmpty ? 0 : state.currentIndex % updatedCards.length;

      state = state.copyWith(
        dueCards: updatedCards,
        currentIndex: nextIndex,
        isFlipped: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setCategoryFilter(String? category) {
    if (category == state.categoryFilter) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(categoryFilter: category);
    }
    loadDueCards();
  }
}

final flashcardNotifierProvider =
    StateNotifierProvider<FlashcardNotifier, FlashcardState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return FlashcardNotifier(client, user);
});
