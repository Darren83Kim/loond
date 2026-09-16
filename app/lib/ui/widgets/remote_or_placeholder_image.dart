import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Network image with colored gradient placeholder on missing/error URL.
class RemoteOrPlaceholderImage extends StatelessWidget {
  const RemoteOrPlaceholderImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.seedColor,
  });

  final String? url;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Color? seedColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppTheme.cardRadius);
    final placeholder = _Placeholder(
      color: seedColor ?? AppTheme.seed,
      height: height,
      width: width,
    );

    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) {
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
