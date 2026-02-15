import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.accent, AppColors.accentLight],
              ).createShader(bounds),
              child: const Text(
                'Hanly',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome! Flashcard review coming soon.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.muted : AppColors.mutedLight,
              ),
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () {
                ref.read(authNotifierProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
