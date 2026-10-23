import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_color_scheme.dart';

/// Theme-aware visual tokens derived from the supplied CineConnect Flow Reel.
///
/// The spacing, type scale, gold accents and motion stay consistent while the
/// surfaces and contrast follow the application's active light or dark theme.
class CineMarketplaceVisuals {
  CineMarketplaceVisuals._();

  static CineMarketplacePalette of(BuildContext context) {
    return CineMarketplacePalette(context.appColors);
  }
}

@immutable
class CineMarketplacePalette {
  final CineThemeColors _app;

  const CineMarketplacePalette(this._app);

  bool get isLight => _app.isLight;
  Color get background => _app.background;
  Color get surface => _app.card;
  Color get raisedSurface => _app.elevatedSurface;
  Color get ink => _app.textPrimary;
  Color get secondary => _app.textSecondary;
  Color get muted => _app.textTertiary;
  Color get gold => _app.goldMid;
  Color get goldLight => _app.goldLight;
  Color get border => _app.border;
  Color get onGold => _app.onGold;
  Color get shadow => _app.shadow;

  LinearGradient get goldGradient => _app.goldGradient;

  TextStyle archivo({
    double? size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.archivo(
      fontSize: size,
      fontWeight: weight,
      color: color ?? ink,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

/// Shared, live-data marketplace card for every portal.
///
/// The compact row, image treatment, typography, colors and motion follow the
/// HTML reference. Existing shortlist, profile and booking actions remain
/// available in a restrained action rail under the row.
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
  final bool grid;
  final VoidCallback? onProfile;
  final VoidCallback? onRequest;
  final Future<bool> Function()? onShortlist;
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
    this.grid = false,
    this.onProfile,
    this.onRequest,
    this.onShortlist,
    this.heroTag,
  });

  @override
  State<CineMarketplaceCard> createState() => _CineMarketplaceCardState();
}

class _CineMarketplaceCardState extends State<CineMarketplaceCard> {
  bool _hovered = false;
  bool _pressed = false;
  bool _shortlisted = false;
  bool _savingShortlist = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final imageSize = compact ? 96.0 : 126.0;
        final verified = const {
          'approved',
          'verified',
          'published',
          'active',
        }.contains(widget.verificationStatus.toLowerCase());
        final active = (_hovered || _pressed) && !widget.busy;

