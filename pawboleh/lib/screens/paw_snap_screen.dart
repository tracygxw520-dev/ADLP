import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/content_production.dart';
import '../services/content_production_api.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/remote_image.dart';

enum _GenState { empty, loading, ready, failed }

/// Gema Snap turns a product photo and a creative brief into AI-generated
/// media while using the same visual language as the surrounding Gema UI.
class PawSnapView extends StatefulWidget {
  const PawSnapView({super.key});

  @override
  State<PawSnapView> createState() => _PawSnapViewState();
}

class _PawSnapViewState extends State<PawSnapView> {
  final _productName = TextEditingController();
  final _productDescription = TextEditingController();
  late final ContentProductionApi _api;

  String _selectedAudience = 'Gen Z';
  _GenState _state = _GenState.empty;
  Uint8List? _photoBytes;
  String? _photoName;
  ContentProduction? _production;
  String? _errorMessage;
  int _requestId = 0;
  bool _isRefreshing = false;

  static const _audiences = [
    'Gen Z',
    'Millennial Moms',
    'Working Professionals',
    'Wedding Shoppers',
  ];

  @override
  void initState() {
    super.initState();
    _api = ContentProductionApi();
  }

  @override
  void dispose() {
    _productName.dispose();
    _productDescription.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_state == _GenState.loading) return;
    final requestId = ++_requestId;
    if (_isRefreshing) setState(() => _isRefreshing = false);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.bytes == null || !mounted || requestId != _requestId) return;
      setState(() {
        _photoBytes = file.bytes;
        _photoName = file.name;
        _production = null;
        _errorMessage = null;
        _isRefreshing = false;
        _state = _GenState.empty;
      });
    } catch (_) {
      if (mounted) {
        _showMessage('Could not open your photos. Please try again.');
      }
    }
  }

  Future<void> _generate() async {
    final name = _productName.text.trim();
    final description = _productDescription.text.trim();
    if (_photoBytes == null || _photoName == null) {
      _showMessage('Choose a product photo first.');
      return;
    }
    if (name.length < 2) {
      _showMessage('Add a product name so Gema Snap can create the visuals.');
      return;
    }
    if (description.length < 10) {
      _showMessage(
        'Add a little more product detail (at least 10 characters).',
      );
      return;
    }

    final requestId = ++_requestId;
    setState(() {
      _state = _GenState.loading;
      _errorMessage = null;
      _production = null;
      _isRefreshing = false;
    });

    try {
      final imageUrl = await _api.uploadImage(_photoName!, _photoBytes!);
      final production = await _api.create(
        CreateContentProductionRequest(
          productName: name,
          productDescription: description,
          productImageUrl: imageUrl,
          targetAudience: _selectedAudience,
        ),
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _production = production;
        _state = _stateForProduction(production);
        _errorMessage = production.errorMessage;
      });
    } on ContentProductionApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _state = _GenState.failed;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _state = _GenState.failed;
        _errorMessage =
            'Gema Snap could not reach the campaign service. Check that the API is running, then try again.';
      });
    }
  }

  Future<void> _refreshCampaign() async {
    final current = _production;
    if (current == null || current.id.isEmpty || _isRefreshing) return;
    final requestId = ++_requestId;
    setState(() => _isRefreshing = true);
    try {
      final production = await _api.getById(current.id);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _production = production;
        _state = _stateForProduction(production);
        _errorMessage = production.errorMessage;
      });
    } on ContentProductionApiException catch (error) {
      if (mounted && requestId == _requestId) _showMessage(error.message);
    } catch (_) {
      if (mounted && requestId == _requestId) {
        _showMessage('Could not refresh this Gema Snap. Please try again.');
      }
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _onBriefChanged() {
    if (_state == _GenState.ready || _state == _GenState.failed) {
      _requestId++;
      setState(() {
        _state = _GenState.empty;
        _production = null;
        _errorMessage = null;
        _isRefreshing = false;
      });
      return;
    }
    setState(() {});
  }

  void _onAudienceChanged(String? audience) {
    if (audience == null || audience == _selectedAudience) return;
    _selectedAudience = audience;
    _onBriefChanged();
  }

  _GenState _stateForProduction(ContentProduction production) {
    final needsAttention =
        production.status == ContentProductionStatus.failed ||
        production.status == ContentProductionStatus.partial;
    return needsAttention && !_hasText(production.posterUrl)
        ? _GenState.failed
        : _GenState.ready;
  }

  Future<void> _openAsset(String? asset, String label) async {
    final url = _api.resolveAssetUrl(asset);
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null) {
      _showMessage('$label is not available yet.');
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!opened && mounted) {
        _showMessage('Could not open the $label on this device.');
      }
    } catch (_) {
      if (mounted) _showMessage('Could not open the $label on this device.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _state == _GenState.loading;
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
            Text('Gema Snap', style: AppTextStyles.cardTitle),
            const SizedBox(height: 4),
            Text(
              'Add a product photo and creative brief. Gema turns both into a poster and promo video.',
              style: AppTextStyles.cardSubtitle,
            ),
            const SizedBox(height: AppSpacing.md),
            _CameraViewfinder(
              photoBytes: _photoBytes,
              isBusy: isLoading,
              onPickPhoto: _pickPhoto,
              onRetake: _pickPhoto,
            ),
            const SizedBox(height: AppSpacing.md),
            _BriefFields(
              productName: _productName,
              productDescription: _productDescription,
              enabled: !isLoading,
              onChanged: _onBriefChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            _AudienceDropdown(
              selected: _selectedAudience,
              options: _audiences,
              enabled: !isLoading,
              onChanged: _onAudienceChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            _GenerateButton(isLoading: isLoading, onGenerate: _generate),
            const SizedBox(height: AppSpacing.lg),
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
      case _GenState.failed:
        return _FailureOutputState(
          message: _friendlyFailureMessage(_errorMessage),
          onRetry: _generate,
        );
      case _GenState.ready:
        final production = _production;
        if (production == null) return const _EmptyOutputState();
        return _CampaignOutput(
          production: production,
          posterUrl: _api.resolveAssetUrl(production.posterUrl),
          isRefreshing: _isRefreshing,
          onRefresh: _refreshCampaign,
          onOpenPoster: () => _openAsset(production.posterUrl, 'poster'),
          onOpenVideo: () => _openAsset(production.videoUrl, 'promo video'),
        );
    }
  }
}

class _CameraViewfinder extends StatelessWidget {
  const _CameraViewfinder({
    required this.photoBytes,
    required this.isBusy,
    required this.onPickPhoto,
    required this.onRetake,
  });

  final Uint8List? photoBytes;
  final bool isBusy;
  final VoidCallback onPickPhoto;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoBytes != null;
    return Semantics(
      label: hasPhoto
          ? 'Selected product image reference. Tap retake to choose another image.'
          : 'Product image reference selector. Tap to choose an image.',
      child: Container(
        height: 220,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: hasPhoto
              ? AppColors.tealStart
              : Colors.white.withValues(alpha: 0.5),
          border: hasPhoto
              ? null
              : Border.all(
                  color: AppColors.textPrimary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              Image.memory(photoBytes!, fit: BoxFit.cover)
            else
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onPickPhoto,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.camera300,
                        size: 44,
                        color: AppColors.textPrimary.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Choose a product image',
                        style: AppTextStyles.cardSubtitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'or choose an image',
                        style: AppTextStyles.cardSubtitle,
                      ),
                    ],
                  ),
                ),
              ),
            if (hasPhoto)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Image reference ready',
                          style: AppTextStyles.chipLabel.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      heroTag: 'retake_product_photo',
                      onPressed: isBusy ? null : onRetake,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 2,
                      tooltip: 'Choose another product image',
                      child: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BriefFields extends StatelessWidget {
  const _BriefFields({
    required this.productName,
    required this.productDescription,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController productName;
  final TextEditingController productDescription;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SnapTextField(
          controller: productName,
          label: 'Product name',
          hint: 'e.g. Embroidered Kebaya Set',
          enabled: enabled,
          textInputAction: TextInputAction.next,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SnapTextField(
          controller: productDescription,
          label: 'Creative brief for the AI',
          hint:
              'Describe the style, setting, mood, and product details to show.',
          enabled: enabled,
          minLines: 3,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SnapTextField extends StatelessWidget {
  const _SnapTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.textInputAction,
    required this.onChanged,
    this.minLines,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;
  final TextInputAction textInputAction;
  final VoidCallback onChanged;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      onChanged: (_) => onChanged(),
      style: AppTextStyles.cardSubtitle.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppTextStyles.chipLabel,
        hintStyle: AppTextStyles.cardSubtitle,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.tealStart, width: 1.5),
        ),
      ),
    );
  }
}

