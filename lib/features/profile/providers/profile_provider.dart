import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../models/profile.dart';

final profileProvider = StreamProvider<Profile?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .map((data) => data.isEmpty ? null : Profile.fromJson(data.first));
});

class ProfileUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient _client;
  final User? _user;

  ProfileUpdateNotifier(this._client, this._user)
      : super(const AsyncValue.data(null));

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    if (_user == null) return;
    state = const AsyncValue.loading();
    try {
      await _client
          .from('profiles')
          .update({...fields, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', _user.id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Map<String, dynamic>?> regenerateContext({
    required String chineseLevel,
    required List<String> learningPurposes,
    String? industry,
    String? additionalContext,
  }) async {
    if (_user == null) return null;
    state = const AsyncValue.loading();
    try {
      final response = await _client.functions.invoke(
        'generate-context',
        body: {
          'chinese_level': chineseLevel,
          'learning_purposes': learningPurposes,
          'industry': industry,
          'additional_context': additionalContext,
        },
      );

      if (response.status != 200) {
        throw Exception('Context generation failed');
      }

      final rawData = response.data;
      final Map<String, dynamic> data = rawData is String
          ? jsonDecode(rawData) as Map<String, dynamic>
          : rawData as Map<String, dynamic>;

      await _client.from('profiles').update({
        'chinese_level': chineseLevel,
        'learning_purposes': learningPurposes,
        'industry': industry,
        'additional_context': additionalContext,
        'context_summary': data['context_summary'],
        'context_tags': data['context_tags'],
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _user.id);

      state = const AsyncValue.data(null);
      return data;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateTheme(String theme) async {
    if (_user == null) return;
    await _client.from('profiles').update({
      'theme_preference': theme,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', _user.id);
  }
}

final profileUpdateProvider =
    StateNotifierProvider<ProfileUpdateNotifier, AsyncValue<void>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  return ProfileUpdateNotifier(client, user);
});
