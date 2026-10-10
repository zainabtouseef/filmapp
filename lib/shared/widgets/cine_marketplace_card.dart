import 'package:flutter/foundation.dart';
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
  final VoidCallback? onQuickView;
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
    this.onQuickView,
    this.onRequest,
    this.onShortlist,
  });

  @override
  State<CineMarketplaceCard> createState() => _CineMarketplaceCardState();
}

class _CineMarketplaceCardState extends State<CineMarketplaceCard> {
  bool _shortlisted = false;
  bool _savingShortlist = false;
  bool _hovered = false;
  bool _mobileExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = cineMarketplaceKindColor(context, widget.kind);
    final mobile = MediaQuery.sizeOf(context).width < 700;
    final active = _hovered || _mobileExpanded;
    final verified = const {'approved', 'verified', 'published', 'active'}
        .contains(widget.verificationStatus.toLowerCase());
    final source = widget.imageUrl?.trim() ?? '';

    Widget art = _MarketplaceFallback(kind: widget.kind, accent: accent);
    if (source.isNotEmpty) {
      art = Stack(
        fit: StackFit.expand,
        children: [
          art,
          Image.network(
            source,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            fit: BoxFit.cover,
            alignment: {'actor', 'model', 'influencer'}.contains(widget.kind)
                ? Alignment.topCenter
                : Alignment.center,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: kIsWeb
            ? null
            : () => setState(() => _mobileExpanded = !_mobileExpanded),
        child: CardShell(
          variant: CardVariant.media,
          padding: EdgeInsets.zero,
          radius: 22,
          selected: _shortlisted,
          tone: cineToneFromColor(context, accent),
          semanticLabel: '${widget.title}, ${widget.category}',
          child: SizedBox(
            height: mobile ? 420 : (widget.featured ? 500 : 470),
            child: Stack(
              fit: StackFit.expand,
              children: [
                art,
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: colors.isLight
                          ? [
                              Colors.black.withValues(alpha: .02),
                              Colors.black.withValues(alpha: .08),
                              Colors.black.withValues(alpha: .72),
                              Colors.black.withValues(alpha: .93),
                            ]
                          : [
                              Colors.black.withValues(alpha: .04),
                              Colors.black.withValues(alpha: .16),
                              Colors.black.withValues(alpha: .72),
                              Colors.black.withValues(alpha: .95),
                            ],
                      stops: const [0, .42, .72, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          CineStatusBadge(
                            label: widget.rating > 0
                                ? widget.rating.toStringAsFixed(1)
                                : widget.category,
                            tone: CineTone.premium,
                            icon: widget.rating > 0
                                ? Icons.star_rounded
                                : cineMarketplaceKindIcon(widget.kind),
                            showDot: false,
                          ),
                          if (verified)
                            const CineStatusBadge(
                              label: 'Verified',
                              tone: CineTone.positive,
                              icon: Icons.verified_rounded,
                              showDot: false,
                            ),
                        ],
                      ),
                      const Spacer(),
                      if (widget.onShortlist != null)
                        Material(
                          color: Colors.black.withValues(alpha: .28),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: _shortlisted
                                ? 'Remove from shortlist'
                                : 'Add to shortlist',
                            onPressed: widget.busy || _savingShortlist
                                ? null
                                : _toggleShortlist,
                            icon: Icon(
                              _shortlisted
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: _shortlisted ? colors.goldLight : Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.available ? colors.success : colors.warning,
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.available ? colors.success : colors.warning)
                                      .withValues(alpha: .65),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.available ? 'AVAILABLE' : 'CHECK AVAILABILITY',
                              style: AppTextStyles.micro.copyWith(
                                color: widget.available
                                    ? const Color(0xFFA8E0C0)
                                    : const Color(0xFFE8D08E),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          Text(
                            widget.rateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.smallMeta.copyWith(
                              color: colors.goldLight,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: Colors.white,
                          fontFamily: 'Georgia',
                          fontSize: mobile ? 21 : (widget.featured ? 27 : 23),
                          fontWeight: FontWeight.w700,
                          height: 1.04,
                          shadows: const [Shadow(color: Colors.black, blurRadius: 10)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle.trim().isEmpty
                            ? widget.category
                            : widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.smallMeta.copyWith(
                          color: Colors.white.withValues(alpha: .76),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: Colors.white.withValues(alpha: .72), size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.smallMeta.copyWith(
                                color: Colors.white.withValues(alpha: .78),
                              ),
                            ),
                          ),
                          if (widget.trustScore != null)
                            Text(
                              'Trust ${widget.trustScore}',
                              style: AppTextStyles.smallMeta.copyWith(
                                color: Colors.white.withValues(alpha: .78),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 380),
                        curve: const Cubic(.2, .9, .25, 1),
                        height: active ? 44 : 0,
                        margin: EdgeInsets.only(top: active ? 10 : 0),
                        child: AnimatedOpacity(
                          opacity: active ? 1 : 0,
                          duration: const Duration(milliseconds: 260),
                          child: Row(
                            children: [
                              if (widget.onQuickView != null) ...[
                                SizedBox(
                                  width: 40,
                                  child: OutlinedButton(
                                    onPressed: widget.busy ? null : widget.onQuickView,
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      foregroundColor: Colors.white,
                                      side: BorderSide(color: Colors.white.withValues(alpha: .35)),
                                      backgroundColor: Colors.black.withValues(alpha: .22),
                                    ),
                                    child: const Icon(Icons.visibility_outlined, size: 17),
                                  ),
                                ),
                                const SizedBox(width: 7),
                              ],
                              if (widget.onProfile != null)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: widget.busy ? null : widget.onProfile,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(color: Colors.white.withValues(alpha: .35)),
                                      backgroundColor: Colors.black.withValues(alpha: .22),
                                    ),
                                    child: const Text('Profile'),
                                  ),
                                ),
                              if (widget.onProfile != null && widget.onRequest != null)
                                const SizedBox(width: 7),
                              if (widget.onRequest != null)
                                Expanded(
                                  child: FilledButton(
                                    onPressed: widget.busy ? null : widget.onRequest,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colors.goldMid,
                                      foregroundColor: colors.onGold,
                                    ),
                                    child: const Text('Request'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
              if (widget.onQuickView != null)
                OutlinedButton.icon(
                  onPressed: widget.busy ? null : widget.onQuickView,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Quick view'),
                ),
              OutlinedButton.icon(
                onPressed: widget.busy ? null : widget.onProfile,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Full profile'),
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
        final width = constraints.maxWidth;
        final columns = width >= 1320
            ? 4
            : width >= 940
                ? 3
                : width >= 620
                    ? 2
                    : 1;
        const gap = 14.0;
        final cardWidth = (width - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: 18,
          children: [
            for (final card in cards)
              SizedBox(width: cardWidth, child: card),
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
