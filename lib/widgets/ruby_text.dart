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

    // Group consecutive segments by highlight status
    final groups = <List<Segment>>[];
    List<Segment> currentGroup = [];

    for (final seg in segments) {
      if (currentGroup.isEmpty) {
        currentGroup = [seg];
      } else if (seg.highlight == currentGroup.first.highlight) {
        currentGroup.add(seg);
      } else {
        groups.add(currentGroup);
        currentGroup = [seg];
      }
    }
    if (currentGroup.isNotEmpty) groups.add(currentGroup);

    return Wrap(
      spacing: 2,
      children: groups.map((group) {
        final widgets = group
            .map((seg) => _buildSegment(seg, isDark, pyColor))
            .toList();

        if (group.first.highlight) {
          // Wrap consecutive highlighted segments in a single container
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.accent : AppColors.accentLightMode)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: widgets,
            ),
          );
        }

        // Non-highlighted: return individual widgets
        if (widgets.length == 1) return widgets.first;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: widgets,
        );
      }).toList(),
    );
  }

  Widget _buildSegment(Segment seg, bool isDark, Color pyColor) {
    final isPunctuation =
        RegExp(r'^[，。！？、；：\u201C\u201D\u2018\u2019（）\s.!?,;:()]+$')
            .hasMatch(seg.char);
    final isAscii = RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(seg.char);

    if (isPunctuation || isAscii) {
      return Text(
        seg.char,
        style: TextStyle(
          fontSize: charSize,
          fontWeight: FontWeight.w500,
        ),
      );
    }

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
  }
}
