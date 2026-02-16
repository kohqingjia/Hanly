import 'dictionary_entry.dart';

class FlashcardProgress {
  final String id;
  final String userId;
  final String entryId;
  final double ease;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReviewAt;
  final DateTime? lastReviewedAt;

  const FlashcardProgress({
    required this.id,
    required this.userId,
    required this.entryId,
    required this.ease,
    required this.intervalDays,
    required this.repetitions,
    required this.nextReviewAt,
    this.lastReviewedAt,
  });

  factory FlashcardProgress.fromJson(Map<String, dynamic> json) =>
      FlashcardProgress(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        entryId: json['entry_id'] as String,
        ease: (json['ease'] as num).toDouble(),
        intervalDays: json['interval_days'] as int,
        repetitions: json['repetitions'] as int,
        nextReviewAt: DateTime.parse(json['next_review_at'] as String),
        lastReviewedAt: json['last_reviewed_at'] != null
            ? DateTime.parse(json['last_reviewed_at'] as String)
            : null,
      );
}

class FlashcardWithEntry {
  final FlashcardProgress progress;
  final DictionaryEntry entry;

  const FlashcardWithEntry({
    required this.progress,
    required this.entry,
  });
}
