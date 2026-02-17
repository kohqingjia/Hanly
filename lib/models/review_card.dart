import 'example_sentence.dart';
import 'segment.dart';
import 'user_word.dart';

class ReviewCard {
  final String id;
  final String userId;
  final String wordId;
  final double stability;
  final double difficulty;
  final int reps;
  final int lapses;
  final String state;
  final int? lastGrade;
  final DateTime nextReviewAt;
  final DateTime? lastReviewedAt;

  const ReviewCard({
    required this.id,
    required this.userId,
    required this.wordId,
    required this.stability,
    required this.difficulty,
    required this.reps,
    required this.lapses,
    required this.state,
    this.lastGrade,
    required this.nextReviewAt,
    this.lastReviewedAt,
  });

  factory ReviewCard.fromJson(Map<String, dynamic> json) => ReviewCard(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        wordId: json['word_id'] as String,
        stability: (json['stability'] as num).toDouble(),
        difficulty: (json['difficulty'] as num).toDouble(),
        reps: json['reps'] as int,
        lapses: json['lapses'] as int,
        state: json['state'] as String,
        lastGrade: json['last_grade'] as int?,
        nextReviewAt: DateTime.parse(json['next_review_at'] as String),
        lastReviewedAt: json['last_reviewed_at'] != null
            ? DateTime.parse(json['last_reviewed_at'] as String)
            : null,
      );
}

class ReviewCardWithWord {
  final ReviewCard card;
  final UserWord word;

  const ReviewCardWithWord({
    required this.card,
    required this.word,
  });

  factory ReviewCardWithWord.fromRpcJson(Map<String, dynamic> json) {
    return ReviewCardWithWord(
      card: ReviewCard(
        id: json['card_id'] as String,
        userId: '',
        wordId: json['word_id'] as String,
        stability: (json['card_stability'] as num).toDouble(),
        difficulty: (json['card_difficulty'] as num).toDouble(),
        reps: json['card_reps'] as int,
        lapses: json['card_lapses'] as int,
        state: json['card_state'] as String,
        lastGrade: json['card_last_grade'] as int?,
        nextReviewAt: DateTime.parse(json['card_next_review_at'] as String),
        lastReviewedAt: json['card_last_reviewed_at'] != null
            ? DateTime.parse(json['card_last_reviewed_at'] as String)
            : null,
      ),
      word: UserWord(
        id: json['word_id'] as String,
        userId: '',
        english: json['word_english'] as String,
        chinese: json['word_chinese'] as String,
        pinyin: json['word_pinyin'] as String?,
        meaning: json['word_meaning'] as String?,
        notes: json['word_notes'] as String?,
        examples: (json['word_examples'] as List<dynamic>?)
                ?.map((e) =>
                    ExampleSentence.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        segments: (json['word_segments'] as List<dynamic>?)
                ?.map((e) => Segment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        categories: (json['word_categories'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        createdAt: DateTime.parse(json['word_created_at'] as String),
        updatedAt: DateTime.parse(json['word_created_at'] as String),
      ),
    );
  }
}
