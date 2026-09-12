import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable frosted-glass container used throughout PawBoleh.
///
/// Wraps [child] in a blurred, semi-transparent, rounded surface with a
/// soft border and shadow. Optionally accepts a background [gradient]
/// that tints the glass, and an [onTap] callback for interactive cards.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.gradient,
    this.borderRadius = 28,
    this.blurSigma = 10,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.semanticLabel,
    this.tintOpacity = 0.18,
  });

  final Widget child;
  final Gradient? gradient;
  final double borderRadius;
  final double blurSigma;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double tintOpacity;

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: gradient != null
                ? gradient!.tinted(tintOpacity)
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) {
      return Semantics(label: semanticLabel, child: content);
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}

/// Helper extension so gradients can be tinted/opacity-adjusted without
/// manually rebuilding the colors list everywhere.
extension GradientTint on Gradient {
  Gradient tinted(double opacity) {
    if (this is LinearGradient) {
      final g = this as LinearGradient;
      return LinearGradient(
        begin: g.begin,
        end: g.end,
        colors: g.colors.map((c) => c.withValues(alpha: opacity)).toList(),
        stops: g.stops,
        tileMode: g.tileMode,
        transform: g.transform,
      );
    }
    return this;
  }
}
