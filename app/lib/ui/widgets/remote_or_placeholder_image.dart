import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Image from bundled asset, network URL, or colored gradient placeholder.
///
/// Prefer [asset] when set. Otherwise if [url] looks like an `assets/` path,
/// load via [Image.asset]; http(s) URLs use [Image.network]. Missing/error → placeholder.
class RemoteOrPlaceholderImage extends StatelessWidget {
  const RemoteOrPlaceholderImage({
    super.key,
    this.url,
    this.asset,
    this.height,
    this.width,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.seedColor,
  });

  final String? url;
  final String? asset;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Color? seedColor;

  static bool _isAssetPath(String path) {
    final p = path.trim();
    return p.startsWith('assets/') || p.startsWith('package:');
  }

  static bool _isNetworkUrl(String path) {
    final lower = path.trim().toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppTheme.cardRadius);
    final placeholder = _Placeholder(
      color: seedColor ?? AppTheme.seed,
      height: height,
      width: width,
    );

    final assetPath = asset?.trim();
    if (assetPath != null && assetPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          assetPath,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      );
    }

    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return ClipRRect(borderRadius: radius, child: placeholder);
    }

    if (_isAssetPath(trimmed)) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          trimmed,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      );
    }

    if (!_isNetworkUrl(trimmed)) {
      return ClipRRect(borderRadius: radius, child: placeholder);
    }

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        trimmed,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: height,
            width: width,
            child: placeholder,
          );
        },
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.color,
    this.height,
    this.width,
  });

  final Color color;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.85),
            color.withValues(alpha: 0.45),
            AppTheme.accent.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.landscape_outlined, color: Colors.white70, size: 36),
      ),
    );
  }
}
