class Segment {
  final String char;
  final String py;
  final bool highlight;

  const Segment({required this.char, required this.py, this.highlight = false});

  factory Segment.fromJson(Map<String, dynamic> json) => Segment(
        char: json['char'] as String,
        py: json['py'] as String,
        highlight: json['highlight'] as bool? ?? false,
      );

  Segment copyWith({bool? highlight}) => Segment(
        char: char,
        py: py,
        highlight: highlight ?? this.highlight,
      );

  Map<String, dynamic> toJson() => {
        'char': char,
        'py': py,
        if (highlight) 'highlight': true,
      };

  /// Returns segments with highlight computed from the vocabulary word's characters.
  /// A segment is highlighted if any of its characters appear in [vocabChinese].
  static List<Segment> withHighlights(
      List<Segment> segments, String vocabChinese) {
    return segments.map((seg) {
      final shouldHighlight =
          seg.char.runes.any((r) => vocabChinese.runes.contains(r));
      return shouldHighlight ? seg.copyWith(highlight: true) : seg;
    }).toList();
  }
}
