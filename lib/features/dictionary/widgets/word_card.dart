import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_word.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/ruby_text.dart';

class WordCard extends StatelessWidget {
  final UserWord word;
  final bool isArchived;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const WordCard({
    super.key,
    required this.word,
    required this.isArchived,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pinyin + Chinese characters via RubyText, or plain Chinese fallback
                    if (word.segments.isNotEmpty)
                      RubyText(
                        segments: word.segments,
                        charSize: 24,
                        pinyinSize: 10,
                      )
                    else ...[
                      // Show pinyin separately when no segments
                      if (word.pinyin != null && word.pinyin!.isNotEmpty)
                        Text(
                          word.pinyin!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.accent
                                : AppColors.accentLightMode,
                          ),
                        ),
                      Text(
                        word.chinese,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.foreground
                              : AppColors.foregroundLight,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // English translation
                    Text(
                      word.english,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.foreground
                            : AppColors.foregroundLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Menu button
              PopupMenuButton<String>(
                icon: Icon(
                  LucideIcons.moreVertical,
                  size: 18,
                  color: isDark ? AppColors.muted : AppColors.mutedLight,
                ),
                color: isDark ? AppColors.backgroundElevated : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'archive') {
                    onArchive();
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, isDark);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(
                          isArchived
                              ? LucideIcons.archiveRestore
                              : LucideIcons.archive,
                          size: 16,
                          color: isDark
                              ? AppColors.foreground
                              : AppColors.foregroundLight,
                        ),
                        const SizedBox(width: 8),
                        Text(isArchived ? 'Unarchive' : 'Archive'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color:
                              isDark ? AppColors.danger : AppColors.dangerLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.danger
                                : AppColors.dangerLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Meaning
          if (word.meaning != null && word.meaning!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              word.meaning!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.muted : AppColors.mutedLight,
                height: 1.4,
              ),
            ),
          ],
          // Example sentence (show first one)
          if (word.examples.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
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
                  if (word.examples.first.pinyin.isNotEmpty)
                    Text(
                      word.examples.first.pinyin,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.accent
                            : AppColors.accentLightMode,
                      ),
                    ),
                  if (word.examples.first.pinyin.isNotEmpty)
                    const SizedBox(height: 2),
                  Text(
                    word.examples.first.zh,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.foreground
                          : AppColors.foregroundLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    word.examples.first.en,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.muted : AppColors.mutedLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Category pills
          if (word.categories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: word.categories.map((cat) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.accent
                            : AppColors.accentLightMode)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.accentLight
                          : AppColors.accentLightMode,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.backgroundElevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete word?'),
        content: Text(
          'This will permanently delete "${word.english}" and its review progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor:
                  isDark ? AppColors.danger : AppColors.dangerLight,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
