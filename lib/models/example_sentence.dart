import 'segment.dart';

class ExampleSentence {
  final String zh;
  final String en;
  final List<Segment> segments;

  const ExampleSentence({
    required this.zh,
    required this.en,
    this.segments = const [],
  });

  factory ExampleSentence.fromJson(Map<String, dynamic> json) =>
      ExampleSentence(
        zh: json['zh'] as String,
        en: json['en'] as String,
        segments: (json['segments'] as List<dynamic>?)
                ?.map((e) => Segment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'zh': zh,
        'en': en,
        'segments': segments.map((s) => s.toJson()).toList(),
      };
}
