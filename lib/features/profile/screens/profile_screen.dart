import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/app_toast.dart';
import '../../../models/profile.dart';
import '../providers/profile_provider.dart';
import '../providers/import_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/flashcard_provider.dart';
import '../../dictionary/providers/dictionary_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditingContext = false;
  List<String> _editFocusAreas = [];
  final _editContextController = TextEditingController();
  final _editSummaryController = TextEditingController();
  double? _sliderValue;

  @override
  void dispose() {
    _editContextController.dispose();
    _editSummaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 640;

    ref.listen(importProvider, (prev, next) {
      if (prev?.isImporting == true && !next.isImporting && next.isComplete) {
        ref.invalidate(flashcardNotifierProvider);
        ref.invalidate(dictionaryNotifierProvider);
      }
    });

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

                        // Import card
                        _buildImportCard(isDark)
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 350.ms)
                            .slideY(begin: 0.03, end: 0, duration: 400.ms, delay: 350.ms),
                        const SizedBox(height: 24),

                        // Sign out
                        _buildSignOutButton(isDark)
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 400.ms),
                        const SizedBox(height: 12),

                        // Delete account
                        _buildDeleteAccountButton(isDark)
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

  Widget _buildContextCard(bool isDark, Profile profile) {
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
                      _editFocusAreas = List<String>.from(profile.focusAreas);
                      _editContextController.text =
                          profile.additionalContext ?? '';
                      _editSummaryController.text =
                          profile.contextSummary ?? '';
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
            if (profile.focusAreas.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.focusAreas
                    .map((i) => _buildPill(isDark, i))
                    .toList(),
              ),
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
    const focusAreas = [
      'Data & Analytics', 'Cloud Computing', 'Machine Learning & AI',
      'Software Engineering', 'Product Management', 'Business & Strategy',
      'Marketing & Growth', 'Finance & Accounting', 'Operations & Supply Chain',
      'Design & UX', 'Cybersecurity', 'E-commerce',
      'Hardware & IoT', 'DevOps & Infrastructure', 'General Tech',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Focus Areas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.muted : AppColors.mutedLight)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: focusAreas.map((area) {
            final isSelected = _editFocusAreas.contains(area);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _editFocusAreas.remove(area);
                } else {
                  _editFocusAreas.add(area);
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
                child: Text(area, style: TextStyle(fontSize: 12,
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
        const SizedBox(height: 16),
        Text(
          'AI SUMMARY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.muted : AppColors.mutedLight,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Edit the AI-generated summary directly, or tap "Regenerate" to have it rewritten.',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.muted : AppColors.mutedLight,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _editSummaryController,
          maxLength: 300,
          maxLines: 3,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.foreground : AppColors.foregroundLight,
            fontStyle: FontStyle.italic,
          ),
          decoration: InputDecoration(
            hintText: 'AI-generated summary',
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.muted : AppColors.mutedLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final result = await ref
                      .read(profileUpdateProvider.notifier)
                      .regenerateContext(
                        focusAreas: _editFocusAreas,
                        additionalContext: _editContextController.text.isEmpty
                            ? null
                            : _editContextController.text,
                      );
                  if (mounted) {
                    setState(() => _isEditingContext = false);
                    if (result != null) {
                      AppToast.show(context,
                          message: 'Context regenerated!', type: ToastType.success);
                    }
                  }
                },
                child: const Text('Regenerate'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(profileUpdateProvider.notifier).updateProfile({
                    'focus_areas': _editFocusAreas,
                    'additional_context': _editContextController.text.isEmpty
                        ? null
                        : _editContextController.text,
                    'context_summary': _editSummaryController.text.isEmpty
                        ? null
                        : _editSummaryController.text,
                  });
                  if (mounted) {
                    setState(() => _isEditingContext = false);
                    AppToast.show(context,
                        message: 'Context saved!', type: ToastType.success);
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreferencesCard(bool isDark, Profile profile) {
    final themeMode = ref.watch(themeModeProvider);
    final displayGoal = _sliderValue?.round() ?? profile.dailyWordGoal;

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
                  'Daily Goal: $displayGoal words',
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
            value: _sliderValue ?? profile.dailyWordGoal.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            activeColor:
                isDark ? AppColors.accent : AppColors.accentLightMode,
            onChanged: (value) {
              setState(() => _sliderValue = value);
            },
            onChangeEnd: (value) {
              ref.read(profileUpdateProvider.notifier).updateProfile({
                'daily_word_goal': value.round(),
              });
              setState(() => _sliderValue = null);
            },
          ),
        ],
      ),
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

  Widget _buildImportCard(bool isDark) {
    final importState = ref.watch(importProvider);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOCABULARY IMPORT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.muted : AppColors.mutedLight,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (importState.isImporting) ...[
            Row(
              children: [
                Icon(LucideIcons.loader, size: 16,
                    color: isDark ? AppColors.accent : AppColors.accentLightMode)
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(duration: const Duration(milliseconds: 1000)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Processing ${importState.processedRows} of ${importState.totalRows} rows'
                    ' · ${importState.savedWords} words saved',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.foreground : AppColors.foregroundLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: importState.totalRows > 0
                    ? importState.processedRows / importState.totalRows
                    : null,
                minHeight: 4,
                color: isDark ? AppColors.accent : AppColors.accentLightMode,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
          ] else if (importState.isComplete) ...[
            Row(
              children: [
                Icon(LucideIcons.checkCircle, size: 16,
                    color: isDark ? AppColors.accent : AppColors.accentLightMode),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Import complete — ${importState.savedWords} words added',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.foreground : AppColors.foregroundLight,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => ref.read(importProvider.notifier).dismiss(),
                  child: Icon(LucideIcons.x, size: 16,
                      color: isDark ? AppColors.muted : AppColors.mutedLight),
                ),
              ],
            ),
          ] else if (importState.error != null) ...[
            Row(
              children: [
                Icon(LucideIcons.alertCircle, size: 16,
                    color: isDark ? AppColors.danger : AppColors.dangerLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Import failed. Tap to retry.',
                    style: TextStyle(fontSize: 13,
                        color: isDark ? AppColors.foreground : AppColors.foregroundLight),
                  ),
                ),
                GestureDetector(
                  onTap: () => ref.read(importProvider.notifier).dismiss(),
                  child: Icon(LucideIcons.x, size: 16,
                      color: isDark ? AppColors.muted : AppColors.mutedLight),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showImportSheet(isDark),
                icon: const Icon(LucideIcons.upload, size: 16),
                label: const Text('Import Words'),
              ),
            ),
          ] else ...[
            Text(
              'Upload a CSV or Excel file to import your vocabulary. The AI will map each row into the correct format.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.muted : AppColors.mutedLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showImportSheet(isDark),
                icon: const Icon(LucideIcons.upload, size: 16),
                label: const Text('Import Words'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showImportSheet(bool isDark) async {
    List<List<dynamic>>? parsedRows;
    List<String>? headers;
    String? fileName;
    bool sheetIsLoading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundElevated : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(
                24, 20, 24,
                MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Import Vocabulary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.foreground : AppColors.foregroundLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload a CSV or Excel (.xlsx) file. The AI will read each row and convert it to the correct format — any column layout works.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.muted : AppColors.mutedLight,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (sheetIsLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (parsedRows == null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          setSheetState(() => sheetIsLoading = true);
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['csv', 'xlsx'],
                              withData: true,
                            );
                            if (result != null && result.files.single.bytes != null) {
                              final file = result.files.single;
                              final bytes = file.bytes!;
                              final ext = file.extension?.toLowerCase();

                              List<List<dynamic>> rows = [];

                              if (ext == 'csv') {
                                final content = String.fromCharCodes(bytes);
                                rows = const CsvToListConverter(eol: '\n').convert(content);
                              } else if (ext == 'xlsx') {
                                final excel = Excel.decodeBytes(bytes);
                                final sheet = excel.tables.values.first;
                                rows = sheet.rows.map((row) =>
                                  row.map((cell) => cell?.value?.toString() ?? '').toList()
                                ).toList();
                              }

                              // Filter empty rows
                              rows = rows.where((r) => r.any((c) => c.toString().trim().isNotEmpty)).toList();

                              if (rows.isNotEmpty) {
                                final hdrs = rows.first.map((c) => c.toString()).toList();
                                final dataRows = rows.sublist(1);
                                setSheetState(() {
                                  headers = hdrs;
                                  parsedRows = dataRows;
                                  fileName = file.name;
                                  sheetIsLoading = false;
                                });
                              } else {
                                setSheetState(() => sheetIsLoading = false);
                              }
                            } else {
                              setSheetState(() => sheetIsLoading = false);
                            }
                          } catch (e) {
                            setSheetState(() => sheetIsLoading = false);
                          }
                        },
                        icon: const Icon(LucideIcons.filePlus, size: 16),
                        label: const Text('Pick File (CSV or XLSX)'),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.accent : AppColors.accentLightMode)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isDark ? AppColors.accent : AppColors.accentLightMode)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.fileText, size: 16,
                                  color: isDark ? AppColors.accent : AppColors.accentLightMode),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  fileName ?? 'File',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.foreground : AppColors.foregroundLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${parsedRows!.length} rows · Columns: ${headers!.take(4).join(', ')}${headers!.length > 4 ? '...' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.muted : AppColors.mutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(importProvider.notifier).startImport(
                            parsedRows!,
                            headers!,
                          );
                        },
                        child: Text('Start Import (${parsedRows!.length} rows)'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => setSheetState(() {
                          parsedRows = null;
                          headers = null;
                          fileName = null;
                        }),
                        child: const Text('Pick a different file'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeleteAccountButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor:
                  isDark ? AppColors.backgroundElevated : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Delete Account?'),
              content: const Text(
                'This will permanently delete your account and all your saved words, flashcards, and progress. This cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      final client = ref.read(supabaseClientProvider);
                      final response = await client.functions.invoke(
                        'delete-account',
                        body: {},
                      );
                      if (response.status == 200) {
                        try {
                          await client.auth.signOut();
                        } catch (_) {}
                      } else if (mounted) {
                        AppToast.show(
                          context,
                          message: 'Failed to delete account',
                          type: ToastType.error,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        AppToast.show(
                          context,
                          message: 'Failed to delete account',
                          type: ToastType.error,
                        );
                      }
                    }
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
        },
        child: Center(
          child: Text(
            'Delete Account',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: (isDark ? AppColors.danger : AppColors.dangerLight)
                  .withValues(alpha: 0.7),
            ),
          ),
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