class _AudienceDropdown extends StatelessWidget {
  const _AudienceDropdown({
    required this.selected,
    required this.options,
    required this.enabled,
    required this.onChanged,
  });

  final String selected;
  final List<String> options;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.minTouchTarget,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
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
                  (audience) => DropdownMenuItem<String>(
                    value: audience,
                    child: Text('Target audience: $audience'),
                  ),
                )
                .toList(),
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.isLoading, required this.onGenerate});

  final bool isLoading;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.minTouchTarget,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.tealGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: isLoading ? null : onGenerate,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.sparkles300,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Generate poster & video',
                          style: AppTextStyles.buttonLabel,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampaignOutput extends StatelessWidget {
  const _CampaignOutput({
    required this.production,
    required this.posterUrl,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onOpenPoster,
    required this.onOpenVideo,
  });

  final ContentProduction production;
  final String? posterUrl;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onOpenPoster;
  final VoidCallback onOpenVideo;

  @override
  Widget build(BuildContext context) {
    final isPartialResult = _isPartialVisualProduction(production);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (production.isInProgress) ...[
          _PendingOutputState(isRefreshing: isRefreshing, onRefresh: onRefresh),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (posterUrl != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _PosterCard(posterUrl: posterUrl!, onOpen: onOpenPoster),
        ],
        if (isPartialResult) ...[
          const SizedBox(height: AppSpacing.sm),
          const _VideoUnavailableNotice(),
        ],
        if (_hasText(production.videoUrl)) ...[
          const SizedBox(height: AppSpacing.sm),
          _VideoCard(onOpen: onOpenVideo),
        ],
      ],
    );
  }
}

