import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class ProfilePanel extends StatefulWidget {
  const ProfilePanel({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  State<ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<ProfilePanel> {
  bool _liveReminders = true;

  @override
  Widget build(BuildContext context) {
    return _PanelSurface(
      child: Column(
        children: [
          _PanelHeader(
            title: 'Profile',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppColors.tealStart,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'KA',
              style: AppTextStyles.cardTitle.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Kirana Atelier', style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text('Fashion MSME workspace', style: AppTextStyles.cardSubtitle),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _InfoRow(
                  icon: LucideIcons.atSign300,
                  label: 'Account',
                  value: 'kirana@atelier.my',
                ),
                const Divider(height: AppSpacing.lg),
                _InfoRow(
                  icon: LucideIcons.award300,
                  label: 'Plan',
                  value: 'Gema Starter',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Gema Live reminders',
                style: AppTextStyles.sectionLabel,
              ),
              subtitle: Text(
                'Keep upcoming livestream cues on',
                style: AppTextStyles.cardSubtitle,
              ),
              value: _liveReminders,
              activeTrackColor: AppColors.tealStart,
              onChanged: (value) => setState(() => _liveReminders = value),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.minTouchTarget,
            child: OutlinedButton.icon(
              onPressed: widget.onSignOut,
              icon: const Icon(LucideIcons.logOut300),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.liveRed,
                side: const BorderSide(color: AppColors.liveRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelSurface extends StatelessWidget {
  const _PanelSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width.clamp(320, 420).toDouble(),
      height: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.cardTitle),
        const Spacer(),
        IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          icon: const Icon(LucideIcons.x300),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.tealStart),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTextStyles.sectionLabel)),
        Text(
          value,
          style: AppTextStyles.chipLabel.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
