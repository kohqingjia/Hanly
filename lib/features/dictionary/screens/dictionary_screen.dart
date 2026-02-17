import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/shimmer_loader.dart';
import '../providers/dictionary_provider.dart';
import '../widgets/word_card.dart';

class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(dictionaryNotifierProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(dictionaryNotifierProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 640;

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
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Header
                Row(
                  children: [
                    Text(
                      'Dictionary',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.foreground
                            : AppColors.foregroundLight,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.accent
                                : AppColors.accentLightMode)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${state.words.length}',
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
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 16),
                // Active/Archived toggle
                Row(
                  children: [
                    _buildToggleChip(
                      context,
                      label: 'Active',
                      isSelected: !state.showArchived,
                      isDark: isDark,
                      onTap: () {
                        if (state.showArchived) {
                          ref
                              .read(dictionaryNotifierProvider.notifier)
                              .toggleArchiveView();
                          _searchController.clear();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildToggleChip(
                      context,
                      label: 'Archived',
                      isSelected: state.showArchived,
                      isDark: isDark,
                      onTap: () {
                        if (!state.showArchived) {
                          ref
                              .read(dictionaryNotifierProvider.notifier)
                              .toggleArchiveView();
                          _searchController.clear();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? AppColors.foreground
                          : AppColors.foregroundLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search words...',
                      prefixIcon: Icon(
                        LucideIcons.search,
                        size: 18,
                        color: isDark ? AppColors.muted : AppColors.mutedLight,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Word list
                Expanded(
                  child: _buildWordList(state, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.accent : AppColors.accentLightMode)
                  .withValues(alpha: 0.2)
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.accent : AppColors.accentLightMode)
                : isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? (isDark ? AppColors.accentLight : AppColors.accentLightMode)
                : (isDark ? AppColors.foreground : AppColors.foregroundLight),
          ),
        ),
      ),
    );
  }

  Widget _buildWordList(DictionaryState state, bool isDark) {
    if (state.isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerLoader(height: 120, borderRadius: 16),
        ),
      );
    }

    if (state.words.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.showArchived
                  ? LucideIcons.archiveRestore
                  : LucideIcons.bookOpen,
              size: 48,
              color: isDark ? AppColors.muted : AppColors.mutedLight,
            ),
            const SizedBox(height: 16),
            Text(
              state.showArchived
                  ? 'No archived words'
                  : state.searchQuery.isNotEmpty
                      ? 'No results found'
                      : 'No words yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.muted : AppColors.mutedLight,
              ),
            ),
            if (!state.showArchived && state.searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Translate words on the Home tab to build your dictionary',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.muted : AppColors.mutedLight,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.words.length,
      itemBuilder: (context, index) {
        final word = state.words[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WordCard(
            word: word,
            isArchived: state.showArchived,
            onArchive: () {
              if (state.showArchived) {
                ref
                    .read(dictionaryNotifierProvider.notifier)
                    .unarchiveWord(word.id);
              } else {
                ref
                    .read(dictionaryNotifierProvider.notifier)
                    .archiveWord(word.id);
              }
            },
            onDelete: () {
              ref
                  .read(dictionaryNotifierProvider.notifier)
                  .deleteWord(word.id);
            },
          ),
        )
            .animate()
            .fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: 30 * (index.clamp(0, 10))))
            .slideY(
                begin: 0.03,
                end: 0,
                duration: 300.ms,
                delay: Duration(milliseconds: 30 * (index.clamp(0, 10))));
      },
    );
  }
}
