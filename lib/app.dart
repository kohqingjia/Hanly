import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'features/profile/providers/profile_provider.dart';

class HanlyApp extends ConsumerWidget {
  const HanlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Sync theme from profile when it loads
    ref.listen(profileProvider, (prev, next) {
      next.whenData((profile) {
        if (profile != null) {
          ref
              .read(themeModeProvider.notifier)
              .setFromProfile(profile.themePreference);
        }
      });
    });

    return MaterialApp.router(
      title: 'Hanly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
