import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/glass_card.dart';

class FlashcardEmptyState extends StatelessWidget {
  const FlashcardEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.sparkles,
            size: 36,
            color: isDark ? AppColors.accent : AppColors.accentLightMode,
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.foreground : AppColors.foregroundLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No cards due for review.\nTranslate some words below to get started!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.muted : AppColors.mutedLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
