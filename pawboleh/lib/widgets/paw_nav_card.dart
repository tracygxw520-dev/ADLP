import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'cat_mascot.dart';
import 'glass_card.dart';

/// The large glassmorphism navigation cards used on the Dashboard,
/// e.g. "Paw Live" and "Paw Snap" — each fronted by the cat mascot
/// holding the tool the card represents.
class PawNavCard extends StatelessWidget {
  const PawNavCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.prop,
    required this.gradient,
    required this.onTap,
    required this.semanticLabel,
  });

  final String title;
  final String subtitle;
  final CatProp prop;
  final Gradient gradient;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GlassCard(
        gradient: gradient,
        borderRadius: 28,
        padding: const EdgeInsets.all(20),
        tintOpacity: 0.85,
        onTap: onTap,
        semanticLabel: semanticLabel,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget + 50),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.cardTitle.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.cardSubtitleOnDark,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        title,
                        style: AppTextStyles.chipLabel.copyWith(
                          color: gradient.colors.last,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CatMascot(size: 68, prop: prop),
            ],
          ),
        ),
      ),
    );
  }
}
