import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/director/director_discovery_models.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/network/open_url.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/verification/verification_models.dart';
import '../models/dp_candidate.dart';

class DPStakeholderProfileV3 extends StatefulWidget {
  final DpCandidate candidate;
  final String type;
  final DirectorDiscoveryItem? directorItem;
  final MarketplaceListing? listing;
  final VoidCallback onShortlist;
  final Future<void> Function()? onFinalize;
  final VoidCallback? onProviderPending;

  const DPStakeholderProfileV3({
    super.key,
    required this.candidate,
    required this.type,
    this.directorItem,
    this.listing,
    required this.onShortlist,
    required this.onFinalize,
    this.onProviderPending,
  }) : assert(directorItem != null || listing != null);

  @override
  State<DPStakeholderProfileV3> createState() =>
      _DPStakeholderProfileV3State();
}

class _DPStakeholderProfileV3State extends State<DPStakeholderProfileV3> {
  static const _tabs = <String>[
    'Overview',
    'Details',
    'Portfolio',
    'Media Kit',
    'Availability',
  ];

  late final List<GlobalKey> _sectionKeys =
      List<GlobalKey>.generate(_tabs.length, (_) => GlobalKey());
  int _activeTab = 0;
  int _selectedVisual = 1;

  @override
  Widget build(BuildContext context) {
    final visuals = _buildVisuals();
    if (_selectedVisual >= visuals.length) {
      _selectedVisual = visuals.length > 1 ? 1 : 0;
    }
    final mediaKit = widget.directorItem?.mediaKit ?? widget.listing?.mediaKit;
    final isDirector = widget.directorItem != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileCinemaGallery(
          candidate: widget.candidate,
          type: widget.type,
          visuals: visuals,
          selectedIndex: _selectedVisual,
          onSelected: (index) => setState(() => _selectedVisual = index),
        ),
        const SizedBox(height: 18),
        _CinematicActionDeck(
          candidate: widget.candidate,
          shortlistEnabled:
              !isDirector || widget.candidate.marketplaceListingId != null,
          finalizeEnabled: widget.onFinalize != null,
          onShortlist: !isDirector || widget.candidate.marketplaceListingId != null
              ? widget.onShortlist
              : (widget.onProviderPending ?? widget.onShortlist),
          onFinalize: widget.onFinalize,
        ),
        const SizedBox(height: 18),
        _ProfileSectionRail(
          labels: _tabs,
          activeIndex: _activeTab,
          onSelect: _selectTab,
        ),
        const SizedBox(height: 18),
        _ProfileSectionCard(
          key: _sectionKeys[0],
          eyebrow: 'PROFILE',
          title: 'Overview',
          icon: Icons.auto_awesome_rounded,
          child: _OverviewContent(
            candidate: widget.candidate,
            summary: _summary,
            owner: _ownerName,
            verification: _verificationStatus,
          ),
        ),
        const SizedBox(height: 14),
        _ProfileSectionCard(
          key: _sectionKeys[1],
          eyebrow: 'LIVE DETAILS',
          title: 'Professional details',
          icon: Icons.badge_outlined,
          child: _DetailsContent(
            candidate: widget.candidate,
            directorItem: widget.directorItem,
            listing: widget.listing,
          ),
        ),
        const SizedBox(height: 14),
        _ProfileSectionCard(
          key: _sectionKeys[2],
          eyebrow: 'PORTFOLIO',
          title: 'Gallery & featured work',
          icon: Icons.photo_library_outlined,
          child: _PortfolioContent(
            media: _media,
            candidate: widget.candidate,
          ),
        ),
        const SizedBox(height: 14),
        _ProfileSectionCard(
          key: _sectionKeys[3],
          eyebrow: 'VERIFIED MEDIA',
          title: 'Media kit',
          icon: Icons.workspace_premium_outlined,
          child: _MediaKitContent(
            mediaKit: mediaKit,
            resumeFile: widget.directorItem?.resumeFile,
          ),
        ),
        const SizedBox(height: 14),
        _ProfileSectionCard(
          key: _sectionKeys[4],
          eyebrow: 'DIRECTOR READY',
          title: 'Availability & trust',
          icon: Icons.verified_user_outlined,
          child: _AvailabilityContent(
            candidate: widget.candidate,
            verification: _verificationStatus,
            isDirectorRecord: isDirector,
          ),
        ),
        const SizedBox(height: 18),
        _BottomDecisionCard(
          candidate: widget.candidate,
          shortlistEnabled:
              !isDirector || widget.candidate.marketplaceListingId != null,
          finalizeEnabled: widget.onFinalize != null,
          onShortlist: !isDirector || widget.candidate.marketplaceListingId != null
              ? widget.onShortlist
              : (widget.onProviderPending ?? widget.onShortlist),
          onFinalize: widget.onFinalize,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String get _summary =>
      widget.directorItem?.summary ?? widget.listing?.summary ?? widget.candidate.notes;

  String get _ownerName => widget.directorItem?.ownerName ??
      widget.listing?.ownerName ??
      'CineConnect member';

  String get _verificationStatus => widget.directorItem?.verificationStatus ??
      widget.listing?.verificationStatus ??
      (widget.candidate.verified ? 'verified' : 'pending');

  List<MarketplaceListingMedia> get _media =>
      widget.directorItem?.media ?? widget.listing?.media ?? const [];

  List<_ProfileVisual> _buildVisuals() {
    final visuals = <_ProfileVisual>[];
    final seen = <String>{};

    void addUrl(String? url, {String? label}) {
      final clean = url?.trim();
      if (clean == null || clean.isEmpty || !seen.add(clean)) return;
      visuals.add(_ProfileVisual(url: clean, label: label));
    }

    for (final item in _media) {
      final file = item.file;
      final mime = file?.mimeType.toLowerCase() ?? '';
      if (mime.startsWith('video/')) continue;
      addUrl(
        file?.publicUrl,
        label: item.caption?.trim().isNotEmpty == true
            ? item.caption
            : file?.originalName,
      );
    }
    addUrl(widget.candidate.imageUrl, label: widget.candidate.name);

    final fallbackLabels = <String>['Portrait', 'Featured', 'Portfolio', 'On set'];
    var fallbackIndex = 0;
    while (visuals.length < 3) {
      visuals.add(
        _ProfileVisual(
          label: fallbackLabels[fallbackIndex % fallbackLabels.length],
          fallbackIndex: fallbackIndex,
        ),
      );
      fallbackIndex++;
    }
    return visuals.take(8).toList();
  }

  void _selectTab(int index) {
    setState(() => _activeTab = index);
    final target = _sectionKeys[index].currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.06,
      duration: const Duration(milliseconds: 760),
      curve: Curves.easeInOutCubic,
    );
  }
}

class _ProfileVisual {
  final String? url;
  final String? label;
  final int fallbackIndex;

