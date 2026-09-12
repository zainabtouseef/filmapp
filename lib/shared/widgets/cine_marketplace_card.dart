import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/cine_card_system.dart';

/// Shared, image-led marketplace presentation used by buyer portals.
///
/// The card accepts display-ready values from the API models. It deliberately
/// owns no demo records or placeholder business copy, so every portal keeps the
/// same live database source while sharing one visual hierarchy.
class CineMarketplaceCard extends StatefulWidget {
  final String title;
  final String kind;
  final String category;
  final String subtitle;
  final String summary;
  final String city;
  final String rateLabel;
  final String verificationStatus;
  final String? imageUrl;
  final List<String> tags;
  final bool available;
  final double rating;
  final int? trustScore;
  final bool busy;
  final bool featured;
  final VoidCallback? onProfile;
  final VoidCallback? onRequest;
  final Future<bool> Function()? onShortlist;

  const CineMarketplaceCard({
    super.key,
    required this.title,
    required this.kind,
    required this.category,
    required this.subtitle,
    required this.summary,
    required this.city,
    required this.rateLabel,
    required this.verificationStatus,
    required this.imageUrl,
    required this.tags,
    required this.available,
    required this.rating,
    required this.trustScore,
    required this.busy,
    required this.featured,
    this.onProfile,
    this.onRequest,
    this.onShortlist,
  });

  @override
  State<CineMarketplaceCard> createState() => _CineMarketplaceCardState();
}

class _CineMarketplaceCardState extends State<CineMarketplaceCard> {
  bool _shortlisted = false;
  bool _savingShortlist = false;

