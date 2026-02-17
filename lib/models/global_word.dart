import 'segment.dart';

class GlobalWord {
  final String id;
  final String chinese;
  final String pinyin;
  final List<Segment> segments;
  final String? meaning;
  final List<String> categories;
  final int addCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GlobalWord({
    required this.id,
    required this.chinese,
    required this.pinyin,
    this.segments = const [],
    this.meaning,
    this.categories = const [],
    this.addCount = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GlobalWord.fromJson(Map<String, dynamic> json) => GlobalWord(
        id: json['id'] as String,
        chinese: json['chinese'] as String,
        pinyin: json['pinyin'] as String,
        segments: (json['segments'] as List<dynamic>?)
                ?.map((e) => Segment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        meaning: json['meaning'] as String?,
        categories: (json['categories'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        addCount: json['add_count'] as int? ?? 1,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
