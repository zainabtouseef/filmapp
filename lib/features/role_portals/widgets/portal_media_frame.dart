import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/role_portal_models.dart';

class PortalMediaFrame extends StatelessWidget {
  final PortalMediaAsset asset;
  final double aspectRatio;
  final String? badge;
  final bool compact;

  const PortalMediaFrame({
    super.key,
    required this.asset,
    this.aspectRatio = 16 / 9,
    this.badge,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 16 : 22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              asset.url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _MediaFallback(asset: asset, loading: true);
              },
              errorBuilder: (_, __, ___) => _MediaFallback(asset: asset),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black
                        .withValues(alpha: colors.isLight ? 0.18 : 0.48),
                  ],
                ),
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(compact ? 16 : 22),
              ),
            ),
            Positioned(
              left: compact ? 8 : 12,
              right: compact ? 8 : 12,
              bottom: compact ? 8 : 12,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      asset.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.statusText.copyWith(
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.goldMid.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        badge!,
                        style: AppTextStyles.micro.copyWith(
                          color: colors.onGold,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaFallback extends StatelessWidget {
  final PortalMediaAsset asset;
  final bool loading;

  const _MediaFallback({
    required this.asset,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        gradient: colors.cardGradient,
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              loading ? Icons.hourglass_top_rounded : asset.fallbackIcon,
              color: colors.goldDark,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              loading ? 'Loading media' : 'Media fallback',
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
