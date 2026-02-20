import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/review_card.dart';
import '../../../models/segment.dart';
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
    return ConstrainedBox(
      key: const ValueKey('front'),
      constraints: const BoxConstraints(minHeight: 220),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
        const SizedBox(height: 8),
        Text(
          'ENGLISH',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.muted : AppColors.mutedLight,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          card.word.english,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.foreground : AppColors.foregroundLight,
            letterSpacing: -0.5,
          ),
        ),
        if (card.word.meaning != null && card.word.meaning!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            card.word.meaning!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.muted : AppColors.mutedLight,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Tap to reveal',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.muted : AppColors.mutedLight,
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildBack(BuildContext context, bool isDark) {
    final segments = card.word.segments;
    final hasPinyin =
        card.word.pinyin != null && card.word.pinyin!.isNotEmpty;

    return ConstrainedBox(
      key: const ValueKey('back'),
      constraints: const BoxConstraints(minHeight: 220),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chinese characters with pinyin
          if (segments.isNotEmpty) ...[
            // RubyText already shows pinyin above characters, no need for separate line
            Center(
              child: RubyText(
                segments: segments,
                charSize: 32,
                pinyinSize: 12,
              ),
            ),
          ] else ...[
            // No segments — show pinyin as plain text + plain Chinese
            if (hasPinyin)
              Center(
                child: Text(
                  card.word.pinyin!,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark ? AppColors.accent : AppColors.accentLightMode,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (hasPinyin) const SizedBox(height: 4),
            Center(
              child: Text(
                card.word.chinese,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.foreground
                      : AppColors.foregroundLight,
                ),
              ),
            ),
          ],

          // Meaning
          if (card.word.meaning != null &&
              card.word.meaning!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'MEANING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.muted : AppColors.mutedLight,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.word.meaning!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.foreground : AppColors.foregroundLight,
                height: 1.5,
              ),
            ),
          ],

          // Example sentence
          if (card.word.examples.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (card.word.examples.first.segments.isNotEmpty)
                    RubyText(
                      segments: Segment.withHighlights(
                        card.word.examples.first.segments,
                        card.word.chinese,
                      ),
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
        ),
      ),
    );
  }
}