        return Semantics(
          button: widget.onProfile != null,
          label:
              '${widget.title}, ${marketplaceCategoryLabel(widget.category)}',
          child: MouseRegion(
            cursor: widget.busy || widget.onProfile == null
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() {
              _hovered = false;
              _pressed = false;
            }),
            child: AnimatedScale(
              scale: _pressed ? 0.994 : (_hovered ? 1.008 : 1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                key: const ValueKey('cine-marketplace-card-surface'),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: CineMarketplaceVisuals.of(context).surface,
                  borderRadius: BorderRadius.circular(compact ? 18 : 26),
                  border: Border.all(
                    color: active || _shortlisted
                        ? CineMarketplaceVisuals.of(context)
                            .gold
                            .withValues(alpha: 0.55)
                        : CineMarketplaceVisuals.of(context).border,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: CineMarketplaceVisuals.of(context)
                                .gold
                                .withValues(alpha: 0.10),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ]
                      : const [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: widget.grid
                      ? _gridContent(context, constraints.maxWidth)
                      : Column(
                          children: [
                            InkWell(
                              onTap: widget.busy ? null : widget.onProfile,
                              onTapDown: widget.busy
                                  ? null
                                  : (_) => setState(() => _pressed = true),
                              onTapCancel: widget.busy
                                  ? null
                                  : () => setState(() => _pressed = false),
                              onTapUp: widget.busy
                                  ? null
                                  : (_) => setState(() => _pressed = false),
                              splashColor: CineMarketplaceVisuals.of(context)
                                  .gold
                                  .withValues(alpha: 0.08),
                              highlightColor: Colors.transparent,
                              child: Padding(
                                padding: EdgeInsets.all(compact ? 10 : 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CineMarketplaceMediaFrame(
                                      imageUrl: widget.imageUrl,
                                      listingTitle: widget.title,
                                      kind: widget.kind,
                                      width: imageSize,
                                      height: imageSize,
                                      radius: compact ? 13 : 19,
                                      heroTag: widget.heroTag,
                                    ),
                                    SizedBox(width: compact ? 13 : 20),
                                    Expanded(
                                      child: _MarketplaceIdentity(
                                        widget: widget,
                                        compact: compact,
                                        verified: verified,
                                      ),
                                    ),
                                    SizedBox(width: compact ? 5 : 12),
                                    Column(
                                      children: [
                                        if (widget.onShortlist != null)
                                          _ShortlistButton(
                                            active: _shortlisted,
                                            busy:
                                                widget.busy || _savingShortlist,
                                            onTap: _toggleShortlist,
                                          )
                                        else
                                          SizedBox(height: compact ? 30 : 36),
                                        SizedBox(height: compact ? 8 : 16),
                                        AnimatedSlide(
                                          offset: Offset(active ? 0.10 : 0, 0),
                                          duration:
                                              const Duration(milliseconds: 180),
                                          curve: Curves.easeOutCubic,
                                          child: Icon(
                                            Icons.chevron_right_rounded,
                                            color: active
                                                ? CineMarketplaceVisuals.of(
                                                        context)
                                                    .gold
                                                : CineMarketplaceVisuals.of(
                                                        context)
                                                    .muted,
                                            size: compact ? 23 : 29,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _MarketplaceActionRail(
                              onProfile: widget.busy ? null : widget.onProfile,
                              onRequest: widget.busy ? null : widget.onRequest,
                              requestLabel: widget.allowsBargaining
                                  ? 'Make offer'
                                  : 'Request at price',
                              compact: compact,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _gridContent(BuildContext context, double width) {
    final palette = CineMarketplaceVisuals.of(context);
    return Column(
      children: [
        InkWell(
          onTap: widget.busy ? null : widget.onProfile,
          child: SizedBox(
            height: 340,
            width: width,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CineMarketplaceMediaFrame(
                  imageUrl: widget.imageUrl,
                  listingTitle: widget.title,
                  kind: widget.kind,
                  width: width,
                  height: 340,
                  radius: 22,
                  heroTag: widget.heroTag,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, .42, 1],
                      colors: [
                        Colors.black.withValues(alpha: .22),
                        Colors.transparent,
                        Colors.black.withValues(alpha: .82),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: _GridBadge(
                      label: marketplaceCategoryLabel(widget.category)),
                ),
                if (widget.rating > 0)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _GridBadge(
                        label: '★ ${widget.rating.toStringAsFixed(1)}'),
                  ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: palette.archivo(
                              size: 24,
                              weight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.08)),
                      const SizedBox(height: 7),
                      Text(
                          [
                            marketplaceCategoryLabel(widget.subtitle),
                            widget.city
                          ].where((part) => part.trim().isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: palette.archivo(
                              size: 12.5,
                              color: Colors.white.withValues(alpha: .88))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(widget.rateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: palette.archivo(
                        size: 12,
                        weight: FontWeight.w600,
                        color: palette.gold)),
              ),
              if (widget.onShortlist != null)
                _ShortlistButton(
                    active: _shortlisted,
                    busy: widget.busy || _savingShortlist,
                    onTap: _toggleShortlist),
            ],
          ),
        ),
        _MarketplaceActionRail(
          onProfile: widget.busy ? null : widget.onProfile,
          onRequest: widget.busy ? null : widget.onRequest,
          requestLabel:
              widget.allowsBargaining ? 'Make offer' : 'Request at price',
          compact: true,
        ),
      ],
    );
  }

  Future<void> _toggleShortlist() async {
    if (_shortlisted) {
      return;
    }
    final action = widget.onShortlist;
    if (action == null) return;
    setState(() => _savingShortlist = true);
    try {
      final saved = await action();
      if (mounted) setState(() => _shortlisted = saved);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingShortlist = false);
    }
  }
}

class _MarketplaceIdentity extends StatelessWidget {
  final CineMarketplaceCard widget;
  final bool compact;
  final bool verified;

  const _MarketplaceIdentity({
    required this.widget,
    required this.compact,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    final pricing = switch (widget.pricingMode) {
      'fixed' => 'Fixed price',
      'on_request' => 'Bargain privately',
      _ => 'Offers welcome',
    };
    final role = widget.subtitle.trim().isEmpty
        ? marketplaceCategoryLabel(widget.category)
        : marketplaceCategoryLabel(widget.subtitle.trim());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.available
                    ? CineMarketplaceVisuals.of(context).gold
                    : CineMarketplaceVisuals.of(context).muted,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CineMarketplaceVisuals.of(context).archivo(
                  size: compact ? 17 : 24,
                  weight: FontWeight.w700,
                  height: 1.06,
                ),
              ),
            ),
            if (verified) ...[
              const SizedBox(width: 5),
              Icon(
                Icons.verified_rounded,
                color: CineMarketplaceVisuals.of(context).gold,
                size: compact ? 15 : 18,
              ),
            ],
          ],
        ),
        SizedBox(height: compact ? 6 : 8),
        Text(
          role,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CineMarketplaceVisuals.of(context).archivo(
            size: compact ? 12.5 : 16,
            color: CineMarketplaceVisuals.of(context).secondary,
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        Text(
          widget.summary.trim().isEmpty
              ? marketplaceCategoryLabel(widget.category)
              : widget.summary.trim(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CineMarketplaceVisuals.of(context).archivo(
            size: compact ? 10.5 : 13,
            color: CineMarketplaceVisuals.of(context).muted,
          ),
        ),
        SizedBox(height: compact ? 7 : 10),
        Wrap(
          spacing: compact ? 10 : 14,
          runSpacing: 5,
          children: [
            _MetaDatum(
              icon: Icons.location_on_outlined,
              label: widget.city,
              compact: compact,
            ),
            _MetaDatum(
              icon: Icons.payments_outlined,
              label: _displayRate(widget.rateLabel),
              compact: compact,
              gold: true,
            ),
            _MetaDatum(
              icon: widget.allowsBargaining
                  ? Icons.handshake_outlined
                  : Icons.lock_outline_rounded,
              label: pricing,
              compact: compact,
            ),
            if (widget.trustScore != null)
              _MetaDatum(
                icon: Icons.shield_outlined,
                label: 'Trust ${widget.trustScore}/100',
                compact: compact,
              )
            else if (widget.rating > 0)
              _MetaDatum(
                icon: Icons.star_rounded,
                label: widget.rating.toStringAsFixed(1),
                compact: compact,
              ),
          ],
        ),
      ],
    );
  }
}

class _GridBadge extends StatelessWidget {
  final String label;

  const _GridBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .52),
          border: Border.all(color: Colors.white.withValues(alpha: .25)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CineMarketplaceVisuals.of(context).archivo(
                size: 11, weight: FontWeight.w700, color: Colors.white)),
      );
}

class _MetaDatum extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;
  final bool gold;

  const _MetaDatum({
    required this.icon,
    required this.label,
    required this.compact,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = gold
        ? CineMarketplaceVisuals.of(context).gold
        : CineMarketplaceVisuals.of(context).muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 12 : 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: CineMarketplaceVisuals.of(context).archivo(
            size: compact ? 9.5 : 11.5,
            weight: gold ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MarketplaceActionRail extends StatelessWidget {
  final VoidCallback? onProfile;
  final VoidCallback? onRequest;
  final String requestLabel;
  final bool compact;

  const _MarketplaceActionRail({
    required this.onProfile,
    required this.onRequest,
    required this.requestLabel,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 14,
        compact ? 8 : 10,
        compact ? 10 : 14,
        compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: CineMarketplaceVisuals.of(context).border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onProfile,
              icon: Icon(Icons.person_search_outlined, size: compact ? 15 : 17),
              label: const Text('View profile'),
              style: _outlinedStyle(context, compact),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: CineMarketplaceVisuals.of(context).goldGradient,
                borderRadius: BorderRadius.circular(compact ? 12 : 15),
              ),
              child: FilledButton.icon(
                onPressed: onRequest,
                icon: Icon(Icons.chat_bubble_outline_rounded,
                    size: compact ? 14 : 17),
                label: Text(requestLabel),
                style: _filledStyle(context, compact),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _outlinedStyle(BuildContext context, bool compact) =>
      OutlinedButton.styleFrom(
        foregroundColor: CineMarketplaceVisuals.of(context).gold,
        side: BorderSide(color: CineMarketplaceVisuals.of(context).gold),
        padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 15),
        ),
        textStyle: CineMarketplaceVisuals.of(context).archivo(
          size: compact ? 11 : 13,
          weight: FontWeight.w600,
        ),
      );

  ButtonStyle _filledStyle(BuildContext context, bool compact) =>
      FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        foregroundColor: CineMarketplaceVisuals.of(context).onGold,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 15),
        ),
        textStyle: CineMarketplaceVisuals.of(context).archivo(
          size: compact ? 11 : 13,
          weight: FontWeight.w700,
        ),
      );
}

class _ShortlistButton extends StatelessWidget {
  final bool active;
  final bool busy;
  final VoidCallback onTap;

  const _ShortlistButton({
    required this.active,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        tooltip: active ? 'Saved — manage in Shortlist' : 'Add to shortlist',
        padding: EdgeInsets.zero,
        onPressed: busy || active ? null : onTap,
        icon: busy
            ? SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: CineMarketplaceVisuals.of(context).gold,
                ),
              )
            : Icon(
                active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: CineMarketplaceVisuals.of(context).gold,
                size: 20,
              ),
        style: IconButton.styleFrom(
          side: BorderSide(
            color:
                CineMarketplaceVisuals.of(context).gold.withValues(alpha: 0.45),
          ),
          backgroundColor: active
              ? CineMarketplaceVisuals.of(context).gold.withValues(alpha: 0.12)
              : CineMarketplaceVisuals.of(context)
                  .background
                  .withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

/// Staggers result rows upward in the same order as the reference animation.
class CineMarketplaceResults extends StatefulWidget {
  final List<Widget> cards;
  final bool grid;

  const CineMarketplaceResults({
    super.key,
    required this.cards,
    this.grid = false,
  });

  @override
  State<CineMarketplaceResults> createState() => _CineMarketplaceResultsState();
}

class _CineMarketplaceResultsState extends State<CineMarketplaceResults>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ScrollController _horizontal = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    if (cards.isEmpty) return const SizedBox.shrink();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final count = cards.length.clamp(1, 8);
    Widget animatedCard(int index) => reduceMotion
        ? cards[index]
        : _RevealRow(
            controller: _controller,
            start: (index / count) * 0.52,
            child: cards[index],
          );
    if (!widget.grid) {
      return Column(
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            animatedCard(index),
            if (index != cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth < 420
          ? (constraints.maxWidth * .83).clamp(230.0, 330.0)
          : 306.0;
      final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final carouselHeight = 460.0 + (textScale - 1).clamp(0.0, 3.0) * 96.0;
      return Column(
        children: [
          SizedBox(
            height: carouselHeight,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: const {
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.touch,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
              ),
              child: ListView.separated(
                controller: _horizontal,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, index) => SizedBox(
                  width: width,
                  child: animatedCard(index),
                ),
              ),
            ),
          ),
          if (cards.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  tooltip: 'Previous listings',
                  onPressed: () => _scrollBy(-width - 12),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                IconButton(
                  tooltip: 'Next listings',
                  onPressed: () => _scrollBy(width + 12),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ]),
            ),
        ],
      );
    });
  }

  void _scrollBy(double delta) {
    if (!_horizontal.hasClients) return;
    final position = _horizontal.position;
    _horizontal.animateTo(
      (position.pixels + delta).clamp(0.0, position.maxScrollExtent),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
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
        (start + 0.42).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 23),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Reusable image frame for marketplace rows, profiles and galleries.
class CineMarketplaceMediaFrame extends StatelessWidget {
  final String? listingTitle;
  final String? imageUrl;
  final String kind;
  final double width;
  final double height;
  final double radius;
  final String? heroTag;
  final BoxFit fit;

  const CineMarketplaceMediaFrame({
    super.key,
    this.listingTitle,
    required this.imageUrl,
    required this.kind,
    required this.width,
    required this.height,
    required this.radius,
    this.heroTag,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final source = imageUrl?.trim() ?? '';
    final fallback = _MarketplacePlate(kind: kind);
    final brandedRental = kind == 'equipment' &&
        {'arr camera rentals', 'arri camera rentals'}
            .contains(listingTitle?.trim().toLowerCase());
    final media = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: source.isEmpty && brandedRental
            ? Image.asset('assets/images/arr-camera-rentals-v1.jpg', fit: fit)
            : source.isEmpty
                ? fallback
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      fallback,
                      Image.network(
                        source,
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        fit: fit,
                        alignment:
                            {'actor', 'model', 'influencer'}.contains(kind)
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
    final framed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: CineMarketplaceVisuals.of(context).border),
      ),
      child: media,
    );
    if (heroTag == null) return framed;
    return Hero(
      tag: heroTag!,
      child: framed,
    );
  }
}

/// Public alias so other "entity card" contexts (project cards, booking
/// cards, etc. outside the marketplace) can reuse the exact same
/// tone-gradient + film-grain fallback plate.
class CineTonePlate extends StatelessWidget {
  final String kind;

  const CineTonePlate({super.key, required this.kind});

  @override
  Widget build(BuildContext context) => _MarketplacePlate(kind: kind);
}

class _MarketplacePlate extends StatelessWidget {
  final String kind;

  const _MarketplacePlate({required this.kind});

  @override
  Widget build(BuildContext context) {
    final tones = _tonesForKind(kind);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.45, -0.72),
          radius: 1.25,
          colors: tones,
        ),
      ),
      child: CustomPaint(painter: const _FilmTexturePainter()),
    );
  }
}

class _FilmTexturePainter extends CustomPainter {
  const _FilmTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 26) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height * 0.48, size.height),
        line,
      );
    }
    final shade = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Color(0x99000000)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, shade);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

