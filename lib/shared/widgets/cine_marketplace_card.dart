import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/cine_card_system.dart';

/// Shared, image-led marketplace presentation used by buyer portals.
///
/// The card accepts display-ready values from the API models. It deliberately
/// owns no demo records or placeholder business copy, so every portal keeps the
/// same live database source while sharing one visual hierarchy.
///
/// Presented as a single cinematic list row — thumbnail, name, meta, chevron —
/// so the whole row opens the live profile, matching the marketplace flow
/// across every portal that reuses this widget.
class CineMarketplaceCard extends StatefulWidget {
  final String title;
  final String kind;
  final String category;
  final String subtitle;
  final String summary;
  final String city;
  final String rateLabel;
  final String pricingMode;
  final bool allowsBargaining;
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

  /// Stable identity shared with the destination profile route so its hero
  /// image can morph out of this thumbnail. Leave null to skip the
  /// shared-element transition (e.g. when the same id could render twice
  /// on screen at once).
  final String? heroTag;

  const CineMarketplaceCard({
    super.key,
    required this.title,
    required this.kind,
    required this.category,
    required this.subtitle,
    required this.summary,
    required this.city,
    required this.rateLabel,
    this.pricingMode = 'negotiable',
    this.allowsBargaining = true,
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
    this.heroTag,
  });

  @override
  State<CineMarketplaceCard> createState() => _CineMarketplaceCardState();
}

class _CineMarketplaceCardState extends State<CineMarketplaceCard> {
  bool _shortlisted = false;
  bool _savingShortlist = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = cineMarketplaceKindColor(context, widget.kind);
    final verified = const {'approved', 'verified', 'published', 'active'}
        .contains(widget.verificationStatus.toLowerCase());
    final thumbSize = widget.featured ? 116.0 : 96.0;

    return CardShell(
      variant: CardVariant.media,
      padding: EdgeInsets.zero,
      radius: AppRadius.xl,
      selected: _shortlisted,
      tone: cineToneFromColor(context, accent),
      semanticLabel: '${widget.title}, ${widget.category}',
      onTap: widget.busy ? null : widget.onProfile,
      child: Padding(
        padding: EdgeInsets.all(widget.featured ? 16 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MarketplaceThumb(
                  imageUrl: widget.imageUrl,
                  kind: widget.kind,
                  accent: accent,
                  size: thumbSize,
                  heroTag: widget.heroTag,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(top: 4, right: 7),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.available
                                  ? colors.success
                                  : colors.warning,
                            ),
                          ),
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
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          if (widget.onShortlist != null)
                            _ShortlistButton(
                              active: _shortlisted,
                              accent: accent,
                              busy: widget.busy || _savingShortlist,
                              onTap: _toggleShortlist,
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.title,
                        maxLines: widget.featured ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: colors.textPrimary,
                          fontSize: widget.featured ? 22 : 18,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.summary.trim().isEmpty
                            ? 'Open the live profile for availability and production details.'
                            : widget.summary,
                        maxLines: widget.featured ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.smallMeta.copyWith(
                          color: colors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.iconMuted,
                    size: 22,
                  ),
                ),
              ],
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
                CineStatusBadge(
                  label: switch (widget.pricingMode) {
                    'fixed' => 'Fixed price',
                    'on_request' => 'Bargain privately',
                    _ => 'Offers welcome',
                  },
                  tone: widget.allowsBargaining
                      ? CineTone.information
                      : CineTone.neutral,
                  icon: widget.allowsBargaining
                      ? Icons.handshake_outlined
                      : Icons.lock_outline_rounded,
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
              const SizedBox(height: 8),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.busy ? null : widget.onProfile,
                    icon: const Icon(Icons.person_search_outlined, size: 16),
                    label: const Text(
                      'View profile',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.busy ? null : widget.onRequest,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      widget.allowsBargaining
                          ? 'Make offer'
                          : 'Request at price',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

class _ShortlistButton extends StatelessWidget {
  final bool active;
  final bool busy;
  final Color accent;
  final VoidCallback onTap;

  const _ShortlistButton({
    required this.active,
    required this.busy,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // A plain GestureDetector nested inside the card's own InkWell-driven
    // onTap would fight it for the same tap gesture. IconButton's InkResponse
    // is the pattern Material itself uses for a tile's onTap + trailing
    // action (see ListTile) and resolves that nesting correctly.
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        tooltip: active ? 'Remove from shortlist' : 'Add to shortlist',
        onPressed: busy ? null : onTap,
        icon: AnimatedScale(
          scale: active ? 1.1 : 1.0,
          duration: AppDurations.press,
          curve: AppDurations.standardCurve,
          child: Icon(
            active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 19,
            color: active ? accent : colors.iconMuted,
          ),
        ),
      ),
    );
  }
}

/// Lays out marketplace result cards as one continuous cinematic list, with
/// each row cascading into place the way the marketplace list builds in.
class CineMarketplaceResults extends StatefulWidget {
  final List<Widget> cards;

  const CineMarketplaceResults({super.key, required this.cards});

  @override
  State<CineMarketplaceResults> createState() =>
      _CineMarketplaceResultsState();
}

class _CineMarketplaceResultsState extends State<CineMarketplaceResults>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget.cards.length),
    )..forward();
  }

  // Deliberately no didUpdateWidget restart: the caller rebuilds this widget
  // with a freshly-mapped `cards` list on every keystroke while searching
  // (new List instance each time, even when the matched set is unchanged),
  // so restarting on any list-identity change would replay the stagger on
  // every character typed. A category switch already gets a fresh entrance
  // for free — it recreates this State via the FutureBuilder's loading ->
  // data swap — so a single play-once-on-mount animation covers both cases
  // without fighting search input.

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static Duration _durationFor(int count) =>
      Duration(milliseconds: 320 + count.clamp(0, 8) * 70);

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    if (cards.isEmpty) return const SizedBox.shrink();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final count = cards.length.clamp(1, 8);
    return Column(
      children: [
        for (var index = 0; index < cards.length; index++) ...[
          if (reduceMotion)
            cards[index]
          else
            _RevealRow(
              controller: _controller,
              start: (index / count) * 0.6,
              child: cards[index],
            ),
          if (index != cards.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _RevealRow extends StatelessWidget {
  final AnimationController controller;
  final double start;
  final Widget child;

  const _RevealRow({
    required this.controller,
    required this.start,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start.clamp(0.0, 1.0),
        (start + 0.45).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 18),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _MarketplaceThumb extends StatelessWidget {
  final String? imageUrl;
  final String kind;
  final Color accent;
  final double size;
  final String? heroTag;

  const _MarketplaceThumb({
    required this.imageUrl,
    required this.kind,
    required this.accent,
    required this.size,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final source = imageUrl?.trim() ?? '';
    final visual = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl - 3),
      child: SizedBox(
        width: size,
        height: size,
        child: source.isEmpty
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
              ),
      ),
    );
    final framed = Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.border),
      ),
      child: visual,
    );
    final tag = heroTag;
    if (tag == null) return framed;
    return Hero(tag: tag, child: framed);
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
