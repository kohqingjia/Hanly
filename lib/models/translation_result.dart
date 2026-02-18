import 'example_sentence.dart';
import 'segment.dart';

class TranslationResult {
  final String english;
  final String chinese;
  final String pinyin;
  final String? meaning;
  final String? notes;
  final List<ExampleSentence> examples;
  final List<String> tagsSuggested;
  final List<Segment> segments;

  const TranslationResult({
    required this.english,
    required this.chinese,
    required this.pinyin,
    this.meaning,
    this.notes,
    required this.examples,
    required this.tagsSuggested,
    required this.segments,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json) =>
      TranslationResult(
        english: json['english'] as String,
        chinese: json['chinese'] as String,
        pinyin: json['pinyin'] as String,
        meaning: json['meaning'] as String?,
        notes: json['notes'] as String?,
        examples: (json['examples'] as List<dynamic>?)
                ?.map((e) =>
                    ExampleSentence.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        tagsSuggested: (json['tags_suggested'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        segments: (json['segments'] as List<dynamic>?)
                ?.map((e) => Segment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
