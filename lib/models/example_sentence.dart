class ExampleSentence {
  final String zh;
  final String pinyin;
  final String en;

  const ExampleSentence({
    required this.zh,
    required this.pinyin,
    required this.en,
  });

  factory ExampleSentence.fromJson(Map<String, dynamic> json) =>
      ExampleSentence(
        zh: json['zh'] as String,
        pinyin: json['pinyin'] as String,
        en: json['en'] as String,
      );

  Map<String, dynamic> toJson() => {'zh': zh, 'pinyin': pinyin, 'en': en};
}
