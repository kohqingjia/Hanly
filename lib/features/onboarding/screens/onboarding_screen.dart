import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_decoration.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/app_toast.dart';
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
                        _buildNameStep(state, isDark),
                        _buildLevelStep(state, isDark),
                        _buildPurposesStep(state, isDark),
                        _buildIndustryStep(state, isDark),
                        _buildPreferencesStep(state, isDark),
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
    // Map current step to dot index (skip industry step in dot count if not needed)
    int dotIndex;
    if (!state.needsIndustry && current >= 3) {
      dotIndex = current - 1; // Shift down since industry (3) is skipped
    } else {
      dotIndex = current;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i <= dotIndex;
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

  // Step 0: Name
  Widget _buildNameStep(OnboardingState state, bool isDark) {
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
              "What's your name?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.foreground : AppColors.foregroundLight,
              ),
            ),
            const SizedBox(height: 40),
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
          ],
        ),
      ),
    );
  }

  // Step 1: Chinese Level
  Widget _buildLevelStep(OnboardingState state, bool isDark) {
    const levels = [
      'Absolute Beginner',
      'Beginner',
      'Elementary',
      'Intermediate',
      'Upper Intermediate',
      'Advanced',
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
              "What's your Chinese level?",
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
              "We'll personalize your experience",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.muted : AppColors.mutedLight,
              ),
            ),
            const SizedBox(height: 32),
            ...levels.asMap().entries.map((entry) {
              final level = entry.value;
              final isSelected = state.chineseLevel == level;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    ref.read(onboardingProvider.notifier).setChineseLevel(level);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                      ? AppColors.accent
                                      : AppColors.accentLightMode)
                                  .withValues(alpha: 0.2)
                              : isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
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
                            Expanded(
                              child: Text(
                                level,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
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
                            if (isSelected)
                              Icon(
                                LucideIcons.check,
                                size: 18,
                                color: isDark
                                    ? AppColors.accent
                                    : AppColors.accentLightMode,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                      duration: 400.ms,
                      delay: Duration(milliseconds: 50 * entry.key))
                  .slideX(
                      begin: 0.05,
                      end: 0,
                      duration: 400.ms,
                      delay: Duration(milliseconds: 50 * entry.key));
            }),
          ],
        ),
      ),
    );
  }

  // Step 2: Learning Purposes
  Widget _buildPurposesStep(OnboardingState state, bool isDark) {
    const purposes = [
      'School',
      'Work',
      'Career Advancement',
      'Travel',
      'Relocation',
      'Heritage',
      'Hobby',
      'Exam Prep',
      'General',
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
              'Why are you learning Chinese?',
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
              'Select all that apply',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.muted : AppColors.mutedLight,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: purposes.asMap().entries.map((entry) {
                final purpose = entry.value;
                final isSelected = state.learningPurposes.contains(purpose);
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(onboardingProvider.notifier)
                        .togglePurpose(purpose);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
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
                      purpose,
                      style: TextStyle(
                        fontSize: 14,
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
                        delay: Duration(milliseconds: 30 * entry.key))
                    .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        duration: 300.ms,
                        delay: Duration(milliseconds: 30 * entry.key));
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Step 3: Industry (conditional)
  Widget _buildIndustryStep(OnboardingState state, bool isDark) {
    const industries = [
      'Technology',
      'Finance',
      'Healthcare',
      'Legal',
      'Education',
      'Marketing',
      'Hospitality',
      'Manufacturing',
      'Real Estate',
      'Media',
      'Government',
      'Retail',
      'Other',
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
              "What's your industry?",
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
              "We'll tailor vocabulary to your field",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.muted : AppColors.mutedLight,
              ),
            ),
            const SizedBox(height: 32),
            ...industries.asMap().entries.map((entry) {
              final industry = entry.value;
              final isSelected = state.industry == industry;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    ref
                        .read(onboardingProvider.notifier)
                        .setIndustry(industry);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                                  ? AppColors.accent
                                  : AppColors.accentLightMode)
                              .withValues(alpha: 0.2)
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
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            industry,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
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
                        if (isSelected)
                          Icon(
                            LucideIcons.check,
                            size: 18,
                            color: isDark
                                ? AppColors.accent
                                : AppColors.accentLightMode,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Step 4: Context + Age Range + Daily Goal
  Widget _buildPreferencesStep(OnboardingState state, bool isDark) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Almost done!',
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
                'Set your preferences',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.muted : AppColors.mutedLight,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Daily Word Goal
            Text(
              'DAILY WORD GOAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.muted : AppColors.mutedLight,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: GlassDecoration.card(context),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.target,
                              size: 18,
                              color: isDark
                                  ? AppColors.accent
                                  : AppColors.accentLightMode),
                          const SizedBox(width: 10),
                          Text(
                            '${state.dailyWordGoal} words per day',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.foreground
                                  : AppColors.foregroundLight,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: state.dailyWordGoal.toDouble(),
                        min: 5,
                        max: 50,
                        divisions: 9,
                        activeColor: isDark
                            ? AppColors.accent
                            : AppColors.accentLightMode,
                        onChanged: (value) {
                          ref
                              .read(onboardingProvider.notifier)
                              .setDailyWordGoal(value.round());
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('5',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.muted
                                      : AppColors.mutedLight)),
                          Text('50',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.muted
                                      : AppColors.mutedLight)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Age Range (optional)
            Text(
              'AGE RANGE (OPTIONAL)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.muted : AppColors.mutedLight,
                letterSpacing: 1.2,
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
            ),
            const SizedBox(height: 24),

            // Additional Context (optional)
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
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? AppColors.foreground
                          : AppColors.foregroundLight,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. "I\'m a software engineer moving to Shanghai" or "Preparing for HSK 4"',
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

  // Step 5: Suggested Words
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
          child: state.isLoadingSuggestions
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: isDark
                              ? AppColors.accent
                              : AppColors.accentLightMode,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Finding words for you...',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDark ? AppColors.muted : AppColors.mutedLight,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
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
                                        Text(
                                          pinyin,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? AppColors.accent
                                                : AppColors.accentLightMode,
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
                        final success = await ref
                            .read(onboardingProvider.notifier)
                            .skipAndComplete();
                        if (success && mounted) {
                          context.go('/');
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
                          context.go('/');
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
    final isPreferencesStep = state.currentStep == state.preferencesStep;

    // Determine if next is enabled
    bool canProceed;
    switch (state.currentStep) {
      case 0:
        canProceed = state.displayName != null && state.displayName!.isNotEmpty;
        break;
      case 1:
        canProceed = state.chineseLevel != null;
        break;
      case 2:
        canProceed = state.learningPurposes.isNotEmpty;
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
                    if (isPreferencesStep) {
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
                          isPreferencesStep ? 'Complete Setup' : 'Next',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: canProceed
                                ? Colors.white
                                : (isDark ? AppColors.muted : AppColors.mutedLight),
                          ),
                        ),
                        if (!isPreferencesStep) ...[
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
