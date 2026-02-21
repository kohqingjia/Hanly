import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/shimmer_loader.dart';
import '../../dictionary/providers/dictionary_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/translate_provider.dart';
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
    final dueCount = flashcardState.dueCount;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
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
                        // App title
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
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: -0.1, end: 0, duration: 500.ms),
                        const SizedBox(height: 16),

                        // Quiz & Flashcard buttons
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  AppToast.show(
                                    context,
                                    message: 'Quiz coming soon!',
                                    type: ToastType.info,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.06),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        LucideIcons.brain,
                                        size: 16,
                                        color: isDark
                                            ? AppColors.muted
                                            : AppColors.mutedLight,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Quiz',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? AppColors.muted
                                              : AppColors.mutedLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.push('/flashcards'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.accent, AppColors.accentLight],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
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
                                      const Icon(
                                        LucideIcons.layers,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Flashcards',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (dueCount > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '$dueCount',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 100.ms)
                            .slideY(
                                begin: 0.05,
                                end: 0,
                                duration: 500.ms,
                                delay: 100.ms),
                        const SizedBox(height: 16),

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
                            .fadeIn(duration: 500.ms, delay: 150.ms)
                            .slideY(
                                begin: 0.05,
                                end: 0,
                                duration: 500.ms,
                                delay: 150.ms),
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
