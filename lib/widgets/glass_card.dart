import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/glass_decoration.dart';

enum GlassVariant { standard, elevated }

class GlassCard extends StatelessWidget {
  final Widget child;
  final GlassVariant variant;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.variant = GlassVariant.standard,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ??
        (variant == GlassVariant.elevated ? 20.0 : 16.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: variant == GlassVariant.elevated
              ? GlassDecoration.elevated(context)
              : GlassDecoration.card(context),
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}
