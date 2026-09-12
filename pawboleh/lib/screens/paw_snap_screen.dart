import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/content_production.dart';
import '../services/content_production_api.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/remote_image.dart';

enum _GenState { empty, loading, ready, failed }

/// Paw Snap turns a product photo and a short brief into campaign-ready media.
/// The visual language deliberately matches the surrounding PawBoleh UI.
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
      if (mounted) _showMessage('Could not open your photos. Please try again.');
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
      _showMessage('Add a product name so Paw Snap can create the campaign.');
      return;
    }
    if (description.length < 10) {
      _showMessage('Add a little more product detail (at least 10 characters).');
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
        _state = production.status == ContentProductionStatus.failed
            ? _GenState.failed
            : _GenState.ready;
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
            'Paw Snap could not reach the campaign service. Check that the API is running, then try again.';
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
        _state = production.status == ContentProductionStatus.failed
            ? _GenState.failed
            : _GenState.ready;
        _errorMessage = production.errorMessage;
      });
    } on ContentProductionApiException catch (error) {
      if (mounted && requestId == _requestId) _showMessage(error.message);
    } catch (_) {
      if (mounted && requestId == _requestId) {
        _showMessage('Could not refresh this Paw Snap. Please try again.');
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

  Future<void> _copyCaption() async {
    final production = _production;
    if (production == null) return;
    final caption = [
      production.headline,
      production.tagline,
      production.callToAction,
    ].where(_hasText).join('\n\n');
    if (caption.isEmpty) {
      _showMessage('The caption is still being prepared.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: caption));
    if (mounted) _showMessage('Caption copied — ready to paste.');
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
      if (!opened && mounted) _showMessage('Could not open the $label on this device.');
    } catch (_) {
      if (mounted) _showMessage('Could not open the $label on this device.');
    }
  }

  List<String> _suggestedTags() {
    final rawProduct = _productName.text
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '');
    final product = rawProduct.length > 18 ? rawProduct.substring(0, 18) : rawProduct;
    final audience = _selectedAudience
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '');
    return <String>{
      '#pawboleh',
      if (product.isNotEmpty) '#$product',
      if (audience.isNotEmpty) '#$audience',
      '#supportlocal',
    }.toList(growable: false);
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
    final hasResult = _state == _GenState.ready &&
        _production != null &&
        !_production!.isInProgress;
    final hasVideo = _hasText(_production?.videoUrl);

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
            Text('Paw Snap', style: AppTextStyles.cardTitle),
            const SizedBox(height: 4),
            Text(
              'Snap your product. PawBoleh makes it campaign-ready.',
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
            if (hasResult) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildActions(hasVideo),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputZone() {
    switch (_state) {
      case _GenState.empty:
        return _EmptyOutputState(onPickPhoto: _pickPhoto);
      case _GenState.loading:
        return const _LoadingOutputState();
      case _GenState.failed:
        return _FailureOutputState(
          message: _errorMessage ?? 'Something went wrong while making your campaign.',
          onRetry: _generate,
        );
      case _GenState.ready:
        final production = _production;
        if (production == null) return _EmptyOutputState(onPickPhoto: _pickPhoto);
        return _CampaignOutput(
          production: production,
          posterUrl: _api.resolveAssetUrl(production.posterUrl),
          tags: _suggestedTags(),
          isRefreshing: _isRefreshing,
          onCopyCaption: _copyCaption,
          onRefresh: _refreshCampaign,
          onOpenPoster: () => _openAsset(production.posterUrl, 'marketing poster'),
          onOpenVideo: () => _openAsset(production.videoUrl, 'promo video'),
        );
    }
  }

  Widget _buildActions(bool hasVideo) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: AppSpacing.minTouchTarget,
          child: ElevatedButton.icon(
            onPressed: _copyCaption,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            icon: const Icon(Icons.copy_all_rounded),
            label: Text('Copy caption', style: AppTextStyles.buttonLabel),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          height: AppSpacing.minTouchTarget,
          child: Opacity(
            opacity: hasVideo ? 1 : 0.45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.orangeGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: hasVideo
                      ? () => _openAsset(_production?.videoUrl, 'promo video')
                      : null,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          hasVideo ? 'Open promo video' : 'Promo video unavailable',
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
          ? 'Selected product photo. Tap retake to choose another image.'
          : 'Empty product photo viewfinder. Tap to choose an image.',
      child: Container(
        height: 220,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: hasPhoto ? AppColors.tealStart : Colors.white.withValues(alpha: 0.5),
          border: hasPhoto
              ? null
              : Border.all(color: AppColors.textPrimary.withValues(alpha: 0.2), width: 1.5),
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
                        Icons.add_a_photo_rounded,
                        size: 44,
                        color: AppColors.textPrimary.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Tap to snap your product', style: AppTextStyles.cardSubtitle),
                      const SizedBox(height: 2),
                      Text('or choose an image', style: AppTextStyles.cardSubtitle),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Product photo ready',
                          style: AppTextStyles.chipLabel.copyWith(color: Colors.white),
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
                      tooltip: 'Retake product photo',
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
          label: 'What makes it special?',
          hint: 'Describe the material, style, price, or best use.',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            icon: const Icon(Icons.expand_more_rounded, color: AppColors.textPrimary),
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Generate Paw Snap', style: AppTextStyles.buttonLabel),
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
    required this.tags,
    required this.isRefreshing,
    required this.onCopyCaption,
    required this.onRefresh,
    required this.onOpenPoster,
    required this.onOpenVideo,
  });

  final ContentProduction production;
  final String? posterUrl;
  final List<String> tags;
  final bool isRefreshing;
  final VoidCallback onCopyCaption;
  final VoidCallback onRefresh;
  final VoidCallback onOpenPoster;
  final VoidCallback onOpenVideo;

  @override
  Widget build(BuildContext context) {
    final caption = [production.headline, production.tagline, production.callToAction]
        .where(_hasText)
        .join('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (production.isInProgress) ...[
          _PendingOutputState(
            isRefreshing: isRefreshing,
            onRefresh: onRefresh,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (_hasText(production.marketingConcept)) ...[
          _OutputSection(
            icon: Icons.auto_awesome_rounded,
            gradient: AppColors.orangeGradient,
            title: 'Campaign idea',
            body: production.marketingConcept!,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (caption.isNotEmpty) ...[
          _OutputSection(
            icon: Icons.chat_bubble_rounded,
            gradient: AppColors.tealGradient,
            title: 'Caption ready to post',
            body: caption,
            onCopy: onCopyCaption,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (_hasText(production.targetAudience)) ...[
          _OutputSection(
            icon: Icons.people_alt_rounded,
            gradient: AppColors.tealGradient,
            title: 'AI audience',
            body: production.targetAudience!,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          semanticLabel: 'Suggested tags',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Suggested tags', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
                    .map(
                      (tag) => Container(
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
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        if (posterUrl != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _PosterCard(posterUrl: posterUrl!, onOpen: onOpenPoster),
        ],
        if (_hasText(production.videoUrl)) ...[
          const SizedBox(height: AppSpacing.sm),
          _VideoCard(onOpen: onOpenVideo),
        ],
      ],
    );
  }
}

class _OutputSection extends StatelessWidget {
  const _OutputSection({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.body,
    this.onCopy,
  });

  final IconData icon;
  final Gradient gradient;
  final String title;
  final String body;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
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
              if (onCopy != null)
                IconButton(
                  tooltip: 'Copy $title',
                  onPressed: onCopy,
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: AppColors.textPrimary.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(body, style: AppTextStyles.cardSubtitle.copyWith(height: 1.45)),
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
      semanticLabel: 'Generated marketing poster',
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
                const Icon(Icons.image_outlined, color: AppColors.tealStart),
                const SizedBox(width: 8),
                Expanded(child: Text('Marketing poster', style: AppTextStyles.sectionLabel)),
                IconButton(
                  tooltip: 'Open marketing poster',
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
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.orangeGradient),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Promo video', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 3),
                Text('Open the generated video in your browser.', style: AppTextStyles.cardSubtitle),
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
  const _EmptyOutputState({required this.onPickPhoto});

  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      semanticLabel: 'No campaign generated yet',
      onTap: onPickPhoto,
      child: Column(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 32, color: AppColors.textPrimary.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Snap a product to create your campaign',
            style: AppTextStyles.cardSubtitle.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'You’ll get campaign copy, a poster, and a promo video when available.',
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
      semanticLabel: 'Campaign generation error',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.deepOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Couldn’t make this Paw Snap', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 4),
                Text(message, style: AppTextStyles.cardSubtitle.copyWith(height: 1.4)),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(foregroundColor: AppColors.tealStart),
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
      semanticLabel: 'Campaign generation in progress',
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: AppColors.tealStart),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Paw Snap is still generating', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 4),
                Text(
                  'Refresh in a moment to see the completed campaign.',
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
      label: 'Generating campaign, please wait',
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
                    color: AppColors.textPrimary.withValues(alpha: opacity * 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: index == 1
                      ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.textPrimary.withValues(alpha: 0.5),
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
