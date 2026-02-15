import 'example_sentence.dart';
import 'segment.dart';

class DictionaryEntry {
  final String id;
  final String userId;
  final String english;
  final String chinese;
  final String? pinyin;
  final String? meaning;
  final String? notes;
  final List<ExampleSentence> examples;
  final List<String> tags;
  final bool isMastered;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Segment> segments;

  const DictionaryEntry({
    required this.id,
    required this.userId,
    required this.english,
    required this.chinese,
    this.pinyin,
    this.meaning,
    this.notes,
    this.examples = const [],
    this.tags = const [],
    this.isMastered = false,
    required this.createdAt,
    required this.updatedAt,
    this.segments = const [],
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) =>
      DictionaryEntry(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        english: json['english'] as String,
        chinese: json['chinese'] as String,
        pinyin: json['pinyin'] as String?,
        meaning: json['meaning'] as String?,
        notes: json['notes'] as String?,
        examples: (json['examples'] as List<dynamic>?)
                ?.map((e) =>
                    ExampleSentence.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        isMastered: json['is_mastered'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        segments: (json['segments'] as List<dynamic>?)
                ?.map((e) => Segment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toInsertJson(String userId) => {
        'user_id': userId,
        'english': english,
        'chinese': chinese,
        'pinyin': pinyin,
        'meaning': meaning,
        'notes': notes ?? '',
        'examples': examples.map((e) => e.toJson()).toList(),
        'tags': tags,
        'is_mastered': isMastered,
      };
}
