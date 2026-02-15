import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/segment.dart';

class RubyText extends StatelessWidget {
  final List<Segment> segments;
  final double charSize;
  final double pinyinSize;
  final Color? pinyinColor;

  const RubyText({
    super.key,
    required this.segments,
    this.charSize = 28,
    this.pinyinSize = 10,
    this.pinyinColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pyColor =
        pinyinColor ?? (isDark ? AppColors.accent : AppColors.accentLightMode);

    return Wrap(
      spacing: 2,
      children: segments.map((seg) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (seg.py.isNotEmpty)
              Text(
                seg.py,
                style: TextStyle(
                  fontSize: pinyinSize,
                  color: pyColor,
                  height: 1.2,
                ),
              ),
            if (seg.py.isNotEmpty) const SizedBox(height: 2),
            Text(
              seg.char,
              style: TextStyle(
                fontSize: charSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
