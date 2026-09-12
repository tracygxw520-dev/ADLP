import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Displays a remote raster or SVG image with consistent loading and error UI.
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.errorBuilder,
    super.key,
  });

  final String url;
  final BoxFit fit;
  final Alignment alignment;
  final WidgetBuilder? errorBuilder;

  bool get _isSvg =>
      Uri.tryParse(url)?.path.toLowerCase().endsWith('.svg') ?? false;

  @override
  Widget build(BuildContext context) {
    final failed = errorBuilder ?? (_) => const _ImageUnavailable();
    if (url.trim().isEmpty) return failed(context);

    if (_isSvg) {
      return SvgPicture.network(
        url,
        fit: fit,
        alignment: alignment,
        placeholderBuilder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (_, _, _) => failed(context),
      );
    }

    return Image.network(
      url,
      fit: fit,
      alignment: alignment,
      loadingBuilder: (context, child, progress) =>
          progress == null
              ? child
              : const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, _, _) => failed(context),
    );
  }
}

class _ImageUnavailable extends StatelessWidget {
  const _ImageUnavailable();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 34)),
      );
}