class _VideoUnavailableNotice extends StatelessWidget {
  const _VideoUnavailableNotice();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      semanticLabel: 'Promo video unavailable',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.tealStart),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Poster ready - video unavailable',
                  style: AppTextStyles.sectionLabel,
                ),
                const SizedBox(height: 4),
                Text(
                  'The promo video could not be generated. Change your photo or creative brief, then generate again.',
                  style: AppTextStyles.cardSubtitle.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.posterUrl, required this.onOpen});

  final String posterUrl;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      semanticLabel: 'Generated AI poster',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 0.8,
              child: RemoteImage(url: posterUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                const Icon(LucideIcons.image300, color: AppColors.tealStart),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('AI poster', style: AppTextStyles.sectionLabel),
                ),
                IconButton(
                  tooltip: 'Open poster',
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      semanticLabel: 'Generated promotional video',
      onTap: onOpen,
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.orangeGradient,
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Promo video', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 3),
                Text(
                  'Open the generated video in your browser.',
                  style: AppTextStyles.cardSubtitle,
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded, color: AppColors.textPrimary),
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
      borderRadius: 20,
      semanticLabel: 'Campaign preview',
      child: Column(
        children: [
          Icon(
            LucideIcons.sparkles300,
            size: 32,
            color: AppColors.textPrimary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your poster and video will appear here',
            style: AppTextStyles.cardSubtitle.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Add a product image and creative brief, then generate your visuals.',
            style: AppTextStyles.cardSubtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FailureOutputState extends StatelessWidget {
  const _FailureOutputState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      semanticLabel: 'Visual generation error',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.deepOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Couldn’t generate your visuals',
                  style: AppTextStyles.sectionLabel,
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.cardSubtitle.copyWith(height: 1.4),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.tealStart,
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingOutputState extends StatelessWidget {
  const _PendingOutputState({
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      semanticLabel: 'Visual generation in progress',
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: AppColors.tealStart),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your poster and video are still generating',
                  style: AppTextStyles.sectionLabel,
                ),
                const SizedBox(height: 4),
                Text(
                  'Refresh in a moment to see the completed visuals.',
                  style: AppTextStyles.cardSubtitle,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh campaign',
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
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
      label: 'Generating poster and promo video, please wait',
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final opacity = 0.4 + (_controller.value * 0.3);
          return Column(
            children: List.generate(3, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index == 2 ? 0 : 8),
                child: Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(
                      alpha: opacity * 0.15,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: index == 1
                      ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.textPrimary.withValues(
                                alpha: 0.5,
                              ),
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

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

bool _isPartialVisualProduction(ContentProduction production) {
  final videoMissing = !_hasText(production.videoUrl);
  final hasPoster = _hasText(production.posterUrl);
  return hasPoster &&
      videoMissing &&
      (production.status == ContentProductionStatus.partial ||
          production.status == ContentProductionStatus.failed);
}

String _friendlyFailureMessage(String? message) {
  const fallback =
      'We couldn\'t generate your visuals. Try a different photo or creative brief.';
  final value = message?.trim();
  if (value == null || value.isEmpty || _hasRawProviderDetails(value)) {
    return fallback;
  }
  return value;
}

bool _hasRawProviderDetails(String value) {
  final normalized = value.toLowerCase();
  return normalized.contains('openai') ||
      normalized.contains('video_') ||
      normalized.contains('image_') ||
      normalized.contains('moderation') ||
      normalized.contains('provider') ||
      normalized.contains('api error') ||
      normalized.contains('status \'failed\'') ||
      RegExp(r'\b(?:video|image|resp|job)_[a-z0-9_-]+').hasMatch(normalized);
}
