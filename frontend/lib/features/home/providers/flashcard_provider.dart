import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/utils/sm2.dart';
import '../../../models/dictionary_entry.dart';
import '../../../models/flashcard_progress.dart';

class FlashcardState {
  final bool isLoading;
  final List<FlashcardWithEntry> dueCards;
  final int currentIndex;
  final bool isFlipped;
  final String? error;

  const FlashcardState({
    this.isLoading = false,
    this.dueCards = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.error,
  });

  int get dueCount => dueCards.length;

  FlashcardWithEntry? get currentCard =>
      dueCards.isEmpty ? null : dueCards[currentIndex];

  bool get isEmpty => dueCards.isEmpty && !isLoading;

  FlashcardState copyWith({
    bool? isLoading,
    List<FlashcardWithEntry>? dueCards,
    int? currentIndex,
    bool? isFlipped,
    String? error,
  }) {
    return FlashcardState(
      isLoading: isLoading ?? this.isLoading,
      dueCards: dueCards ?? this.dueCards,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      error: error,
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
      final response = await _client
          .from('flashcard_progress')
          .select('*, dictionary_entries(*)')
          .eq('user_id', _user.id)
          .lte('next_review_at', DateTime.now().toUtc().toIso8601String())
          .order('next_review_at', ascending: true);

      final cards = (response as List).map((row) {
        final progress = FlashcardProgress.fromJson(row);
        final entry = DictionaryEntry.fromJson(
            row['dictionary_entries'] as Map<String, dynamic>);
        return FlashcardWithEntry(progress: progress, entry: entry);
      }).toList();

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

  Future<void> gradeCard(Grade grade) async {
    final card = state.currentCard;
    if (card == null) return;

    final result = calculateNext(
      ease: card.progress.ease,
      intervalDays: card.progress.intervalDays,
      repetitions: card.progress.repetitions,
      grade: grade,
    );

    try {
      await _client.from('flashcard_progress').update({
        'ease': result.ease,
        'interval_days': result.intervalDays,
        'repetitions': result.repetitions,
        'next_review_at': result.nextReviewAt.toUtc().toIso8601String(),
        'last_reviewed_at': result.lastReviewedAt.toUtc().toIso8601String(),
      }).eq('id', card.progress.id);

      final updatedCards = List<FlashcardWithEntry>.from(state.dueCards)
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
}

final flashcardNotifierProvider =
    StateNotifierProvider<FlashcardNotifier, FlashcardState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return FlashcardNotifier(client, user);
});
