import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/supabase_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/screens/flashcard_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/dictionary/screens/dictionary_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../widgets/adaptive_nav.dart';

/// Notifies GoRouter to re-evaluate redirects when auth or profile state changes.
/// Using ref.listen (not ref.watch) ensures the GoRouter is created only once.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(profileProvider, (_, __) => notifyListeners());
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final profileAsync = ref.read(profileProvider);

      final isLoggedIn =
          authAsync.whenOrNull(data: (s) => s.session != null) ?? false;
      final isProfileLoading = profileAsync.isLoading;
      final profileData = profileAsync.whenOrNull(data: (p) => p);

      final loc = state.matchedLocation;
      final isOnLogin = loc == '/login';
      final isOnSplash = loc == '/splash';
      final isOnOnboarding = loc == '/onboarding';

      // Not logged in → login
      if (!isLoggedIn) {
        return isOnLogin ? null : '/login';
      }

      // Logged in, profile still loading:
      // Move off login immediately (we know the user is authenticated),
      // but wait on splash until profile resolves.
      if (isProfileLoading) {
        if (isOnLogin) return '/splash';
        return null; // Stay on splash (or wherever we are) — no further redirect
      }

      // Profile has loaded — decide destination
      final onboardingComplete = profileData?.onboardingCompleted ?? false;

      if (!onboardingComplete) {
        return isOnOnboarding ? null : '/onboarding';
      }

      // Onboarding complete — move off transient screens to home
      if (isOnLogin || isOnSplash || isOnOnboarding) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
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

  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });

  return router;
});
