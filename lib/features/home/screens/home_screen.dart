import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../dictionary/providers/dictionary_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/translate_provider.dart';
import '../widgets/flashcard_empty_state.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/grade_buttons.dart';
import '../widgets/translate_input.dart';
import '../widgets/translation_result_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 640;
    final flashcardState = ref.watch(flashcardNotifierProvider);
    final translateState = ref.watch(translateNotifierProvider);

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
        child: Stack(
          children: [
            // Accent glow orbs
            Positioned(
              top: size.height * 0.05,
              right: size.width * 0.1,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.3,
              left: size.width * 0.05,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentLight.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Flashcard header
                        _buildFlashcardHeader(context, flashcardState, isDark)
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: -0.1, end: 0, duration: 500.ms),
                        const SizedBox(height: 12),

                        // Flashcard area
                        _buildFlashcardArea(context, ref, flashcardState)
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 100.ms)
                            .slideY(
                                begin: 0.05,
                                end: 0,
                                duration: 500.ms,
                                delay: 100.ms),

                        // Grade buttons (only when flipped)
                        if (flashcardState.isFlipped &&
                            flashcardState.currentCard != null) ...[
                          const SizedBox(height: 12),
                          GradeButtons(
                            onGrade: (grade) {
                              ref
                                  .read(flashcardNotifierProvider.notifier)
                                  .gradeCard(grade);
                            },
                          ).animate().fadeIn(duration: 300.ms),
                        ],

                        const SizedBox(height: 32),

                        // Translate section
                        TranslateInput(
                          isLoading: translateState.isLoading,
                          onTranslate: (text) {
                            ref
                                .read(translateNotifierProvider.notifier)
                                .translate(text);
                          },
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 200.ms)
                            .slideY(
                                begin: 0.05,
                                end: 0,
                                duration: 500.ms,
                                delay: 200.ms),
                        const SizedBox(height: 16),

                        // Translation loading shimmer
                        if (translateState.isLoading)
                          const Column(
                            children: [
                              ShimmerLoader(height: 200, borderRadius: 16),
                              SizedBox(height: 16),
                            ],
                          ),

                        // Translation error
                        if (translateState.error != null &&
                            !translateState.isLoading)
                          _buildError(context, translateState.error!, isDark),

                        // Translation result
                        if (translateState.result != null &&
                            !translateState.isLoading)
                          TranslationResultCard(
                            result: translateState.result!,
                            isSaving: translateState.isSaving,
                            saved: translateState.saved,
                            onSave: () async {
                              final success = await ref
                                  .read(translateNotifierProvider.notifier)
                                  .saveToDict();
                              if (success && context.mounted) {
                                ref.invalidate(flashcardNotifierProvider);
                                ref.invalidate(dictionaryNotifierProvider);
                                AppToast.show(
                                  context,
                                  message: 'Word saved to dictionary!',
                                  type: ToastType.success,
                                );
                                ref
                                    .read(translateNotifierProvider.notifier)
                                    .clear();
                              }
                            },
                          ).animate().fadeIn(duration: 400.ms).slideY(
                              begin: 0.05, end: 0, duration: 400.ms),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardHeader(
      BuildContext context, FlashcardState state, bool isDark) {
    final count = state.dueCount;
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.accent, AppColors.accentLight],
          ).createShader(bounds),
          child: const Text(
            'Hanly',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.accent : AppColors.accentLightMode)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            state.isLoading
                ? '...'
                : '$count card${count == 1 ? '' : 's'} due',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.accentLight : AppColors.accentLightMode,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlashcardArea(
      BuildContext context, WidgetRef ref, FlashcardState state) {
    if (state.isLoading) {
      return const ShimmerLoader(height: 180, borderRadius: 20);
    }

    if (state.isEmpty) {
      return const FlashcardEmptyState();
    }

    final card = state.currentCard;
    if (card == null) return const SizedBox.shrink();

    return FlashcardWidget(
      card: card,
      isFlipped: state.isFlipped,
      onTap: () {
        ref.read(flashcardNotifierProvider.notifier).flipCard();
      },
    );
  }

  Widget _buildError(BuildContext context, String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.danger : AppColors.dangerLight)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? AppColors.danger : AppColors.dangerLight)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        error,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? AppColors.danger : AppColors.dangerLight,
        ),
      ),
    );
  }
}
