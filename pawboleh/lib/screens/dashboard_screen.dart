import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_mascot.dart';
import '../widgets/paw_nav_card.dart';

/// Dashboard tab content. Reports taps via [onNavigate] so [MainShell]
/// can switch tabs instead of pushing a new route.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key, required this.onNavigate, required this.onNotifications, required this.onProfile});

  /// 1 = Paw Live tab, 2 = Paw Snap tab (see MainShell tab order).
  final ValueChanged<int> onNavigate;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            _BrandBar(onNotifications: onNotifications, onProfile: onProfile),
            const SizedBox(height: AppSpacing.lg),
            Text(AppBrand.greeting, style: AppTextStyles.greeting),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'What are we creating today?',
              style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.md),
            PawNavCard(
              title: 'Paw Live',
              subtitle: '30-illustration-file, the hot release',
              prop: CatProp.mic,
              gradient: AppColors.orangeGradient,
              semanticLabel: 'Open Paw Live, AI livestream tool',
              onTap: () => onNavigate(1),
            ),
            const SizedBox(height: AppSpacing.md),
            PawNavCard(
              title: 'Paw Snap',
              subtitle: 'Choose one card to Paw Snap pick',
              prop: CatProp.camera,
              gradient: AppColors.tealGradient,
              semanticLabel: 'Open Paw Snap, content generator tool',
              onTap: () => onNavigate(2),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(height: 80), // clearance for the floating nav bar
          ],
        ),
      ),
    );
  }
}

class _BrandBar extends StatelessWidget {
  const _BrandBar({required this.onNotifications, required this.onProfile});

  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [AppColors.orangeStart, AppColors.tealStart],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(child: CatMascot(size: 18)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(AppBrand.name, style: AppTextStyles.brandLabel),
        ),
        Semantics(
          button: true,
          label: 'Notifications',
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onNotifications,
            child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: AppColors.textPrimary, size: 18),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          button: true,
          label: 'Open profile',
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onProfile,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: AppColors.tealStart, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                'KA',
                style: AppTextStyles.chipLabel.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
