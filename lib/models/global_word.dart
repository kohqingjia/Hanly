class GlobalWord {
  final String id;
  final String chinese;
  final String pinyin;
  final String? meaning;
  final int addCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GlobalWord({
    required this.id,
    required this.chinese,
    required this.pinyin,
    this.meaning,
    this.addCount = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GlobalWord.fromJson(Map<String, dynamic> json) => GlobalWord(
        id: json['id'] as String,
        chinese: json['chinese'] as String,
        pinyin: json['pinyin'] as String,
        meaning: json['meaning'] as String?,
        addCount: json['add_count'] as int? ?? 1,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
