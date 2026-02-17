import 'example_sentence.dart';
import 'segment.dart';

class UserWord {
  final String id;
  final String userId;
  final String? globalWordId;
  final String english;
  final String chinese;
  final String? pinyin;
  final String? meaning;
  final String? notes;
  final List<ExampleSentence> examples;
  final List<Segment> segments;
  final List<String> categories;
  final String source;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserWord({
    required this.id,
    required this.userId,
    this.globalWordId,
    required this.english,
    required this.chinese,
    this.pinyin,
    this.meaning,
    this.notes,
    this.examples = const [],
    this.segments = const [],
    this.categories = const [],
    this.source = 'manual',
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserWord.fromJson(Map<String, dynamic> json) => UserWord(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        globalWordId: json['global_word_id'] as String?,
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
        segments: (json['segments'] as List<dynamic>?)
                ?.map((e) => Segment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        categories: (json['categories'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        source: json['source'] as String? ?? 'manual',
        isArchived: json['is_archived'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'english': english,
        'chinese': chinese,
        'pinyin': pinyin,
        'meaning': meaning,
        'notes': notes,
        'examples': examples.map((e) => e.toJson()).toList(),
        'segments': segments.map((s) => s.toJson()).toList(),
        'categories': categories,
        'source': source,
        'is_archived': isArchived,
      };
}