  const _ProfileVisual({
    this.url,
    this.label,
    this.fallbackIndex = 0,
  });
}

class _ProfileCinemaGallery extends StatelessWidget {
  final DpCandidate candidate;
  final String type;
  final List<_ProfileVisual> visuals;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _ProfileCinemaGallery({
    required this.candidate,
    required this.type,
    required this.visuals,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 720;
    final cardWidth = mobile ? math.min(258.0, width * .72).toDouble() : 260.0;
    final height = mobile ? 360.0 : 410.0;

    return _AtmosphericFrame(
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 8 : 20,
        vertical: mobile ? 20 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: mobile ? 6 : 2),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.goldMid,
                    boxShadow: [
                      BoxShadow(
                        color: colors.goldGlow,
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'CINECONNECT · VERIFIED PROFILE',
                  style: AppTextStyles.caption.copyWith(
                    color: colors.goldDark,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.25,
                  ),
                ),
                const Spacer(),
                if (candidate.available)
                  _GlassMicroChip(
                    icon: Icons.bolt_rounded,
                    label: 'Available',
                    positive: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: height,
            child: ListView.separated(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: mobile ? 16 : 32,
                vertical: 24,
              ),
              itemCount: visuals.length,
              separatorBuilder: (_, __) => SizedBox(width: mobile ? 10 : 16),
              itemBuilder: (context, index) {
                final selected = index == selectedIndex;
                return _NetflixVisualCard(
                  visual: visuals[index],
                  candidate: candidate,
                  type: type,
                  width: cardWidth,
                  selected: selected,
                  origin: index == 0
                      ? Alignment.centerLeft
                      : index == visuals.length - 1
                          ? Alignment.centerRight
                          : Alignment.center,
                  onSelected: () => onSelected(index),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: mobile ? 6 : 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Hover a frame on web or tap on mobile to bring it forward.',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${selectedIndex + 1}/${visuals.length}',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.goldDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NetflixVisualCard extends StatefulWidget {
  final _ProfileVisual visual;
  final DpCandidate candidate;
  final String type;
  final double width;
  final bool selected;
  final Alignment origin;
  final VoidCallback onSelected;

  const _NetflixVisualCard({
    required this.visual,
    required this.candidate,
    required this.type,
    required this.width,
    required this.selected,
    required this.origin,
    required this.onSelected,
  });

  @override
  State<_NetflixVisualCard> createState() => _NetflixVisualCardState();
}

class _NetflixVisualCardState extends State<_NetflixVisualCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final mobile = MediaQuery.sizeOf(context).width < 720;
    final active = widget.selected || (!mobile && _hovered);
    final scale = active ? (mobile ? 1.07 : 1.12) : 1.0;
    final visual = widget.visual;

    return MouseRegion(
      onEnter: (_) {
        if (!mobile) {
          setState(() => _hovered = true);
          widget.onSelected();
        }
      },
      onExit: (_) {
        if (!mobile) setState(() => _hovered = false);
      },
      child: GestureDetector(
        onTap: widget.onSelected,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 420),
          opacity: active || mobile ? 1 : .82,
          child: AnimatedScale(
            scale: scale,
            alignment: widget.origin,
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 420),
              width: widget.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: active
                      ? colors.goldMid.withValues(alpha: .92)
                      : colors.border,
                  width: active ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: active
                        ? colors.goldGlow.withValues(alpha: .82)
                        : colors.shadow.withValues(alpha: .42),
                    blurRadius: active ? 30 : 16,
                    spreadRadius: active ? 2 : 0,
                    offset: Offset(0, active ? 15 : 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ProfileVisualBackdrop(visual: visual),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, .38, .72, 1],
                        colors: [
                          Color(0x24000000),
                          Color(0x00000000),
                          Color(0x8A000000),
                          Color(0xE6000000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        if (widget.candidate.rating > 0)
                          _ImageBadge(
                            icon: Icons.star_rounded,
                            label: widget.candidate.rating.toStringAsFixed(1),
                          ),
                        const Spacer(),
                        _ImageBadge(
                          icon: widget.candidate.verified
                              ? Icons.verified_rounded
                              : Icons.shield_outlined,
                          label: widget.candidate.verified
                              ? 'Verified'
                              : 'Profile',
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.candidate.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFFFFCF5),
                                  fontFamily: 'Georgia',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                  shadows: [
                                    Shadow(
                                      color: Color(0xCC000000),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.candidate.verified) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: colors.goldLight,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.type} · ${widget.candidate.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFEDE8DB),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Color(0xCC000000), blurRadius: 6),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _AvailabilityDot(available: widget.candidate.available),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                widget.candidate.available
                                    ? 'AVAILABLE FOR PROJECTS'
                                    : 'LIMITED AVAILABILITY',
                                style: const TextStyle(
                                  color: Color(0xFFEDE8DB),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .75,
                                ),
                              ),
                            ),
                            Text(
                              widget.candidate.rateRange.trim().isEmpty
                                  ? 'Rate on request'
                                  : widget.candidate.rateRange,
                              style: TextStyle(
                                color: colors.goldLight,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xCC000000),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (active)
                    const Positioned.fill(
                      child: IgnorePointer(child: _CardSheen()),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileVisualBackdrop extends StatelessWidget {
  final _ProfileVisual visual;

  const _ProfileVisualBackdrop({required this.visual});

  @override
  Widget build(BuildContext context) {
    if (visual.url != null) {
      return Image.network(
        visual.url!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _FallbackArtwork(index: visual.fallbackIndex),
      );
    }
    return _FallbackArtwork(index: visual.fallbackIndex);
  }
}

class _FallbackArtwork extends StatelessWidget {
  final int index;

  const _FallbackArtwork({required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final palettes = <List<Color>>[
      [colors.infoBlue.withValues(alpha: .75), colors.infoPurple.withValues(alpha: .55), colors.goldMid.withValues(alpha: .50)],
      [colors.goldDark.withValues(alpha: .78), colors.infoBlue.withValues(alpha: .48), colors.surface],
      [colors.infoPurple.withValues(alpha: .70), colors.goldLight.withValues(alpha: .50), colors.elevatedSurface],
      [colors.holographicTeal.withValues(alpha: .68), colors.holographicCyan.withValues(alpha: .58), colors.goldDark.withValues(alpha: .42)],
    ];
    final palette = palettes[index % palettes.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: 40,
            child: Icon(
              Icons.movie_filter_outlined,
              size: 150,
              color: Colors.white.withValues(alpha: .10),
            ),
          ),
          Center(
            child: Icon(
              Icons.person_outline_rounded,
              size: 82,
              color: Colors.white.withValues(alpha: .38),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionRail extends StatefulWidget {
  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const _ProfileSectionRail({
    required this.labels,
    required this.activeIndex,
    required this.onSelect,
  });

  @override
  State<_ProfileSectionRail> createState() => _ProfileSectionRailState();
}

class _ProfileSectionRailState extends State<_ProfileSectionRail> {
  final ScrollController _controller = ScrollController();
  static const double _tabWidth = 116;
  static const double _gap = 8;

  @override
  void didUpdateWidget(covariant _ProfileSectionRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealActive());
    }
  }

  void _revealActive() {
    if (!_controller.hasClients) return;
    final target = widget.activeIndex * (_tabWidth + _gap);
    final max = _controller.position.maxScrollExtent;
    _controller.animateTo(
      target.clamp(0.0, max).toDouble(),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final totalWidth =
        widget.labels.length * _tabWidth + (widget.labels.length - 1) * _gap;
    final left = widget.activeIndex * (_tabWidth + _gap);

    return Container(
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: colors.surface.withValues(alpha: .62),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: .22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          width: totalWidth,
          height: 43,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 620),
                curve: Curves.easeInOutCubic,
                left: left,
                top: 0,
                width: _tabWidth,
                height: 38,
                child: _MovingGoldPill(),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 620),
                curve: Curves.easeInOutCubic,
                left: left + 12,
                bottom: -1,
                width: _tabWidth - 24,
                height: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.goldMid,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colors.goldGlow,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < widget.labels.length; i++) ...[
                    SizedBox(
                      width: _tabWidth,
                      height: 38,
                      child: InkWell(
                        onTap: () => widget.onSelect(i),
                        borderRadius: BorderRadius.circular(999),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: AppTextStyles.smallMeta.copyWith(
                              color: i == widget.activeIndex
                                  ? colors.onGold
                                  : colors.textSecondary,
                              fontWeight: i == widget.activeIndex
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                            child: Text(widget.labels[i]),
                          ),
                        ),
                      ),
                    ),
                    if (i != widget.labels.length - 1)
                      const SizedBox(width: _gap),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovingGoldPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: colors.goldGradient,
        boxShadow: [
          BoxShadow(
            color: colors.goldGlow.withValues(alpha: .90),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: const _CardSheen(),
    );
  }
}

class _CinematicActionDeck extends StatelessWidget {
  final DpCandidate candidate;
  final bool shortlistEnabled;
  final bool finalizeEnabled;
  final VoidCallback onShortlist;
  final Future<void> Function()? onFinalize;

  const _CinematicActionDeck({
    required this.candidate,
    required this.shortlistEnabled,
    required this.finalizeEnabled,
    required this.onShortlist,
    required this.onFinalize,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 720;
    final colors = context.appColors;

    final shortlist = _CinematicActionButton(
      icon: Icons.bookmark_add_outlined,
      eyebrow: 'SHORTLIST',
      title: shortlistEnabled ? 'Save for project review' : 'Listing link required',
      subtitle: shortlistEnabled
          ? 'Keep ${candidate.name} inside your casting decision flow.'
          : 'This provider must be linked before it can enter a project shortlist.',
      secondary: true,
      enabled: true,
      onTap: onShortlist,
    );
    final finalize = _CinematicActionButton(
      icon: Icons.movie_creation_outlined,
      eyebrow: 'FINALIZE',
      title: finalizeEnabled ? 'Finalize & send request' : 'Booking not linked yet',
      subtitle: finalizeEnabled
          ? 'Open the booking request and confirm the next production step.'
          : 'A marketplace listing is required before a booking request can be sent.',
      secondary: false,
      enabled: finalizeEnabled,
      onTap: finalizeEnabled ? () => onFinalize?.call() : null,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: const _ActionBubbles(),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: colors.surface.withValues(alpha: .52),
            border: Border.all(color: colors.goldMid.withValues(alpha: .24)),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: .20),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: mobile
              ? Column(
                  children: [
                    shortlist,
                    const SizedBox(height: 12),
                    finalize,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: shortlist),
                    const SizedBox(width: 12),
                    Expanded(child: finalize),
                  ],
                ),
        ),
      ],
    );
  }
}

class _BottomDecisionCard extends StatelessWidget {
  final DpCandidate candidate;
  final bool shortlistEnabled;
  final bool finalizeEnabled;
  final VoidCallback onShortlist;
  final Future<void> Function()? onFinalize;

  const _BottomDecisionCard({
    required this.candidate,
    required this.shortlistEnabled,
    required this.finalizeEnabled,
    required this.onShortlist,
    required this.onFinalize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface,
            colors.goldDark.withValues(alpha: .09),
            colors.infoPurple.withValues(alpha: .07),
          ],
        ),
        border: Border.all(color: colors.goldMid.withValues(alpha: .28)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 330,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'READY FOR THE NEXT STEP?',
                  style: AppTextStyles.caption.copyWith(
                    color: colors.goldDark,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  candidate.name,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onShortlist,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(shortlistEnabled ? 'Shortlist' : 'Check shortlist link'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.goldDark,
              side: BorderSide(color: colors.goldMid.withValues(alpha: .55)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: const StadiumBorder(),
            ),
          ),
          FilledButton.icon(
            onPressed: finalizeEnabled ? () => onFinalize?.call() : null,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Finalize & send request'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.goldMid,
              foregroundColor: colors.onGold,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CinematicActionButton extends StatefulWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final bool secondary;
  final bool enabled;
  final VoidCallback? onTap;

  const _CinematicActionButton({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.secondary,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_CinematicActionButton> createState() => _CinematicActionButtonState();
}

class _CinematicActionButtonState extends State<_CinematicActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();
  bool _hovered = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.018 : 1,
          duration: const Duration(milliseconds: 220),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              final begin = Alignment(-1 + t * 2, -1);
              final end = Alignment(1 - t * 2, 1);
              final base = widget.secondary
                  ? [
                      colors.surface.withValues(alpha: .90),
                      colors.holographicTeal.withValues(alpha: .18),
                      colors.holographicCyan.withValues(alpha: .15),
                      colors.goldLight.withValues(alpha: .15),
                    ]
                  : [
                      colors.goldLight,
                      colors.goldMid,
                      colors.holographicCyan.withValues(alpha: .78),
                      colors.goldMid,
                    ];
              return Container(
                constraints: const BoxConstraints(minHeight: 112),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(begin: begin, end: end, colors: base),
                  border: Border.all(
                    color: widget.secondary
                        ? colors.goldMid.withValues(alpha: .38)
                        : colors.goldLight.withValues(alpha: .72),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.secondary
                          ? colors.shadow.withValues(alpha: .18)
                          : colors.goldGlow.withValues(alpha: .68),
                      blurRadius: _hovered ? 28 : 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                foregroundDecoration: widget.enabled
                    ? null
                    : BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: colors.background.withValues(alpha: .36),
                      ),
                child: child,
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.secondary
                        ? colors.goldMid.withValues(alpha: .15)
                        : colors.onGold.withValues(alpha: .12),
                    border: Border.all(
                      color: widget.secondary
                          ? colors.goldMid.withValues(alpha: .34)
                          : colors.onGold.withValues(alpha: .18),
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.secondary ? colors.goldDark : colors.onGold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.eyebrow,
                        style: AppTextStyles.caption.copyWith(
                          color: widget.secondary
                              ? colors.goldDark
                              : colors.onGold.withValues(alpha: .78),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.title,
                        style: AppTextStyles.cardLabel.copyWith(
                          color: widget.secondary
                              ? colors.textPrimary
                              : colors.onGold,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: widget.secondary
                              ? colors.textSecondary
                              : colors.onGold.withValues(alpha: .75),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: widget.secondary ? colors.goldDark : colors.onGold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final IconData icon;
  final Widget child;

  const _ProfileSectionCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface.withValues(alpha: .96),
            colors.holographicTeal.withValues(alpha: .045),
            colors.holographicCyan.withValues(alpha: .035),
          ],
        ),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: .18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    colors: [
                      colors.goldLight.withValues(alpha: .28),
                      colors.holographicCyan.withValues(alpha: .10),
                    ],
                  ),
                  border: Border.all(color: colors.goldMid.withValues(alpha: .24)),
                ),
                child: Icon(icon, size: 19, color: colors.goldDark),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.goldDark,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: AppTextStyles.cardLabel.copyWith(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _OverviewContent extends StatelessWidget {
  final DpCandidate candidate;
  final String summary;
  final String owner;
  final String verification;

  const _OverviewContent({
    required this.candidate,
    required this.summary,
    required this.owner,
    required this.verification,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final items = <Widget>[
      _InfoTile(icon: Icons.location_on_outlined, label: 'City', value: candidate.city),
      _InfoTile(icon: Icons.sell_outlined, label: 'Rate', value: candidate.rateRange),
      _InfoTile(icon: Icons.person_outline_rounded, label: 'Owner', value: owner),
      _InfoTile(icon: Icons.verified_outlined, label: 'Verification', value: _titleCase(verification)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          summary.trim().isEmpty ? 'No public profile summary has been added yet.' : summary,
          style: AppTextStyles.body.copyWith(
            color: colors.textSecondary,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: items),
        if (candidate.skills.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in candidate.skills.take(10))
                _GlassTag(label: skill),
            ],
          ),
        ],
      ],
    );
  }
}

class _DetailsContent extends StatelessWidget {
  final DpCandidate candidate;
  final DirectorDiscoveryItem? directorItem;
  final MarketplaceListing? listing;

  const _DetailsContent({
    required this.candidate,
    required this.directorItem,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    final sections = directorItem?.sections
            .where((section) => section.rows.any((row) => row.value.trim().isNotEmpty))
            .toList() ??
        const <DirectorDiscoverySection>[];

    if (sections.isNotEmpty) {
      return Column(
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            _DetailGroup(section: sections[i]),
            if (i != sections.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _InfoTile(icon: Icons.category_outlined, label: 'Type', value: candidate.category),
        _InfoTile(icon: Icons.location_city_outlined, label: 'Location', value: candidate.city),
        _InfoTile(icon: Icons.payments_outlined, label: 'Starting rate', value: candidate.rateRange),
        _InfoTile(
          icon: Icons.source_outlined,
          label: 'Source',
          value: listing == null ? 'Director discovery' : 'Live marketplace',
        ),
      ],
    );
  }
}

class _DetailGroup extends StatelessWidget {
  final DirectorDiscoverySection section;

  const _DetailGroup({required this.section});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colors.mutedSurface.withValues(alpha: .42),
        border: Border.all(color: colors.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: AppTextStyles.cardLabel.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (final row in section.rows)
            if (row.value.trim().isNotEmpty)
              _KeyValueRow(label: row.label, value: row.value),
        ],
      ),
    );
  }
}

class _PortfolioContent extends StatelessWidget {
  final List<MarketplaceListingMedia> media;
  final DpCandidate candidate;

  const _PortfolioContent({required this.media, required this.candidate});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final visible = media.where((item) => item.file?.publicUrl != null).take(12).toList();
    if (visible.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.goldMid.withValues(alpha: .26)),
          gradient: LinearGradient(
            colors: [
              colors.goldLight.withValues(alpha: .08),
              colors.holographicCyan.withValues(alpha: .05),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined, color: colors.goldDark, size: 28),
            const SizedBox(height: 8),
            Text(
              'No public portfolio media yet',
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${candidate.name} has not published approved gallery media yet.',
              textAlign: TextAlign.center,
              style: AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
                ? 3
                : 2;
        final spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in visible)
              _PortfolioTile(item: item, width: itemWidth),
          ],
        );
      },
    );
  }
}

class _PortfolioTile extends StatefulWidget {
  final MarketplaceListingMedia item;
  final double width;

  const _PortfolioTile({required this.item, required this.width});

  @override
  State<_PortfolioTile> createState() => _PortfolioTileState();
}

class _PortfolioTileState extends State<_PortfolioTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final file = widget.item.file;
    final isVideo = file?.mimeType.startsWith('video/') ?? false;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: file?.publicUrl == null ? null : () => openUrlInNewTab(file!.publicUrl!),
        child: AnimatedScale(
          scale: _hovered ? 1.035 : 1,
          duration: const Duration(milliseconds: 260),
          child: Container(
            width: widget.width,
            height: widget.width * .72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _hovered ? colors.goldMid : colors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovered
                      ? colors.goldGlow.withValues(alpha: .50)
                      : colors.shadow.withValues(alpha: .15),
                  blurRadius: _hovered ? 22 : 10,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (!isVideo && file?.publicUrl != null)
                  Image.network(
                    file!.publicUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _FallbackArtwork(index: 2),
                  )
                else
                  const _FallbackArtwork(index: 3),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xB8000000)],
                    ),
                  ),
                ),
                if (isVideo)
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 8,
                  child: Text(
                    widget.item.caption ?? file?.originalName ?? 'Portfolio media',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(color: Colors.black, blurRadius: 5)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaKitContent extends StatelessWidget {
  final VerifiedMediaKit? mediaKit;
  final UploadedFile? resumeFile;

  const _MediaKitContent({required this.mediaKit, required this.resumeFile});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final kit = mediaKit;
    if (kit == null && resumeFile == null) {
      return Text(
        'No verified media kit or CV has been published for this profile yet.',
        style: AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resumeFile?.publicUrl != null) ...[
          _DocumentLink(
            file: resumeFile!,
            label: 'CV / Resume',
          ),
          if (kit != null) const SizedBox(height: 14),
        ],
        if (kit != null) ...[
          Row(
            children: [
              Icon(
                kit.verified ? Icons.verified_rounded : Icons.info_outline_rounded,
                color: kit.verified ? colors.goldDark : colors.textTertiary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  kit.headline,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final metric in kit.metrics)
                _MetricTile(label: metric.label, value: metric.value),
              if (kit.ratingAverage > 0)
                _MetricTile(
                  label: '${kit.reviewCount} reviews',
                  value: kit.ratingAverage.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                ),
            ],
          ),
          if (kit.rateCards.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Rate cards',
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final card in kit.rateCards)
                  _RateCardTile(card: card),
              ],
            ),
          ],
          if (kit.platforms.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final platform in kit.platforms)
                  OutlinedButton.icon(
                    onPressed: platform.url.isEmpty
                        ? null
                        : () => openUrlInNewTab(platform.url),
                    icon: const Icon(Icons.open_in_new_rounded, size: 15),
                    label: Text(platform.platform),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.goldDark,
                      shape: const StadiumBorder(),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _AvailabilityContent extends StatelessWidget {
  final DpCandidate candidate;
  final String verification;
  final bool isDirectorRecord;

  const _AvailabilityContent({
    required this.candidate,
    required this.verification,
    required this.isDirectorRecord,
  });

  @override
  Widget build(BuildContext context) {
    final trust = candidate.trustMetrics;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _InfoTile(
          icon: Icons.event_available_outlined,
          label: 'Availability',
          value: candidate.available ? 'Available for selected dates' : 'Limited dates',
          positive: candidate.available,
        ),
        _InfoTile(
          icon: Icons.verified_user_outlined,
          label: 'Verification',
          value: _titleCase(verification),
          positive: candidate.verified,
        ),
        _InfoTile(
          icon: Icons.storage_outlined,
          label: 'Record source',
          value: isDirectorRecord ? 'Director discovery database' : 'Live marketplace database',
        ),
        if (trust != null)
          _InfoTile(
            icon: Icons.shield_outlined,
            label: 'Trust',
            value: '${trust.score}/100 · ${trust.label}',
            positive: true,
          ),
        if (candidate.completedBookings > 0)
          _InfoTile(
            icon: Icons.task_alt_rounded,
            label: 'Completed bookings',
            value: '${candidate.completedBookings}',
            positive: true,
          ),
      ],
    );
  }
}

class _DocumentLink extends StatelessWidget {
  final UploadedFile file;
  final String label;

  const _DocumentLink({required this.file, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: file.publicUrl == null ? null : () => openUrlInNewTab(file.publicUrl!),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.goldMid.withValues(alpha: .30)),
          gradient: LinearGradient(
            colors: [
              colors.goldLight.withValues(alpha: .10),
              colors.holographicTeal.withValues(alpha: .07),
            ],
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: colors.goldDark),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    file.originalName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: colors.goldDark, size: 18),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _MetricTile({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.border),
        gradient: LinearGradient(
          colors: [
            colors.surface,
            colors.holographicCyan.withValues(alpha: .06),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: colors.goldDark),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RateCardTile extends StatelessWidget {
  final MediaKitRateCard card;

  const _RateCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 210,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.goldMid.withValues(alpha: .26)),
        color: colors.mutedSurface.withValues(alpha: .45),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.label,
            style: AppTextStyles.cardLabel.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card.priceLabel,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.goldDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card.scope,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool positive;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.positive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 238,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        color: colors.mutedSurface.withValues(alpha: .40),
        border: Border.all(color: colors.borderMuted),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: positive
                  ? colors.success.withValues(alpha: .12)
                  : colors.goldMid.withValues(alpha: .10),
            ),
            child: Icon(
              icon,
              size: 17,
              color: positive ? colors.success : colors.goldDark,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.trim().isEmpty ? 'Not provided' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTag extends StatelessWidget {
  final String label;

  const _GlassTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.goldMid.withValues(alpha: .25)),
        gradient: LinearGradient(
          colors: [
            colors.surface.withValues(alpha: .82),
            colors.holographicCyan.withValues(alpha: .07),
          ],
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GlassMicroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool positive;

  const _GlassMicroChip({
    required this.icon,
    required this.label,
    this.positive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: colors.surface.withValues(alpha: .58),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: positive ? colors.success : colors.goldDark,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ImageBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0x7A09090B),
        border: Border.all(color: const Color(0x52FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFEBD48F)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityDot extends StatelessWidget {
  final bool available;

  const _AvailabilityDot({required this.available});

  @override
  Widget build(BuildContext context) {
    final color = available ? const Color(0xFF8FE2A7) : const Color(0xFFFFCB73);
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 8, spreadRadius: 1)],
      ),
    );
  }
}

class _AtmosphericFrame extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;

  const _AtmosphericFrame({required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface,
            colors.holographicTeal.withValues(alpha: .09),
            colors.holographicCyan.withValues(alpha: .07),
            colors.goldLight.withValues(alpha: .08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: .24),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _HeroBubbles())),
          Positioned(
            left: -100,
            top: -150,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.infoBlue.withValues(alpha: .12),
                    colors.infoBlue.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -120,
            bottom: -180,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.goldMid.withValues(alpha: .12),
                    colors.goldMid.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _HeroBubbles extends StatelessWidget {
  const _HeroBubbles();

  static const _specs = <_FloatingBubbleSpec>[
    _FloatingBubbleSpec(.05, .10, 38, 9, 0),
    _FloatingBubbleSpec(.20, .74, 17, 7, 1.1),
    _FloatingBubbleSpec(.45, .08, 25, 8.5, .6),
    _FloatingBubbleSpec(.62, .78, 14, 6.5, 1.8),
    _FloatingBubbleSpec(.78, .13, 46, 10.5, .3),
    _FloatingBubbleSpec(.91, .62, 22, 7.8, 1.3),
    _FloatingBubbleSpec(.34, .45, 11, 6, 2.2),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (final spec in _specs)
              Positioned(
                left: constraints.maxWidth * spec.x,
                top: constraints.maxHeight * spec.y,
                child: _FloatingBubble(spec: spec),
              ),
          ],
        );
      },
    );
  }
}

class _ActionBubbles extends StatelessWidget {
  const _ActionBubbles();

  static const _specs = <_FloatingBubbleSpec>[
    _FloatingBubbleSpec(.02, .04, 28, 8, 0),
    _FloatingBubbleSpec(.23, .70, 13, 6, .8),
    _FloatingBubbleSpec(.58, .08, 19, 7, 1.4),
    _FloatingBubbleSpec(.82, .55, 36, 9, .3),
    _FloatingBubbleSpec(.95, .10, 12, 6.5, 2),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (final spec in _specs)
              Positioned(
                left: constraints.maxWidth * spec.x,
                top: constraints.maxHeight * spec.y,
                child: _FloatingBubble(spec: spec),
              ),
          ],
        );
      },
    );
  }
}

class _FloatingBubbleSpec {
  final double x;
  final double y;
  final double size;
  final double duration;
  final double delay;

