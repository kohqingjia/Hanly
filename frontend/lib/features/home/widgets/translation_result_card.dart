import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/translation_result.dart';
import '../../../widgets/glass_card.dart';

class TranslationResultCard extends StatelessWidget {
  final TranslationResult result;
  final bool isSaving;
  final bool saved;
  final VoidCallback onSave;

  const TranslationResultCard({
    super.key,
    required this.result,
    required this.isSaving,
    required this.saved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pinyin
          Text(
            result.pinyin,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.accent : AppColors.accentLightMode,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          // Chinese characters
          Text(
            result.segments.isNotEmpty
                ? result.segments.map((s) => s.char).join(' ')
                : result.chinese,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.foreground : AppColors.foregroundLight,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 20),

          // MEANING label
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

          // Meaning text
          Text(
            result.meaning,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.foreground : AppColors.foregroundLight,
              height: 1.5,
            ),
          ),

          // Examples
          if (result.examples.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'EXAMPLES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.muted : AppColors.mutedLight,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ...result.examples.map((ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
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
                        // Pinyin for sentence
                        if (ex.pinyin.isNotEmpty)
                          Text(
                            ex.pinyin,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.accent
                                  : AppColors.accentLightMode,
                            ),
                          ),
                        if (ex.pinyin.isNotEmpty) const SizedBox(height: 2),
                        // Chinese sentence
                        Text(
                          ex.zh,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.foreground
                                : AppColors.foregroundLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // English translation
                        Text(
                          ex.en,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDark ? AppColors.muted : AppColors.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],

          // Tags
          if (result.tagsSuggested.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: result.tagsSuggested.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.accent : AppColors.accentLightMode)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? AppColors.accentLight : AppColors.accentLightMode,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 20),

          // Save to Dictionary button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: saved || isSaving ? null : onSave,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: saved
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentLight],
                        ),
                  color: saved
                      ? (isDark ? AppColors.success : AppColors.successLight)
                          .withValues(alpha: 0.15)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: saved
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSaving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else ...[
                      Icon(
                        saved ? LucideIcons.checkCircle : LucideIcons.bookPlus,
                        size: 18,
                        color: saved
                            ? (isDark
                                ? AppColors.success
                                : AppColors.successLight)
                            : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        saved ? 'Saved!' : 'Save to Dictionary',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: saved
                              ? (isDark
                                  ? AppColors.success
                                  : AppColors.successLight)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
