import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_decoration.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/app_toast.dart';
import '../../home/providers/flashcard_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  final _nameController = TextEditingController();
  final _contextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    ref.listen(onboardingProvider, (prev, next) {
      if (prev?.currentStep != next.currentStep) {
        _goToPage(next.currentStep);
      }
    });

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
              top: size.height * 0.08,
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
              bottom: size.height * 0.2,
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
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Progress indicator
                  _buildProgressDots(state, isDark),
                  const SizedBox(height: 8),
                  // Page content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildNameAgeStep(state, isDark),
                        _buildFocusAreasStep(state, isDark),
                        _buildContextStep(state, isDark),
                        _buildSuggestionsStep(state, isDark),
                      ],
                    ),
                  ),
                  // Navigation buttons (hidden on suggestions step — it has its own)
                  if (state.currentStep != state.suggestionsStep)
                    _buildNavButtons(state, isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots(OnboardingState state, bool isDark) {
    final total = state.totalSteps;
    final current = state.currentStep;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i <= current;
        return Container(
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? AppColors.accent : AppColors.accentLightMode)
                : (isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    ).animate().fadeIn(duration: 400.ms);
  }

  // Step 0: Name + Age
  Widget _buildNameAgeStep(OnboardingState state, bool isDark) {
    const ageRanges = [
      'Under 18',
      '18-24',
      '25-34',
      '35-44',
      '45-54',
      '55+',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.accent, AppColors.accentLight],
              ).createShader(bounds),
              child: const Text(
                'Welcome to Hanly',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Let's get to know you",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.foreground : AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 32),
            // Name field
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'YOUR NAME',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.muted : AppColors.mutedLight,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: GlassDecoration.card(context),
                  padding: const EdgeInsets.all(4),
                  child: TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.foreground
                          : AppColors.foregroundLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      hintStyle: TextStyle(
                        fontSize: 18,
                        color: isDark ? AppColors.muted : AppColors.mutedLight,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                    onChanged: (text) {
                      ref
                          .read(onboardingProvider.notifier)
                          .setDisplayName(text.trim().isEmpty ? null : text.trim());
                    },
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),
            const SizedBox(height: 24),
            // Age Range (optional)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'AGE RANGE (OPTIONAL)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.muted : AppColors.mutedLight,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ageRanges.map((range) {
                final isSelected = state.ageRange == range;
                return GestureDetector(
                  onTap: () {
                    ref.read(onboardingProvider.notifier).setAgeRange(
                          isSelected ? null : range,
                        );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                                  ? AppColors.accent
                                  : AppColors.accentLightMode)
                              .withValues(alpha: 0.2)
                          : isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                ? AppColors.accent
                                : AppColors.accentLightMode)
                            : isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      range,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? (isDark
                                ? AppColors.accentLight
                                : AppColors.accentLightMode)
                            : (isDark
                                ? AppColors.foreground
                                : AppColors.foregroundLight),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          ],
        ),
      ),
    );
  }

  // Step 1: Focus Areas
  Widget _buildFocusAreasStep(OnboardingState state, bool isDark) {
    const focusAreas = [
      'Data & Analytics',
      'Data Engineering',
      'Cloud Computing',
      'Machine Learning & AI',
      'Software Engineering',
      'Product Management',
      'Business & Strategy',
      'Marketing & Growth',
      'Finance & Accounting',
      'Operations & Supply Chain',
      'Design & UX',
      'Cybersecurity',
      'E-commerce',
      'Hardware & IoT',
      'DevOps & Infrastructure',
      'General Tech',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Text(
              "What's your specialization?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.foreground : AppColors.foregroundLight,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Select all that apply — we'll tailor your vocabulary",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.muted : AppColors.mutedLight,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: focusAreas.asMap().entries.map((entry) {
                final area = entry.value;
                final isSelected = state.focusAreas.contains(area);
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(onboardingProvider.notifier)
                        .toggleFocusArea(area);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                                  ? AppColors.accent
                                  : AppColors.accentLightMode)
                              .withValues(alpha: 0.2)
                          : isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                ? AppColors.accent
                                : AppColors.accentLightMode)
                            : isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      area,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? (isDark
                                ? AppColors.accentLight
                                : AppColors.accentLightMode)
                            : (isDark
                                ? AppColors.foreground
                                : AppColors.foregroundLight),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(
                        duration: 300.ms,
                        delay: Duration(milliseconds: 20 * entry.key))
                    .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        duration: 300.ms,
                        delay: Duration(milliseconds: 20 * entry.key));
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Step 2: Additional Context
  Widget _buildContextStep(OnboardingState state, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Tell us more',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.foreground : AppColors.foregroundLight,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Any additional context helps us personalize your vocabulary',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.muted : AppColors.mutedLight,
                ),
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'ADDITIONAL CONTEXT (OPTIONAL)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.muted : AppColors.mutedLight,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: GlassDecoration.card(context),
                  padding: const EdgeInsets.all(4),
                  child: TextField(
                    controller: _contextController,
                    maxLength: 500,
                    maxLines: 4,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? AppColors.foreground
                          : AppColors.foregroundLight,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          "e.g. 'I'm a PM at a SaaS startup working with Chinese engineering teams' or 'Preparing for a role at ByteDance'",
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.muted : AppColors.mutedLight,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      counterStyle: TextStyle(
                        color: isDark ? AppColors.muted : AppColors.mutedLight,
                      ),
                    ),
                    onChanged: (text) {
                      ref
                          .read(onboardingProvider.notifier)
                          .setAdditionalContext(text.isEmpty ? null : text);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Step 3: Suggested Words
  Widget _buildSuggestionsStep(OnboardingState state, bool isDark) {
    final selectedCount = state.selectedWordIndices.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentLight],
                ).createShader(bounds),
                child: const Text(
                  'Words for You',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We picked these based on your profile.\nSelect the ones you\'d like to learn.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.muted : AppColors.mutedLight,
                  height: 1.4,
                ),
              ),
              if (!state.isLoadingSuggestions &&
                  state.suggestedWords.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          ref.read(onboardingProvider.notifier).selectAllWords(),
                      child: Text(
                        'Select All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.accent
                              : AppColors.accentLightMode,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () => ref
                          .read(onboardingProvider.notifier)
                          .deselectAllWords(),
                      child: Text(
                        'Deselect All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.muted : AppColors.mutedLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Word list or loading spinner
        Expanded(
          child: state.isLoadingSuggestions && state.suggestedWords.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Generating words...',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDark ? AppColors.muted : AppColors.mutedLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: state.totalWordBatches > 0
                                ? state.wordGenerationProgress /
                                    state.totalWordBatches
                                : null,
                            minHeight: 4,
                            color: isDark
                                ? AppColors.accent
                                : AppColors.accentLightMode,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    if (state.isLoadingSuggestions) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Found ${state.suggestedWords.length} of ${state.totalWordBatches * 4} words',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.muted
                                        : AppColors.mutedLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: state.totalWordBatches > 0
                                    ? state.wordGenerationProgress /
                                        state.totalWordBatches
                                    : null,
                                minHeight: 4,
                                color: isDark
                                    ? AppColors.accent
                                    : AppColors.accentLightMode,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Expanded(
                      child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  itemCount: state.suggestedWords.length,
                  itemBuilder: (context, index) {
                    final word = state.suggestedWords[index];
                    final isSelected =
                        state.selectedWordIndices.contains(index);
                    final chinese = word['chinese'] as String? ?? '';
                    final pinyin = word['pinyin'] as String? ?? '';
                    final english = word['english'] as String? ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => ref
                            .read(onboardingProvider.notifier)
                            .toggleWordSelection(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                        ? AppColors.accent
                                        : AppColors.accentLightMode)
                                    .withValues(alpha: 0.15)
                                : isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.accent
                                      : AppColors.accentLightMode)
                                  : isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.06),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Checkbox indicator
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                          ? AppColors.accent
                                          : AppColors.accentLightMode)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark
                                            ? AppColors.accent
                                            : AppColors.accentLightMode)
                                        : isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.2)
                                            : Colors.black
                                                .withValues(alpha: 0.15),
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(LucideIcons.check,
                                        size: 14, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              // Word info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          chinese,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.foreground
                                                : AppColors.foregroundLight,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            pinyin,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark
                                                  ? AppColors.accent
                                                  : AppColors.accentLightMode,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      english,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.muted
                                            : AppColors.mutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Bottom buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Row(
            children: [
              // Skip button
              GestureDetector(
                onTap: state.isSavingWords
                    ? null
                    : () async {
                        // Cancels any ongoing generation
                        final success = await ref
                            .read(onboardingProvider.notifier)
                            .skipAndComplete();
                        if (success && mounted) {
                          ref.invalidate(profileProvider);
                          ref.invalidate(flashcardNotifierProvider);
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (mounted) context.go('/');
                        }
                      },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.foreground
                          : AppColors.foregroundLight,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Add selected button
              GestureDetector(
                onTap: state.isSavingWords || state.isLoadingSuggestions
                    ? null
                    : () async {
                        final success = await ref
                            .read(onboardingProvider.notifier)
                            .saveSelectedAndComplete();
                        if (success && mounted) {
                          ref.invalidate(profileProvider);
                          ref.invalidate(flashcardNotifierProvider);
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (mounted) context.go('/');
                        } else if (!success && mounted) {
                          AppToast.show(
                            context,
                            message: state.error ?? 'Something went wrong',
                            type: ToastType.error,
                          );
                        }
                      },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                  child: state.isSavingWords
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          selectedCount > 0
                              ? 'Add $selectedCount & Start'
                              : 'Get Started',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavButtons(OnboardingState state, bool isDark) {
    final isFirst = state.currentStep == 0;
    final isContextStep = state.currentStep == state.contextStep;

    // Determine if next is enabled
    bool canProceed;
    switch (state.currentStep) {
      case 0:
        canProceed = state.displayName != null && state.displayName!.isNotEmpty;
        break;
      case 1:
        canProceed = state.focusAreas.isNotEmpty;
        break;
      default:
        canProceed = true;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (!isFirst)
            GestureDetector(
              onTap: () {
                ref.read(onboardingProvider.notifier).previousStep();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.arrowLeft,
                      size: 16,
                      color:
                          isDark ? AppColors.foreground : AppColors.foregroundLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Back',
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
            ),
          const Spacer(),
          GestureDetector(
            onTap: canProceed && !state.isSubmitting
                ? () async {
                    if (isContextStep) {
                      // Submit profile + fetch suggestions
                      final success = await ref
                          .read(onboardingProvider.notifier)
                          .submitAndFetchSuggestions();
                      if (!success && mounted) {
                        AppToast.show(
                          context,
                          message: state.error ?? 'Something went wrong',
                          type: ToastType.error,
                        );
                      }
                    } else {
                      ref.read(onboardingProvider.notifier).nextStep();
                    }
                  }
                : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: canProceed
                    ? const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                      )
                    : null,
                color: canProceed ? null : (isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: canProceed
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isContextStep ? 'Complete Setup' : 'Next',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: canProceed
                                ? Colors.white
                                : (isDark ? AppColors.muted : AppColors.mutedLight),
                          ),
                        ),
                        if (!isContextStep) ...[
                          const SizedBox(width: 6),
                          Icon(
                            LucideIcons.arrowRight,
                            size: 16,
                            color: canProceed
                                ? Colors.white
                                : (isDark ? AppColors.muted : AppColors.mutedLight),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
