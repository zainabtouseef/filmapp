import 'package:flutter/material.dart';

import '../widgets/cine_marketplace_card.dart';

/// A "Known For" / "Spaces & Sets" work-item tile: a tone-plate image,
/// title, and subtitle — staggered fade-up on entrance, matching the
/// Flow Reel's work section.
class EntityWorkTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String plateKind;
  final String? imageUrl;
  final int index;
  final VoidCallback? onTap;

  const EntityWorkTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.plateKind,
    this.imageUrl,
    this.index = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CineMarketplaceVisuals.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 0.72,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: (imageUrl?.trim().isNotEmpty ?? false)
                  ? Image.network(
                      imageUrl!,
                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          CineTonePlate(kind: plateKind),
                    )
                  : CineTonePlate(kind: plateKind),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette.archivo(
              size: 13,
              weight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette.archivo(size: 11.5, color: palette.muted),
          ),
        ],
      ),
    );
    if (reduceMotion) return content;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index.clamp(0, 6) * 90)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 22),
          child: child,
        ),
      ),
      child: content,
    );
  }
}
