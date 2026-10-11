import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/cine_marketplace_card.dart' show CineTonePlate;

/// A small backdrop-art card previewing one real marketplace
/// listing/candidate — used inside a horizontal Discover preview
/// carousel on a portal's home dashboard.
class PortalDiscoverCard extends StatelessWidget {
  final String name;
  final String role;
  final String categoryLabel;
  final String? ratingLabel;
  final bool verified;
  final VoidCallback? onView;
  final VoidCallback? onTap;
  final String? imageUrl;
  final String tonePlateKind;
  final double width;
  final double height;

  const PortalDiscoverCard({
    super.key,
    required this.name,
    required this.role,
    required this.categoryLabel,
    this.ratingLabel,
    this.verified = false,
    this.onView,
    this.onTap,
    this.imageUrl,
    this.tonePlateKind = 'default',
    this.width = 168,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final art = (imageUrl?.trim().isNotEmpty ?? false)
        ? Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => CineTonePlate(kind: tonePlateKind),
          )
        : CineTonePlate(kind: tonePlateKind);
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(20), child: art),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    _SmallChip(label: categoryLabel),
                    const Spacer(),
                    if (ratingLabel != null)
                      _SmallChip(
                        label: ratingLabel!,
                        icon: Icons.star_rounded,
                        iconColor: colors.goldMid,
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle.copyWith(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified_rounded,
                              size: 13, color: colors.goldLight),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.micro.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: OutlinedButton(
                        onPressed: onView,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          padding: EdgeInsets.zero,
                          textStyle: AppTextStyles.micro.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        child: const Text('View'),
                      ),
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

/// A horizontal scroller of [PortalDiscoverCard]s.
class PortalDiscoverCarousel extends StatelessWidget {
  final List<PortalDiscoverCard> cards;
  final double height;

  const PortalDiscoverCarousel({
    super.key,
    required this.cards,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final card in cards) ...[card, const SizedBox(width: 12)],
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const _SmallChip({required this.label, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 21,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: iconColor ?? Colors.black87),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.micro.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}
