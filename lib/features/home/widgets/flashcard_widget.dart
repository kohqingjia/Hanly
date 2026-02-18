import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/review_card.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/ruby_text.dart';

class FlashcardWidget extends StatelessWidget {
  final ReviewCardWithWord card;
  final bool isFlipped;
  final VoidCallback onTap;

  const FlashcardWidget({
    super.key,
    required this.card,
    required this.isFlipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        variant: GlassVariant.elevated,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: isFlipped
              ? _buildBack(context, isDark)
              : _buildFront(context, isDark),
        ),
      ),
    );
  }

  Widget _buildFront(BuildContext context, bool isDark) {
    return Column(
      key: const ValueKey('front'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Text(
          card.word.english,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.foreground : AppColors.foregroundLight,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Tap to reveal',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.muted : AppColors.mutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildBack(BuildContext context, bool isDark) {
    final segments = card.word.segments;
    final hasPinyin =
        card.word.pinyin != null && card.word.pinyin!.isNotEmpty;

    return Column(
      key: const ValueKey('back'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (segments.isNotEmpty)
          RubyText(
            segments: segments,
            charSize: 32,
            pinyinSize: 12,
          )
        else ...[
          if (hasPinyin)
            Text(
              card.word.pinyin!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.accent : AppColors.accentLightMode,
              ),
            ),
          if (hasPinyin) const SizedBox(height: 4),
          Text(
            card.word.chinese,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (card.word.meaning != null &&
            card.word.meaning!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            card.word.meaning!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.foreground : AppColors.foregroundLight,
              height: 1.5,
            ),
          ),
        ],
        if (card.word.examples.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card.word.examples.first.segments.isNotEmpty)
                  RubyText(
                    segments: card.word.examples.first.segments,
                    charSize: 14,
                    pinyinSize: 9,
                  )
                else
                  Text(
                    card.word.examples.first.zh,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.foreground
                          : AppColors.foregroundLight,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  card.word.examples.first.en,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.muted : AppColors.mutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
