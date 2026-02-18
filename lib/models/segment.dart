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

  Map<String, dynamic> toJson() => {
        'char': char,
        'py': py,
        if (highlight) 'highlight': true,
      };
}
