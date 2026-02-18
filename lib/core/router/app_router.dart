import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../providers/supabase_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/flashcard_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/dictionary/screens/dictionary_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../widgets/adaptive_nav.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profile = ref.watch(profileProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final isLoggedIn = authState.whenOrNull(
            data: (s) => s.session != null,
          ) ??
          false;
      final isOnLogin = state.matchedLocation == '/login';
      final isOnOnboarding = state.matchedLocation == '/onboarding';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) {
        final profileData = profile.whenOrNull(data: (p) => p);
        if (profileData != null && !profileData.onboardingCompleted) {
          return '/onboarding';
        }
        return '/';
      }

      // Logged in, check onboarding
      if (isLoggedIn && !isOnOnboarding) {
        final profileData = profile.whenOrNull(data: (p) => p);
        if (profileData != null && !profileData.onboardingCompleted) {
          return '/onboarding';
        }
      }

      // Completed onboarding but still on onboarding page
      if (isLoggedIn && isOnOnboarding) {
        final profileData = profile.whenOrNull(data: (p) => p);
        if (profileData != null && profileData.onboardingCompleted) {
          return '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/flashcards',
        builder: (context, state) => const FlashcardScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdaptiveNavScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dictionary',
              builder: (context, state) => const DictionaryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});

/// Converts a Stream into a Listenable for GoRouter's refreshListenable.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