  const _FloatingBubbleSpec(
    this.x,
    this.y,
    this.size,
    this.duration,
    this.delay,
  );
}

class _FloatingBubble extends StatefulWidget {
  final _FloatingBubbleSpec spec;

  const _FloatingBubble({required this.spec});

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.spec.duration * 1000).round()),
    );
    Future<void>.delayed(
      Duration(milliseconds: (widget.spec.delay * 1000).round()),
      () {
        if (mounted) _controller.repeat(reverse: true);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(math.sin(t * math.pi) * 10, -t * 15),
          child: child,
        );
      },
      child: Container(
        width: widget.spec.size,
        height: widget.spec.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-.35, -.40),
            colors: [
              Colors.white.withValues(alpha: colors.isLight ? .88 : .46),
              colors.holographicTeal.withValues(alpha: .24),
              colors.holographicCyan.withValues(alpha: .15),
              colors.goldLight.withValues(alpha: .10),
              Colors.transparent,
            ],
            stops: const [0, .24, .50, .72, 1],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: colors.isLight ? .65 : .18),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.goldGlow.withValues(alpha: .16),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardSheen extends StatefulWidget {
  const _CardSheen();

  @override
  State<_CardSheen> createState() => _CardSheenState();
}

class _CardSheenState extends State<_CardSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final x = -1.8 + (_controller.value * 3.6);
        return Transform.translate(
          offset: Offset(x * 90, 0),
          child: Transform.rotate(
            angle: -.22,
            child: Container(
              width: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: .32),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _titleCase(String value) {
  if (value.trim().isEmpty) return 'Not provided';
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
