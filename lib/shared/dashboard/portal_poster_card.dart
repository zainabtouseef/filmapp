import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/cine_marketplace_card.dart' show CineTonePlate;

/// A large backdrop-art card for a portal's own primary work items — a
/// project, booking, property listing, or campaign. Used inside a
/// horizontal [PortalPosterCarousel].
class PortalPosterCard extends StatelessWidget {
  final String title;
  final String meta;
  final String statusLabel;
  final Color statusColor;
  final String tagLabel;
  final String? progressLabel;
  final double? progressValue;
  final String trailingMeta;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onTap;
  final String? imageUrl;
  final String tonePlateKind;
  final String? heroTag;
  final double width;
  final double height;

  const PortalPosterCard({
    super.key,
    required this.title,
    required this.meta,
    required this.statusLabel,
    required this.statusColor,
    required this.tagLabel,
    this.progressLabel,
    this.progressValue,
    required this.trailingMeta,
    required this.primaryLabel,
    this.onPrimary,
    this.onTap,
    this.imageUrl,
    this.tonePlateKind = 'default',
    this.heroTag,
    this.width = 300,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final art = (imageUrl?.trim().isNotEmpty ?? false)
        ? Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => CineTonePlate(kind: tonePlateKind),
          )
        : CineTonePlate(kind: tonePlateKind);
    final media = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: art,
    );
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              heroTag != null ? Hero(tag: heroTag!, child: media) : media,
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    _Chip(
                      dotColor: statusColor,
                      label: statusLabel,
                      background: Colors.white.withValues(alpha: 0.85),
                      foreground: Colors.black87,
                    ),
                    const Spacer(),
                    _Chip(
                      label: tagLabel,
                      background: colors.goldMid,
                      foreground: colors.onGold,
                      bold: true,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    if (progressLabel != null && progressValue != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            progressLabel!,
                            style: AppTextStyles.micro.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 10.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(progressValue!.clamp(0, 1) * 100).round()}%',
                            style: AppTextStyles.micro.copyWith(
                              color: colors.goldLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progressValue!.clamp(0, 1),
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor:
                              AlwaysStoppedAnimation(colors.goldLight),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trailingMeta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                primaryLabel,
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.arrow_outward_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A horizontal scroller of [PortalPosterCard]s plus a trailing "create
/// new" dashed placeholder card.
class PortalPosterCarousel extends StatelessWidget {
  final List<PortalPosterCard> cards;
  final String? createLabel;
  final VoidCallback? onCreate;
  final double height;

  const PortalPosterCarousel({
    super.key,
    required this.cards,
    this.createLabel,
    this.onCreate,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (cards.isEmpty && createLabel == null) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final card in cards) ...[
            card,
            const SizedBox(width: 14),
          ],
          if (createLabel != null)
            SizedBox(
              width: 170,
              height: height,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: onCreate,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colors.goldMid.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: colors.goldSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add_rounded,
                              color: colors.goldDark, size: 22),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          createLabel!,
                          style: AppTextStyles.smallMeta.copyWith(
                            color: colors.goldDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color? dotColor;
  final bool bold;

  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
    this.dotColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.micro.copyWith(
              color: foreground,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