  @override
  Widget build(BuildContext context) {
    final accent = cineMarketplaceKindColor(context, widget.kind);
    return CardShell(
      variant: CardVariant.media,
      padding: EdgeInsets.zero,
      radius: 26,
      selected: _shortlisted,
      tone: cineToneFromColor(context, accent),
      semanticLabel: '${widget.title}, ${widget.category}',
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth >= 720;
                if (!horizontal) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MarketplaceVisual(
                        imageUrl: widget.imageUrl,
                        title: widget.title,
                        kind: widget.kind,
                        category: widget.category,
                        status: widget.verificationStatus,
                        featured: false,
                      ),
                      _body(context, accent, compact: true),
                    ],
                  );
                }
                return SizedBox(
                  height: widget.featured ? 400 : 370,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: widget.featured ? 11 : 9,
                        child: _MarketplaceVisual(
                          imageUrl: widget.imageUrl,
                          title: widget.title,
                          kind: widget.kind,
                          category: widget.category,
                          status: widget.verificationStatus,
                          featured: widget.featured,
                        ),
                      ),
                      Expanded(
                        flex: widget.featured ? 10 : 11,
                        child: _body(context, accent, compact: false),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, Color accent, {required bool compact}) {
    final colors = context.appColors;
    final verified = const {'approved', 'verified', 'published', 'active'}
        .contains(widget.verificationStatus.toLowerCase());
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 20,
        compact ? 15 : 20,
        compact ? 16 : 20,
        compact ? 17 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: widget.available ? colors.success : colors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.subtitle.trim().isEmpty
                      ? widget.category
                      : widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.micro.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              if (widget.onShortlist != null)
                IconButton(
                  tooltip: _shortlisted
                      ? 'Remove from shortlist'
                      : 'Add to shortlist',
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      widget.busy || _savingShortlist ? null : _toggleShortlist,
                  icon: Icon(
                    _shortlisted
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _shortlisted ? accent : colors.iconMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            widget.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardTitle.copyWith(
              color: colors.textPrimary,
              fontSize: widget.featured && !compact ? 24 : 19,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.summary.trim().isEmpty
                ? 'Open the live profile for availability and production details.'
                : widget.summary,
            maxLines: widget.featured && !compact ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              CineStatusBadge(
                label: verified ? 'Verified' : widget.verificationStatus,
                tone: verified ? CineTone.positive : CineTone.warning,
                icon:
                    verified ? Icons.verified_rounded : Icons.schedule_rounded,
                showDot: false,
              ),
              CineStatusBadge(
                label: widget.city,
                tone: CineTone.neutral,
                icon: Icons.location_on_outlined,
                showDot: false,
              ),
              CineStatusBadge(
                label: widget.rateLabel,
                tone: CineTone.premium,
                icon: Icons.payments_outlined,
                showDot: false,
              ),
              if (widget.trustScore != null)
                CineStatusBadge(
                  label: 'Trust ${widget.trustScore}/100',
                  tone: CineTone.information,
                  icon: Icons.shield_outlined,
                  showDot: false,
                )
              else if (widget.rating > 0)
                CineStatusBadge(
                  label: widget.rating.toStringAsFixed(1),
                  tone: CineTone.premium,
                  icon: Icons.star_rounded,
                  showDot: false,
                ),
            ],
          ),
          if (widget.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.tags.take(widget.featured ? 5 : 3).join('  ·  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (compact) const SizedBox(height: 14) else const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: widget.busy ? null : widget.onProfile,
                icon: const Icon(Icons.person_search_outlined, size: 18),
                label: const Text('View profile'),
              ),
              FilledButton.icon(
                onPressed: widget.busy ? null : widget.onRequest,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Request'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleShortlist() async {
    if (_shortlisted) {
      setState(() => _shortlisted = false);
      return;
    }
    final action = widget.onShortlist;
    if (action == null) return;
    setState(() => _savingShortlist = true);
    final saved = await action();
    if (!mounted) return;
    setState(() {
      _savingShortlist = false;
      _shortlisted = saved;
    });
  }
}

class CineMarketplaceResults extends StatelessWidget {
  final List<Widget> cards;

  const CineMarketplaceResults({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860 || cards.length == 1) {
          return Column(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                cards[index],
                if (index != cards.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }
        final supporting = cards.skip(1).toList();
        final gap = 14.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cards.first,
            if (supporting.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final card in supporting)
                    SizedBox(width: width, child: card),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MarketplaceVisual extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String kind;
  final String category;
  final String status;
  final bool featured;

  const _MarketplaceVisual({
    required this.imageUrl,
    required this.title,
    required this.kind,
    required this.category,
    required this.status,
    required this.featured,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = cineMarketplaceKindColor(context, kind);
    final source = imageUrl?.trim() ?? '';
    final visual = source.isEmpty
        ? _MarketplaceFallback(kind: kind, accent: accent)
        : Stack(
            fit: StackFit.expand,
            children: [
              _MarketplaceFallback(kind: kind, accent: accent),
              Image.network(
                source,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                fit: BoxFit.cover,
                alignment: {'actor', 'model', 'influencer'}.contains(kind)
                    ? Alignment.topCenter
                    : Alignment.center,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ],
          );
    return AspectRatio(
      aspectRatio: featured ? 16 / 10 : 16 / 9,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(21),
          bottomLeft: Radius.circular(21),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            visual,
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x08000000), Color(0xA6000000)],
                  stops: [0.38, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: CineStatusBadge(
                label: category,
                colorOverride: accent,
                icon: cineMarketplaceKindIcon(kind),
                showDot: false,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status.toUpperCase(),
                    style: AppTextStyles.micro.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: Colors.white,
                      fontSize: featured ? 23 : 18,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 8)
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.border),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceFallback extends StatelessWidget {
  final String kind;
  final Color accent;

  const _MarketplaceFallback({required this.kind, required this.accent});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(colors.surface, accent, colors.isLight ? 0.12 : 0.22)!,
            colors.softSurface,
            Color.lerp(colors.surface, accent, colors.isLight ? 0.24 : 0.34)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -30,
            child: Icon(
              cineMarketplaceKindIcon(kind),
              size: 190,
              color: accent.withValues(alpha: 0.10),
            ),
          ),
          Center(
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: colors.elevatedSurface.withValues(alpha: 0.72),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.35)),
              ),
              child: Icon(
                cineMarketplaceKindIcon(kind),
                color: accent,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData cineMarketplaceKindIcon(String kind) {
  return switch (kind.toLowerCase()) {
    'actor' => Icons.theater_comedy_outlined,
    'model' => Icons.accessibility_new_outlined,
    'influencer' => Icons.campaign_outlined,
    'crew' => Icons.groups_outlined,
    'location' => Icons.location_on_outlined,
    'equipment' => Icons.videocam_outlined,
    'agency' => Icons.badge_outlined,
    'distribution' => Icons.movie_filter_outlined,
    _ => Icons.storefront_outlined,
  };
}

Color cineMarketplaceKindColor(BuildContext context, String kind) {
  final colors = context.appColors;
  return switch (kind.toLowerCase()) {
    'actor' => colors.success,
    'model' => colors.infoPurple,
    'influencer' => colors.goldDark,
    'crew' => colors.infoBlue,
    'location' => colors.success,
    'equipment' => colors.warning,
    'agency' => colors.infoPurple,
    'distribution' => colors.danger,
    _ => colors.goldDark,
  };
}
