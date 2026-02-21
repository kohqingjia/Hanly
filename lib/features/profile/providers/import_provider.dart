import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';

class ImportState {
  final bool isImporting;
  final int totalRows;
  final int processedRows;
  final int savedWords;
  final String? error;
  final bool isComplete;

  const ImportState({
    this.isImporting = false,
    this.totalRows = 0,
    this.processedRows = 0,
    this.savedWords = 0,
    this.error,
    this.isComplete = false,
  });

  ImportState copyWith({
    bool? isImporting,
    int? totalRows,
    int? processedRows,
    int? savedWords,
    String? error,
    bool clearError = false,
    bool? isComplete,
  }) {
    return ImportState(
      isImporting: isImporting ?? this.isImporting,
      totalRows: totalRows ?? this.totalRows,
      processedRows: processedRows ?? this.processedRows,
      savedWords: savedWords ?? this.savedWords,
      error: clearError ? null : (error ?? this.error),
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class ImportNotifier extends StateNotifier<ImportState> {
  final SupabaseClient _client;
  bool _cancelled = false;

  ImportNotifier(this._client) : super(const ImportState());

  void dismiss() {
    state = const ImportState();
  }

  Future<void> startImport(
    List<List<dynamic>> rows,
    List<String> headers,
  ) async {
    if (rows.isEmpty) return;
    _cancelled = false;

    state = ImportState(
      isImporting: true,
      totalRows: rows.length,
      processedRows: 0,
      savedWords: 0,
    );

    const batchSize = 5;
    int totalSaved = 0;

    try {
      for (int i = 0; i < rows.length; i += batchSize) {
        if (_cancelled) break;

        final batchEnd = (i + batchSize).clamp(0, rows.length);
        final batch = rows.sublist(i, batchEnd);

        // Convert batch rows to string lists for JSON serialisation
        final batchStrings = batch
            .map((row) => row.map((cell) => cell?.toString() ?? '').toList())
            .toList();

        // Call process-import-batch edge function
        final processResponse = await _client.functions.invoke(
          'process-import-batch',
          body: {
            'headers': headers,
            'rows': batchStrings,
          },
        );

        if (_cancelled) break;

        if (processResponse.status == 200) {
          final rawData = processResponse.data;
          final Map<String, dynamic> data = rawData is String
              ? jsonDecode(rawData) as Map<String, dynamic>
              : rawData as Map<String, dynamic>;

          final words = (data['words'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [];

          if (words.isNotEmpty) {
            // Save formatted words using existing batch-save-words function
            final saveResponse = await _client.functions.invoke(
              'batch-save-words',
              body: {'words': words},
            );

            if (saveResponse.status == 200) {
              final saveRaw = saveResponse.data;
              final Map<String, dynamic> saveData = saveRaw is String
                  ? jsonDecode(saveRaw) as Map<String, dynamic>
                  : saveRaw as Map<String, dynamic>;
              totalSaved += (saveData['saved'] as int? ?? 0);
            }
          }
        }

        state = state.copyWith(
          processedRows: batchEnd,
          savedWords: totalSaved,
        );
      }

      state = state.copyWith(
        isImporting: false,
        isComplete: true,
        savedWords: totalSaved,
      );
    } catch (e) {
      state = state.copyWith(
        isImporting: false,
        error: e.toString(),
      );
    }
  }

  void cancel() {
    _cancelled = true;
    state = state.copyWith(isImporting: false);
  }
}

// Global provider — not autoDisposed so it survives navigation
final importProvider =
    StateNotifierProvider<ImportNotifier, ImportState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ImportNotifier(client);
});
