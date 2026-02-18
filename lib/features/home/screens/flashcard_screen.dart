import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/shimmer_loader.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/flashcard_empty_state.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/grade_buttons.dart';

class FlashcardScreen extends ConsumerWidget {
  const FlashcardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(flashcardNotifierProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.background,
                    const Color(0xFF0F0F1A),
                    const Color(0xFF0A0A1F),
                  ]
                : [
                    AppColors.backgroundLight,
                    const Color(0xFFF0F0FF),
                    const Color(0xFFE8E8FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          LucideIcons.arrowLeft,
                          size: 20,
                          color: isDark
                              ? AppColors.foreground
                              : AppColors.foregroundLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Flashcards',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.foreground
                            : AppColors.foregroundLight,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.accent
                                : AppColors.accentLightMode)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        state.isLoading
                            ? '...'
                            : '${state.dueCount} remaining',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.accentLight
                              : AppColors.accentLightMode,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main content area
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildContent(context, ref, state, isDark),
                    ),
                  ),
                ),
              ),

              // Grade buttons (fixed at bottom)
              if (state.isFlipped && state.currentCard != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: GradeButtons(
                      onGrade: (grade) {
                        ref
                            .read(flashcardNotifierProvider.notifier)
                            .gradeCard(grade);
                      },
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, FlashcardState state, bool isDark) {
    if (state.isLoading) {
      return const ShimmerLoader(height: 220, borderRadius: 20);
    }

    if (state.isEmpty) {
      return const FlashcardEmptyState();
    }

    final card = state.currentCard;
    if (card == null) return const SizedBox.shrink();

    return SizedBox(
      height: 280,
      child: FlashcardWidget(
        card: card,
        isFlipped: state.isFlipped,
        onTap: () {
          ref.read(flashcardNotifierProvider.notifier).flipCard();
        },
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
