class Segment {
  final String char;
  final String py;

  const Segment({required this.char, required this.py});

  factory Segment.fromJson(Map<String, dynamic> json) => Segment(
        char: json['char'] as String,
        py: json['py'] as String,
      );

  Map<String, dynamic> toJson() => {'char': char, 'py': py};
}
