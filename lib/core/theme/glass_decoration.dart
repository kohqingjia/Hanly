import 'package:flutter/material.dart';

class GlassDecoration {
  GlassDecoration._();

  /// Standard glass card
  static BoxDecoration card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? const Color(0xFF151520).withValues(alpha: 0.6)
          : Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Elevated glass (modals, sheets)
  static BoxDecoration elevated(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? const Color(0xFF151520).withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.06),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
          blurRadius: 80,
          offset: const Offset(0, 24),
        ),
      ],
    );
  }
}
