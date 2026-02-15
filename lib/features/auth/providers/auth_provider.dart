import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';

enum AuthMode { login, signUp }

class AuthState {
  final AuthMode mode;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.mode = AuthMode.login,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AuthMode? mode,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _client;

  AuthNotifier(this._client) : super(const AuthState());

  void toggleMode() {
    state = state.copyWith(
      mode: state.mode == AuthMode.login ? AuthMode.signUp : AuthMode.login,
      error: null,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<bool> submit(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (state.mode == AuthMode.login) {
        await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await _client.auth.signUp(
          email: email,
          password: password,
        );
      }
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(supabaseClientProvider));
});
