import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum ToastType { success, error, info }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconColor;
    IconData icon;
    switch (type) {
      case ToastType.success:
        iconColor = isDark ? AppColors.success : AppColors.successLight;
        icon = Icons.check_circle_rounded;
      case ToastType.error:
        iconColor = isDark ? AppColors.danger : AppColors.dangerLight;
        icon = Icons.error_rounded;
      case ToastType.info:
        iconColor = isDark ? AppColors.accent : AppColors.accentLightMode;
        icon = Icons.info_rounded;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark ? AppColors.foreground : AppColors.foregroundLight,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: duration,
        backgroundColor: isDark ? AppColors.card : AppColors.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
