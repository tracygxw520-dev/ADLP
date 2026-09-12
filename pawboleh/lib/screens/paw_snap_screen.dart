import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

enum _GenState { empty, loading, ready }

/// Gema Snap tab content — content generator with empty, loading, and ready
/// states, producing a video script, a WhatsApp promo message, and tags.
class PawSnapView extends StatefulWidget {
  const PawSnapView({super.key});

  @override
  State<PawSnapView> createState() => _PawSnapViewState();
}

class _PawSnapViewState extends State<PawSnapView> {
  String _selectedAudience = 'Gen Z';
  _GenState _state = _GenState.empty;

  final List<String> _audiences = const [
    'Gen Z',
    'Millennial Moms',
    'Working Professionals',
    'Wedding Shoppers',
  ];

  static const String _videoScript =
      'Open on the embroidered sleeve, pan down to the flowing hem, then a '
      'quick twirl to show movement before the price card fades in.';
  static const String _whatsappPromo =
      'Restock alert for our best-selling piece! Ready to ship within 2 '
      'business days — reply "YES" to reserve yours.';
  static const List<String> _tags = [
    '#pawboleh',
    '#kiranaatelier',
    '#ootdraya',
    '#fashionmsme',
  ];

  Future<void> _capturePhoto() async {
    setState(() => _state = _GenState.loading);
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() => _state = _GenState.ready);
  }

  void _retake() => setState(() => _state = _GenState.empty);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Back',
                  child: const Icon(
                    LucideIcons.arrowLeft300,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text('Gema Snap', style: AppTextStyles.cardTitle),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _CameraViewfinder(
              state: _state,
              onCapture: _capturePhoto,
              onRetake: _retake,
            ),
            const SizedBox(height: AppSpacing.md),
            _AudienceDropdown(
              selected: _selectedAudience,
              options: _audiences,
              onChanged: (v) =>
                  setState(() => _selectedAudience = v ?? _selectedAudience),
            ),
            const SizedBox(height: AppSpacing.lg),

            _buildOutputZone(),
            const SizedBox(height: AppSpacing.lg),
            _buildActionZone(),
            const SizedBox(height: 80), // clearance for the floating nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildOutputZone() {
    switch (_state) {
      case _GenState.empty:
        return _EmptyOutputState(onCapture: _capturePhoto);
      case _GenState.loading:
        return const _LoadingOutputState();
      case _GenState.ready:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OutputSection(
              icon: LucideIcons.video300,
              gradient: AppColors.orangeGradient,
              title: 'Video script',
              body: _videoScript,
            ),
            const SizedBox(height: AppSpacing.sm),
            _OutputSection(
              icon: LucideIcons.messageCircle300,
              gradient: AppColors.tealGradient,
              title: 'WhatsApp promo',
              body: _whatsappPromo,
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(16),
              semanticLabel: 'Suggested tags',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tags', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tealStart.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          tag,
                          style: AppTextStyles.chipLabel.copyWith(
                            color: AppColors.tealStart,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildActionZone() {
    final enabled = _state == _GenState.ready;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: AppSpacing.minTouchTarget,
          child: ElevatedButton.icon(
            onPressed: enabled ? () => _toast('Posting to TikTok…') : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              disabledBackgroundColor: AppColors.textPrimary.withValues(
                alpha: 0.25,
              ),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              side: const BorderSide(color: AppColors.gold, width: 1.5),
              elevation: 0,
            ),
            icon: const Icon(LucideIcons.music300, color: AppColors.gold),
            label: Text('Post to TikTok', style: AppTextStyles.buttonLabel),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          height: AppSpacing.minTouchTarget,
          child: Opacity(
            opacity: enabled ? 1 : 0.35,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.deepOlive,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.gold, width: 1.5),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: enabled
                      ? () => _toast('Pushing to AI Livestream…')
                      : null,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.sparkles300,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Generate campaign ideas',
                          style: AppTextStyles.buttonLabel,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }
}

/// Camera box: empty capture prompt, or the captured product photo with
/// a retake affordance once a photo has been taken.
class _CameraViewfinder extends StatelessWidget {
  const _CameraViewfinder({
    required this.state,
    required this.onCapture,
    required this.onRetake,
  });

  final _GenState state;
  final VoidCallback onCapture;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = state != _GenState.empty;

    return Semantics(
      label: hasPhoto
          ? 'Captured product photo'
          : 'Empty camera viewfinder, tap to capture a product photo',
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: hasPhoto
              ? const LinearGradient(
                  colors: [AppColors.confettiPink, Color(0xFFF6B7C2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: hasPhoto ? null : Colors.white.withValues(alpha: 0.5),
        ),
        child: Stack(
          children: [
            Center(
              child: hasPhoto
                  ? Icon(
                      LucideIcons.shirt300,
                      size: 84,
                      color: AppColors.textPrimary.withValues(alpha: 0.8),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.imagePlus300,
                          size: 44,
                          color: AppColors.textPrimary.withValues(alpha: 0.45),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Tap to snap your product',
                          style: AppTextStyles.cardSubtitle,
                        ),
                      ],
                    ),
            ),
            if (!hasPhoto)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: onCapture,
                  ),
                ),
              ),
            if (hasPhoto)
              Positioned(
                bottom: 12,
                right: 12,
                child: FloatingActionButton(
                  heroTag: 'retake_photo',
                  onPressed: onRetake,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 2,
                  child: const Icon(LucideIcons.refreshCw300),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AudienceDropdown extends StatelessWidget {
  const _AudienceDropdown({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final String selected;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.minTouchTarget,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Semantics(
        label: 'Target audience selector, currently $selected',
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            icon: const Icon(
              LucideIcons.chevronDown300,
              color: AppColors.textPrimary,
            ),
            style: AppTextStyles.cardSubtitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            items: options
                .map(
                  (a) => DropdownMenuItem<String>(
                    value: a,
                    child: Text('Target audience: $a'),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _OutputSection extends StatelessWidget {
  const _OutputSection({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Gradient gradient;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      semanticLabel: '$title output',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradient,
                ),
                child: Icon(icon, color: Colors.white, size: 15),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.sectionLabel),
              const Spacer(),
              Semantics(
                button: true,
                label: 'Copy $title',
                child: Icon(
                  LucideIcons.copy300,
                  size: 16,
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: AppTextStyles.cardSubtitle),
        ],
      ),
    );
  }
}

class _EmptyOutputState extends StatelessWidget {
  const _EmptyOutputState({required this.onCapture});
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      semanticLabel: 'No content generated yet',
      child: Column(
        children: [
          Icon(
            LucideIcons.sparkles300,
            size: 32,
            color: AppColors.textPrimary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Snap a photo to generate content',
            style: AppTextStyles.cardSubtitle.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Your video script, WhatsApp promo, and tags will appear here.',
            style: AppTextStyles.cardSubtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LoadingOutputState extends StatefulWidget {
  const _LoadingOutputState();

  @override
  State<_LoadingOutputState> createState() => _LoadingOutputStateState();
}

class _LoadingOutputStateState extends State<_LoadingOutputState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Generating content, please wait',
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final opacity = 0.4 + (_controller.value * 0.3);
          return Column(
            children: List.generate(3, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: i == 2 ? 0 : 8),
                child: Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(
                      alpha: opacity * 0.15,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: i == 1
                      ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.deepOlive,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
