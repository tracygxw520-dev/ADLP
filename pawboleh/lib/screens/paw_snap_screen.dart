import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

enum _GenState { empty, loading, ready }

/// Paw Snap Screen (TikTok Content Engine)
/// Connects dynamic product context + target demographic dropdown to Express OpenAI JSON Endpoint.
class PawSnapView extends StatefulWidget {
  const PawSnapView({super.key});

  @override
  State<PawSnapView> createState() => _PawSnapViewState();
}

class _PawSnapViewState extends State<PawSnapView> {
  String _selectedAudience = 'Gen Z trendy';
  _GenState _state = _GenState.empty;
  bool _hasCustomImage = false;

  final TextEditingController _productContextController = TextEditingController(
    text: 'Handcrafted Premium Silk Raya Kurung Set',
  );

  final List<String> _audiences = const [
    'Gen Z trendy',
    'Gen X polite & modest',
    'Millennial professional',
    'Luxury & wedding aesthetic',
  ];

  String _returnedHook = '';
  String _returnedScript = '';
  String _returnedCaption = '';
  List<String> _returnedTags = [];

  @override
  void dispose() {
    _productContextController.dispose();
    super.dispose();
  }

  Future<void> _generateContent() async {
    setState(() => _state = _GenState.loading);

    final contextText = _productContextController.text.trim().isEmpty
        ? 'Handcrafted Fashion Product'
        : _productContextController.text.trim();

    try {
      // Trigger Express /api/paw-snap/generate with dynamic demographic & product context
      final response = await ApiService.generatePawSnapContent(
        imageContext: contextText,
        demographic: _selectedAudience,
      );

      if (!mounted) return;

      setState(() {
        _returnedHook = response['hook'] as String? ?? 'Check out this item!';
        _returnedScript = response['script'] as String? ?? 'Full narration script...';
        _returnedCaption = response['caption'] as String? ?? 'Shop now!';
        _returnedTags = (response['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            ['#PawSnap', '#FashionTok'];
        _state = _GenState.ready;
      });
    } catch (e) {
      debugPrint('Paw Snap Connection Error: $e');

      if (!mounted) return;

      setState(() => _state = _GenState.empty);

      // Display error alert in UI via SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paw Snap Network Error: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _reset() {
    setState(() {
      _state = _GenState.empty;
      _hasCustomImage = false;
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

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
                Text('Paw Snap · TikTok Content Engine', style: AppTextStyles.cardTitle),
                const Spacer(),
                if (_state == _GenState.ready)
                  IconButton(
                    onPressed: _reset,
                    icon: const Icon(LucideIcons.refreshCw300, color: AppColors.textPrimary, size: 20),
                    tooltip: 'Start New Snap',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Image Upload / Viewfinder Component
            _CameraViewfinder(
              state: _state,
              hasCustomImage: _hasCustomImage,
              controller: _productContextController,
              onUploadImage: () => setState(() => _hasCustomImage = true),
              onRetake: _reset,
            ),
            const SizedBox(height: AppSpacing.md),

            // Target Demographic Dropdown
            _AudienceDropdown(
              selected: _selectedAudience,
              options: _audiences,
              onChanged: (v) => setState(() => _selectedAudience = v ?? _selectedAudience),
            ),
            const SizedBox(height: AppSpacing.md),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: AppSpacing.minTouchTarget,
              child: ElevatedButton.icon(
                onPressed: _state == _GenState.loading ? null : _generateContent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepOlive,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  side: const BorderSide(color: AppColors.gold, width: 1.5),
                  elevation: 2,
                ),
                icon: const Icon(LucideIcons.sparkles300, color: AppColors.gold),
                label: Text(
                  _state == _GenState.loading ? 'Generating OpenAI Content...' : 'Generate TikTok Content',
                  style: AppTextStyles.buttonLabel,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Output Results Section
            _buildOutputZone(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputZone() {
    switch (_state) {
      case _GenState.empty:
        return const _EmptyOutputState();
      case _GenState.loading:
        return const _LoadingOutputState();
      case _GenState.ready:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TikTok Hook Card
            _OutputSection(
              icon: LucideIcons.zap300,
              gradient: AppColors.orangeGradient,
              title: 'TikTok Video Hook (Opening Line)',
              body: _returnedHook,
              onCopy: () => _copyToClipboard(_returnedHook, 'Video Hook'),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 2. Video Script Card
            _OutputSection(
              icon: LucideIcons.video300,
              gradient: AppColors.tealGradient,
              title: 'TikTok Narration & Scene Script',
              body: _returnedScript,
              onCopy: () => _copyToClipboard(_returnedScript, 'Video Script'),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 3. Caption Card
            _OutputSection(
              icon: LucideIcons.messageCircle300,
              gradient: AppColors.orangeGradient,
              title: 'TikTok Post Caption',
              body: _returnedCaption,
              onCopy: () => _copyToClipboard(_returnedCaption, 'Caption'),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Hashtag Chips Card
            GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(16),
              semanticLabel: 'Hashtags',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Suggested Hashtags', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _returnedTags.map((tag) {
                      return InkWell(
                        onTap: () => _copyToClipboard(tag, 'Tag $tag'),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.tealStart.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            tag,
                            style: AppTextStyles.chipLabel.copyWith(color: AppColors.tealStart),
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
}

class _CameraViewfinder extends StatelessWidget {
  const _CameraViewfinder({
    required this.state,
    required this.hasCustomImage,
    required this.controller,
    required this.onUploadImage,
    required this.onRetake,
  });

  final _GenState state;
  final bool hasCustomImage;
  final TextEditingController controller;
  final VoidCallback onUploadImage;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.5)],
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [AppColors.confettiPink, Color(0xFFF6B7C2)],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasCustomImage ? LucideIcons.checkCircle2300 : LucideIcons.imagePlus300,
                        size: 48,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasCustomImage ? 'Product Image Loaded ✓' : 'Upload Product Photo',
                        style: AppTextStyles.cardSubtitle.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onUploadImage,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Product Context / Name',
              labelStyle: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              hintText: 'e.g. Handmade Silk Raya Dress in Emerald Green',
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
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
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown300, color: AppColors.textPrimary),
          style: AppTextStyles.cardSubtitle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          items: options
              .map((a) => DropdownMenuItem<String>(
                    value: a,
                    child: Text('Target Demographic: $a'),
                  ))
              .toList(),
          onChanged: onChanged,
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
    required this.onCopy,
  });

  final IconData icon;
  final Gradient gradient;
  final String title;
  final String body;
  final VoidCallback onCopy;

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
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
                child: Icon(icon, color: Colors.white, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTextStyles.sectionLabel)),
              IconButton(
                onPressed: onCopy,
                icon: const Icon(LucideIcons.copy300, size: 16, color: AppColors.textPrimary),
                tooltip: 'Copy',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(body, style: AppTextStyles.cardSubtitle),
        ],
      ),
    );
  }
}

class _EmptyOutputState extends StatelessWidget {
  const _EmptyOutputState();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      semanticLabel: 'No content generated yet',
      child: Column(
        children: [
          Icon(LucideIcons.sparkles300, size: 32, color: AppColors.textPrimary.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Upload a product & choose a demographic',
            style: AppTextStyles.cardSubtitle.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Your OpenAI generated TikTok video hook, narration script, and hashtags will appear here.',
            style: AppTextStyles.cardSubtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LoadingOutputState extends StatelessWidget {
  const _LoadingOutputState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white54,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: AppColors.deepOlive),
          SizedBox(height: 16),
          Text(
            'OpenAI GPT-4o-mini is crafting your viral TikTok Hook & Script...',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
