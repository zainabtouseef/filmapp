import 'package:flutter/material.dart';

import '../../core/theme/app_durations.dart';
import 'cine_marketplace_card.dart';

/// A shared, image-led presentation for actor and model profiles.
///
/// The same visual language is used in buyer-facing marketplace views and in
/// the actor/model profile builders, so talent does not look less compelling
/// when it is opened from a different portal.
class TalentProfileShowcase extends StatelessWidget {
  final String name;
  final String role;
  final String city;
  final String summary;
  final String? portraitUrl;
  final String? coverUrl;
  final bool verified;
  final bool available;
  final String rateLabel;
  final double? rating;
  final int? reviewCount;
  final List<String> highlights;
  final List<Widget> actions;
  final String badge;

  /// Stable identity shared with the marketplace card this profile was
  /// opened from, so the thumbnail morphs into this hero image.
  final String? heroTag;

  const TalentProfileShowcase({
    super.key,
    required this.name,
    required this.role,
    required this.city,
    required this.summary,
    this.portraitUrl,
    this.coverUrl,
    this.verified = false,
    this.available = true,
    this.rateLabel = 'Rate on request',
    this.rating,
    this.reviewCount,
    this.highlights = const [],
    this.actions = const [],
    this.badge = 'CineConnect profile',
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final heroHeight = compact ? 520.0 : 430.0;
        final imageUrl =
            coverUrl?.trim().isNotEmpty == true ? coverUrl : portraitUrl;
        final heroImage = _ShowcaseImage(
          imageUrl: imageUrl,
          fallbackLabel: _initials(name),
          alignment: Alignment.topCenter,
        );

        return TweenAnimationBuilder<double>(
          key: const ValueKey('talent-profile-showcase'),
          tween: Tween(begin: 0, end: 1),
          duration: AppDurations.pageEntrance,
          curve: Curves.easeOutCubic,
          builder: (context, reveal, child) => Opacity(
            opacity: reveal,
            child: Transform.translate(
              offset: Offset(0, (1 - reveal) * 20),
              child: child,
            ),
          ),
          child: Container(
            height: heroHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: CineMarketplaceVisuals.surface,
              borderRadius: BorderRadius.circular(compact ? 22 : 28),
              border: Border.all(color: CineMarketplaceVisuals.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.36),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                heroTag == null
                    ? heroImage
                    : Hero(tag: heroTag!, child: heroImage),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x12000000),
                        Color(0x3D000000),
                        Color(0xEF09090A),
                      ],
                      stops: [0.0, 0.44, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: compact ? 16 : 20,
                  left: compact ? 16 : 22,
                  right: compact ? 16 : 22,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: _ShowcasePill(
                          icon: Icons.auto_awesome_rounded,
                          label: badge,
                          emphasized: true,
                        ),
                      ),
                      const Spacer(),
                      if (verified)
                        const _ShowcasePill(
                          icon: Icons.verified_rounded,
                          label: 'Identity verified',
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: compact ? 20 : 30,
                  right: compact ? 20 : 30,
                  bottom: compact ? 20 : 26,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          role.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CineMarketplaceVisuals.archivo(
                            size: compact ? 10.5 : 12,
                            weight: FontWeight.w700,
                            color: CineMarketplaceVisuals.goldLight,
                            letterSpacing: 2.8,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                name.trim().isEmpty
                                    ? 'Your professional name'
                                    : name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: CineMarketplaceVisuals.archivo(
                                  size: compact ? 35 : 48,
                                  weight: FontWeight.w800,
                                  height: 0.98,
                                  letterSpacing: -1.5,
                                ),
                              ),
                            ),
                            if (verified) ...[
                              const SizedBox(width: 9),
                              Icon(
                                Icons.verified_rounded,
                                color: CineMarketplaceVisuals.gold,
                                size: compact ? 20 : 24,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          summary.trim().isEmpty
                              ? 'Add a memorable positioning statement that tells buyers what makes this profile right for their production.'
                              : summary,
                          maxLines: compact ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: CineMarketplaceVisuals.archivo(
                            size: compact ? 12.5 : 14,
                            color: CineMarketplaceVisuals.secondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            _ShowcasePill(
                              icon: Icons.location_on_outlined,
                              label:
                                  city.trim().isEmpty ? 'City not set' : city,
                            ),
                            _ShowcasePill(
                              icon: available
                                  ? Icons.event_available_rounded
                                  : Icons.event_busy_outlined,
                              label: available
                                  ? 'Available for bookings'
                                  : 'Limited availability',
                            ),
                            _ShowcasePill(
                              icon: Icons.payments_outlined,
                              label: rateLabel,
                            ),
                            if (rating != null && rating! > 0)
                              _ShowcasePill(
                                icon: Icons.star_rounded,
                                label:
                                    '${rating!.toStringAsFixed(1)}${reviewCount == null ? '' : ' · $reviewCount reviews'}',
                              ),
                            for (final highlight
                                in highlights.take(compact ? 2 : 4))
                              _ShowcasePill(
                                icon: Icons.check_circle_outline_rounded,
                                label: highlight,
                              ),
                          ],
                        ),
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(spacing: 8, runSpacing: 8, children: actions),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TalentProfileGallery extends StatelessWidget {
  final List<TalentProfileGalleryItem> items;
  final ValueChanged<TalentProfileGalleryItem>? onOpen;
  final String title;

  const TalentProfileGallery({
    super.key,
    required this.items,
    this.onOpen,
    this.title = 'Selected portfolio',
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final videoCount = items.where((item) => item.isVideo).length;
    final kindLabel = videoCount == items.length
        ? '${items.length} ${items.length == 1 ? 'video' : 'videos'}'
        : videoCount == 0
            ? '${items.length} ${items.length == 1 ? 'photo' : 'photos'}'
            : '${items.length} items';

    void openViewer(int index) {
      TalentGalleryViewer.open(
        context,
        title: title,
        countLabel: kindLabel,
        items: items,
        initialIndex: index,
        onOpenOriginal: onOpen,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: CineMarketplaceVisuals.archivo(
                  size: 12,
                  weight: FontWeight.w700,
                  color: CineMarketplaceVisuals.gold,
                  letterSpacing: 3,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => openViewer(0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'More',
                      style: CineMarketplaceVisuals.archivo(
                        size: 11,
                        color: CineMarketplaceVisuals.gold,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: CineMarketplaceVisuals.gold,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Open a frame to review the work at full size.',
          style: CineMarketplaceVisuals.archivo(
            size: 12,
            color: CineMarketplaceVisuals.muted,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 278,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _GalleryStripTile(
                item: item,
                heroTag: 'gallery-item-$title-$index',
                onTap: () => openViewer(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GalleryStripTile extends StatelessWidget {
  final TalentProfileGalleryItem item;
  final String heroTag;
  final VoidCallback onTap;

  const _GalleryStripTile({
    required this.item,
    required this.heroTag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 210,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: CineMarketplaceVisuals.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CineMarketplaceVisuals.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: heroTag,
              child: _ShowcaseImage(
                imageUrl: item.imageUrl,
                fallbackLabel: 'CC',
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xD9000000)],
                ),
              ),
            ),
            if (item.isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Text(
                item.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CineMarketplaceVisuals.archivo(
                  size: 12,
                  color: CineMarketplaceVisuals.ink,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-bleed masonry gallery the media strip opens into — the same
/// "strip thumbnails resolve into the full gallery" motion as the rest of
/// the marketplace flow, continued here via matching Hero tags.
class TalentGalleryViewer extends StatelessWidget {
  final String title;
  final String countLabel;
  final List<TalentProfileGalleryItem> items;
  final int initialIndex;
  final ValueChanged<TalentProfileGalleryItem>? onOpenOriginal;

  const TalentGalleryViewer({
    super.key,
    required this.title,
    required this.countLabel,
    required this.items,
    this.initialIndex = 0,
    this.onOpenOriginal,
  });

  static Future<void> open(
    BuildContext context, {
    required String title,
    required String countLabel,
    required List<TalentProfileGalleryItem> items,
    int initialIndex = 0,
    ValueChanged<TalentProfileGalleryItem>? onOpenOriginal,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: AppDurations.pageEntrance,
        reverseTransitionDuration: AppDurations.pageEntrance,
        pageBuilder: (context, animation, secondaryAnimation) =>
            TalentGalleryViewer(
          title: title,
          countLabel: countLabel,
          items: items,
          initialIndex: initialIndex,
          onOpenOriginal: onOpenOriginal,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppDurations.standardCurve,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 0.97, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CineMarketplaceVisuals.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: CineMarketplaceVisuals.ink,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CineMarketplaceVisuals.archivo(
                            size: 20,
                            weight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          countLabel.toUpperCase(),
                          style: CineMarketplaceVisuals.archivo(
                            size: 9.5,
                            color: CineMarketplaceVisuals.gold,
                            letterSpacing: 3,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _GalleryMasonry(
                items: items,
                title: title,
                onOpenOriginal: onOpenOriginal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryMasonry extends StatelessWidget {
  final List<TalentProfileGalleryItem> items;
  final String title;
  final ValueChanged<TalentProfileGalleryItem>? onOpenOriginal;

  const _GalleryMasonry({
    required this.items,
    required this.title,
    required this.onOpenOriginal,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
                ? 2
                : 2;
        final columnHeights = List<double>.filled(columns, 0);
        final columnItems = List.generate(columns, (_) => <int>[]);
        for (var index = 0; index < items.length; index++) {
          final ratio = const [1.15, 0.85, 1.0, 0.72][index % 4];
          final shortest = columnHeights.indexOf(
            columnHeights.reduce((a, b) => a < b ? a : b),
          );
          columnItems[shortest].add(index);
          columnHeights[shortest] += ratio;
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < columns; column++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: [
                        for (final index in columnItems[column])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _GalleryTile(
                              item: items[index],
                              heroTag: 'gallery-item-$title-$index',
                              aspectRatio: const [
                                1.15,
                                0.85,
                                1.0,
                                0.72
                              ][index % 4],
                              delay: index,
                              onOpenOriginal: onOpenOriginal,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final TalentProfileGalleryItem item;
  final String heroTag;
  final double aspectRatio;
  final int delay;
  final ValueChanged<TalentProfileGalleryItem>? onOpenOriginal;

  const _GalleryTile({
    required this.item,
    required this.heroTag,
    required this.aspectRatio,
    required this.delay,
    required this.onOpenOriginal,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final tile = AspectRatio(
      aspectRatio: aspectRatio,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenOriginal == null ? null : () => onOpenOriginal!(item),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CineMarketplaceVisuals.border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: heroTag,
                child: _ShowcaseImage(
                    imageUrl: item.imageUrl, fallbackLabel: 'CC'),
              ),
              if (item.isVideo) ...[
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB3000000)],
                      stops: [0.55, 1.0],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.4),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
              ],
              if (item.label.trim().isNotEmpty)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CineMarketplaceVisuals.archivo(
                      size: 11,
                      color: CineMarketplaceVisuals.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (reduceMotion) return tile;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (delay.clamp(0, 10) * 55)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(scale: 0.92 + (0.08 * value), child: child),
      ),
      child: tile,
    );
  }
}

class TalentProfileGalleryItem {
  final String label;
  final String? imageUrl;
  final bool isVideo;
  final Object? value;

  const TalentProfileGalleryItem({
    required this.label,
    required this.imageUrl,
    this.isVideo = false,
    this.value,
  });
}

class _ShowcaseImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackLabel;
  final Alignment alignment;

  const _ShowcaseImage({
    required this.imageUrl,
    required this.fallbackLabel,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.6),
          radius: 1.1,
          colors: const [
            Color(0xFF44392A),
            CineMarketplaceVisuals.background,
          ],
        ),
      ),
      child: Center(
        child: Text(
          fallbackLabel,
          style: CineMarketplaceVisuals.archivo(
            size: 58,
            weight: FontWeight.w800,
            color: CineMarketplaceVisuals.ink.withValues(alpha: 0.86),
          ),
        ),
      ),
    );
    if (url == null || url.trim().isEmpty) return fallback;
    return Image.network(
      url,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      fit: BoxFit.cover,
      alignment: alignment,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _ShowcasePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasized;

  const _ShowcasePill({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        gradient: emphasized
            ? const LinearGradient(
                colors: [
                  CineMarketplaceVisuals.gold,
                  CineMarketplaceVisuals.goldLight,
                ],
              )
            : null,
        color: emphasized ? null : Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized
              ? CineMarketplaceVisuals.goldLight
              : Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: emphasized
                ? const Color(0xFF17130A)
                : CineMarketplaceVisuals.ink,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CineMarketplaceVisuals.archivo(
                size: 11,
                color: emphasized
                    ? const Color(0xFF17130A)
                    : CineMarketplaceVisuals.ink,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2);
  final initials = words.map((part) => part[0].toUpperCase()).join();
  return initials.isEmpty ? 'CC' : initials;
}
