import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A reusable frosted-glass container used throughout Gema.
///
/// Wraps [child] in a blurred, semi-transparent, rounded surface with a
/// soft shadow. Optionally accepts a background [gradient]
/// that tints the glass, and an [onTap] callback for interactive cards.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.gradient,
    this.borderRadius = 24,
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
                      AppColors.confettiPink.withValues(alpha: 0.72),
                      Colors.white.withValues(alpha: 0.42),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
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