List<Color> _tonesForKind(String kind) {
  return switch (kind.toLowerCase()) {
    'actor' => const [Color(0xFF413A30), Color(0xFF15141A)],
    'model' => const [Color(0xFF44352C), Color(0xFF16130F)],
    'influencer' => const [Color(0xFF463A3A), Color(0xFF161112)],
    'crew' => const [Color(0xFF3D3830), Color(0xFF141313)],
    'location' => const [Color(0xFF2F3A37), Color(0xFF121418)],
    'equipment' => const [Color(0xFF333A44), Color(0xFF111319)],
    'agency' => const [Color(0xFF2C3640), Color(0xFF101317)],
    'distribution' => const [Color(0xFF463A3A), Color(0xFF161112)],
    _ => const [Color(0xFF37342F), Color(0xFF131317)],
  };
}

String _displayRate(String value) {
  return value.replaceAllMapped(
    RegExp(r'(?<=\d)k\b'),
    (_) => 'K',
  );
}

/// Presentation-only names. Marketplace query and listing keys stay stable.
String marketplaceCategoryLabel(String value) => switch (value.trim()) {
      'Talent' || 'Actor / Talent' => 'Actor',
      'Crew' || 'Crew / Services' || 'Crew Services' => 'Production Services',
      'General Crew' => 'General Production',
      'Camera Crew' => 'Camera Department',
      'Media & Equipment' => 'Camera & Lighting',
      _ => value,
    };

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
  return CineMarketplaceVisuals.of(context).gold;
}
