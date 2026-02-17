import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/app_toast.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditingContext = false;
  String? _editLevel;
  List<String> _editPurposes = [];
  String? _editIndustry;
  final _editContextController = TextEditingController();

  @override
  void dispose() {
    _editContextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileProvider);
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
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (profile) {
              if (profile == null) {
                return const Center(child: Text('No profile found'));
              }

              final user = ref.watch(currentUserProvider);

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.foreground
                                : AppColors.foregroundLight,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 24),

                        // Profile header card
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.accent,
                                      AppColors.accentLight,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    (profile.displayName?.isNotEmpty == true
                                            ? profile.displayName![0]
                                            : user?.email?[0] ?? '?')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.displayName ?? 'Learner',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.foreground
                                            : AppColors.foregroundLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.email ?? '',
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
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 100.ms)
                            .slideY(begin: 0.03, end: 0, duration: 400.ms, delay: 100.ms),
                        const SizedBox(height: 16),

                        // Learning Context card
                        _buildContextCard(isDark, profile)
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 200.ms)
                            .slideY(begin: 0.03, end: 0, duration: 400.ms, delay: 200.ms),
                        const SizedBox(height: 16),

                        // Preferences card
                        _buildPreferencesCard(isDark, profile)
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 300.ms)
                            .slideY(begin: 0.03, end: 0, duration: 400.ms, delay: 300.ms),
                        const SizedBox(height: 16),

                        // Stats row
                        _buildStatsRow(isDark)
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 400.ms)
                            .slideY(begin: 0.03, end: 0, duration: 400.ms, delay: 400.ms),
                        const SizedBox(height: 24),

                        // Sign out
                        _buildSignOutButton(isDark)
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 500.ms),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContextCard(bool isDark, dynamic profile) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'LEARNING CONTEXT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.muted : AppColors.mutedLight,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditingContext = !_isEditingContext;
                    if (_isEditingContext) {
                      _editLevel = profile.chineseLevel;
                      _editPurposes = List<String>.from(profile.learningPurposes);
                      _editIndustry = profile.industry;
                      _editContextController.text =
                          profile.additionalContext ?? '';
                    }
                  });
                },
                child: Text(
                  _isEditingContext ? 'Cancel' : 'Edit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark ? AppColors.accent : AppColors.accentLightMode,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isEditingContext) ...[
            // Display mode
            if (profile.chineseLevel != null)
              _buildInfoRow(isDark, 'Level', profile.chineseLevel!),
            if (profile.learningPurposes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (profile.learningPurposes as List<String>)
                    .map((p) => _buildPill(isDark, p))
                    .toList(),
              ),
            ],
            if (profile.industry != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(isDark, 'Industry', profile.industry!),
            ],
            if (profile.contextSummary != null) ...[
              const SizedBox(height: 12),
              Text(
                profile.contextSummary!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.muted : AppColors.mutedLight,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ] else ...[
            // Edit mode
            _buildEditContextForm(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildEditContextForm(bool isDark) {
    const levels = [
      'Absolute Beginner', 'Beginner', 'Elementary',
      'Intermediate', 'Upper Intermediate', 'Advanced',
    ];
    const purposes = [
      'School', 'Work', 'Career Advancement', 'Travel',
      'Relocation', 'Heritage', 'Hobby', 'Exam Prep', 'General',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.muted : AppColors.mutedLight)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: levels.map((level) {
            final isSelected = _editLevel == level;
            return GestureDetector(
              onTap: () => setState(() => _editLevel = level),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.accent : AppColors.accentLightMode)
                          .withValues(alpha: 0.2)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? AppColors.accent : AppColors.accentLightMode)
                        : Colors.transparent,
                  ),
                ),
                child: Text(level, style: TextStyle(fontSize: 12,
                    color: isDark ? AppColors.foreground : AppColors.foregroundLight)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text('Purposes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.muted : AppColors.mutedLight)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: purposes.map((purpose) {
            final isSelected = _editPurposes.contains(purpose);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _editPurposes.remove(purpose);
                } else {
                  _editPurposes.add(purpose);
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.accent : AppColors.accentLightMode)
                          .withValues(alpha: 0.2)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? AppColors.accent : AppColors.accentLightMode)
                        : Colors.transparent,
                  ),
                ),
                child: Text(purpose, style: TextStyle(fontSize: 12,
                    color: isDark ? AppColors.foreground : AppColors.foregroundLight)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _editContextController,
          maxLength: 500,
          maxLines: 3,
          style: TextStyle(fontSize: 13,
              color: isDark ? AppColors.foreground : AppColors.foregroundLight),
          decoration: InputDecoration(
            hintText: 'Additional context (optional)',
            hintStyle: TextStyle(fontSize: 13,
                color: isDark ? AppColors.muted : AppColors.mutedLight),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final result = await ref
                  .read(profileUpdateProvider.notifier)
                  .regenerateContext(
                    chineseLevel: _editLevel ?? 'Beginner',
                    learningPurposes: _editPurposes,
                    industry: _editIndustry,
                    additionalContext: _editContextController.text.isEmpty
                        ? null
                        : _editContextController.text,
                  );
              if (mounted) {
                setState(() => _isEditingContext = false);
                if (result != null) {
                  AppToast.show(context,
                      message: 'Context updated!', type: ToastType.success);
                }
              }
            },
            child: const Text('Save & Regenerate Context'),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesCard(bool isDark, dynamic profile) {
    final themeMode = ref.watch(themeModeProvider);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREFERENCES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.muted : AppColors.mutedLight,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          // Theme toggle
          Row(
            children: [
              Icon(LucideIcons.sun, size: 18,
                  color: isDark ? AppColors.muted : AppColors.mutedLight),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? AppColors.foreground
                        : AppColors.foregroundLight,
                  ),
                ),
              ),
              Switch(
                value: themeMode == ThemeMode.dark,
                activeTrackColor:
                    isDark ? AppColors.accent : AppColors.accentLightMode,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).toggle();
                  final newTheme = value ? 'dark' : 'light';
                  ref
                      .read(profileUpdateProvider.notifier)
                      .updateTheme(newTheme);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Daily word goal
          Row(
            children: [
              Icon(LucideIcons.target, size: 18,
                  color: isDark ? AppColors.muted : AppColors.mutedLight),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Daily Goal: ${profile.dailyWordGoal} words',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? AppColors.foreground
                        : AppColors.foregroundLight,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: (profile.dailyWordGoal as int).toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            activeColor:
                isDark ? AppColors.accent : AppColors.accentLightMode,
            onChanged: (value) {
              ref.read(profileUpdateProvider.notifier).updateProfile({
                'daily_word_goal': value.round(),
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final client = ref.watch(supabaseClientProvider);
    final user = ref.watch(currentUserProvider);

    return FutureBuilder(
      future: _loadStats(client, user?.id),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'active': 0, 'archived': 0, 'reviewed': 0};
        return Row(
          children: [
            Expanded(child: _buildStatCard(isDark, '${stats['active']}', 'Active Words')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(isDark, '${stats['archived']}', 'Archived')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(isDark, '${stats['reviewed']}', 'Reviewed Today')),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _loadStats(dynamic client, String? userId) async {
    if (userId == null) return {'active': 0, 'archived': 0, 'reviewed': 0};
    try {
      final activeResult = await client
          .from('user_words')
          .select()
          .eq('user_id', userId)
          .eq('is_archived', false);
      final archivedResult = await client
          .from('user_words')
          .select()
          .eq('user_id', userId)
          .eq('is_archived', true);
      final today = DateTime.now().toUtc();
      final startOfDay = DateTime.utc(today.year, today.month, today.day);
      final reviewedResult = await client
          .from('review_cards')
          .select()
          .eq('user_id', userId)
          .gte('last_reviewed_at', startOfDay.toIso8601String());

      return {
        'active': (activeResult as List).length,
        'archived': (archivedResult as List).length,
        'reviewed': (reviewedResult as List).length,
      };
    } catch (_) {
      return {'active': 0, 'archived': 0, 'reviewed': 0};
    }
  }

  Widget _buildStatCard(bool isDark, String value, String label) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.accent : AppColors.accentLightMode,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.muted : AppColors.mutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.muted : AppColors.mutedLight,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.accent : AppColors.accentLightMode)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color:
                  isDark ? AppColors.accentLight : AppColors.accentLightMode,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPill(bool isDark, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.accent : AppColors.accentLightMode)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.accentLight : AppColors.accentLightMode,
        ),
      ),
    );
  }

  Widget _buildSignOutButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor:
                  isDark ? AppColors.backgroundElevated : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Sign Out?'),
              content: const Text(
                  'Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(authNotifierProvider.notifier).signOut();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isDark ? AppColors.danger : AppColors.dangerLight,
                  ),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.danger : AppColors.dangerLight)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? AppColors.danger : AppColors.dangerLight)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.logOut,
                size: 18,
                color: isDark ? AppColors.danger : AppColors.dangerLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.danger : AppColors.dangerLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
