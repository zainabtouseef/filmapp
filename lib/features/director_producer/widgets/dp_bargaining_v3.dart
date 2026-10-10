import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/bookings/booking_models.dart';

class DPBargainingV3 extends StatefulWidget {
  final bool loading;
  final String? error;
  final List<NegotiationThread> negotiations;
  final Map<String, String> projectTitles;
  final Future<void> Function() onRefresh;
  final VoidCallback onFindTalent;
  final ValueChanged<String> onOpenNegotiation;

  const DPBargainingV3({
    super.key,
    required this.loading,
    required this.error,
    required this.negotiations,
    required this.projectTitles,
    required this.onRefresh,
    required this.onFindTalent,
    required this.onOpenNegotiation,
  });

  @override
  State<DPBargainingV3> createState() => _DPBargainingV3State();
}

class _DPBargainingV3State extends State<DPBargainingV3>
    with TickerProviderStateMixin {
  static const _filters = <String>[
    'All',
    'Your move',
    'Replied',
    'Locked',
    'Closed',
  ];

  late final AnimationController _ambient;
  late final AnimationController _sheen;
  late final AnimationController _entry;
  late final AnimationController _refreshSpin;
  final TextEditingController _search = TextEditingController();

  String _filter = 'All';
  String _query = '';
  String? _hoveredId;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _refreshSpin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(covariant DPBargainingV3 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.negotiations.length != widget.negotiations.length ||
        oldWidget.loading != widget.loading) {
      _entry
        ..stop()
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    _sheen.dispose();
    _entry.dispose();
    _refreshSpin.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    _refreshSpin.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        await _refreshSpin.animateTo(
          1,
          duration: const Duration(milliseconds: 180),
        );
        _refreshSpin
          ..stop()
          ..reset();
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _BargainingPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 720;
    final compact = width < 1050;

    final all = widget.negotiations;
    final visible = all.where((thread) {
      final stage = _dealStage(thread);
      if (_filter != 'All' && stage != _filter) return false;
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase().trim();
      final booking = thread.booking;
      final project = _projectTitle(thread);
      return booking.provider.displayName.toLowerCase().contains(q) ||
          project.toLowerCase().contains(q) ||
          booking.category.toLowerCase().contains(q) ||
          (booking.requirementTitle ?? '').toLowerCase().contains(q) ||
          (booking.projectCity ?? '').toLowerCase().contains(q);
    }).toList();

    final open = all.where((e) => !_isClosed(e) && !_isLocked(e)).length;
    final yourMove = all.where((e) => _dealStage(e) == 'Your move').length;
    final locked = all.where(_isLocked).length;
    final totalMinor = all.fold<int>(
      0,
      (sum, item) => sum + (item.currentOffer?.feeMinor ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(
          palette: palette,
          ambient: _ambient,
          sheen: _sheen,
          open: open,
          yourMove: yourMove,
          locked: locked,
          liveValue: _moneyCompact(totalMinor ~/ 100),
          onFindTalent: widget.onFindTalent,
          onRefresh: _refresh,
          refreshSpin: _refreshSpin,
          refreshing: _refreshing,
          mobile: mobile,
        ),
        const SizedBox(height: 12),
        _FilterCommandBar(
          palette: palette,
          filters: _filters,
          active: _filter,
          queryController: _search,
          query: _query,
          sheen: _sheen,
          counts: {
            for (final key in _filters)
              key: key == 'All'
                  ? all.length
                  : all.where((e) => _dealStage(e) == key).length,
          },
          onFilter: (value) {
            setState(() => _filter = value);
            _entry
              ..stop()
              ..reset()
              ..forward();
          },
          onQuery: (value) => setState(() => _query = value),
          mobile: mobile,
        ),
        const SizedBox(height: 12),
        if (widget.loading)
          _LoadingPanel(palette: palette)
        else if (widget.error != null)
          _ErrorPanel(
            palette: palette,
            message: widget.error!,
            onRetry: _refresh,
          )
        else if (all.isEmpty)
          _EmptyPanel(
            palette: palette,
            title: 'No negotiations yet',
            message:
                'Send a booking request from Marketplace to open your first bargaining room.',
            button: 'Find talent',
            onTap: widget.onFindTalent,
          )
        else if (compact) ...[
          _DealPulsePanel(
            palette: palette,
            negotiations: all,
            horizontal: true,
            ambient: _ambient,
            onOpen: widget.onOpenNegotiation,
          ),
          const SizedBox(height: 12),
          _NegotiationList(
            palette: palette,
            items: visible,
            projectTitle: _projectTitle,
            hoveredId: _hoveredId,
            mobile: mobile,
            entry: _entry,
            onHover: (id) => setState(() => _hoveredId = id),
            onOpen: widget.onOpenNegotiation,
            onFindTalent: widget.onFindTalent,
            queryActive: _filter != 'All' || _query.trim().isNotEmpty,
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _NegotiationList(
                  palette: palette,
                  items: visible,
                  projectTitle: _projectTitle,
                  hoveredId: _hoveredId,
                  mobile: false,
                  entry: _entry,
                  onHover: (id) => setState(() => _hoveredId = id),
                  onOpen: widget.onOpenNegotiation,
                  onFindTalent: widget.onFindTalent,
                  queryActive: _filter != 'All' || _query.trim().isNotEmpty,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 320,
                child: _DealPulsePanel(
                  palette: palette,
                  negotiations: all,
                  horizontal: false,
                  ambient: _ambient,
                  onOpen: widget.onOpenNegotiation,
                ),
              ),
            ],
          ),
        SizedBox(height: mobile ? 88 : 28),
      ],
    );
  }

  String _projectTitle(NegotiationThread thread) {
    final booking = thread.booking;
    if (booking.projectTitle.trim().isNotEmpty &&
        booking.projectTitle != 'Untitled project') {
      return booking.projectTitle;
    }
    return widget.projectTitles[booking.projectId] ??
        (booking.projectId.isEmpty ? 'Untitled production' : 'Project ${booking.projectId}');
  }
}

class _Hero extends StatelessWidget {
  final _BargainingPalette palette;
  final Animation<double> ambient;
  final Animation<double> sheen;
  final int open;
  final int yourMove;
  final int locked;
  final String liveValue;
  final VoidCallback onFindTalent;
  final VoidCallback onRefresh;
  final Animation<double> refreshSpin;
  final bool refreshing;
  final bool mobile;

  const _Hero({
    required this.palette,
    required this.ambient,
    required this.sheen,
    required this.open,
    required this.yourMove,
    required this.locked,
    required this.liveValue,
    required this.onFindTalent,
    required this.onRefresh,
    required this.refreshSpin,
    required this.refreshing,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleSize = mobile ? 36.0 : 46.0;
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.line),
            boxShadow: [palette.shadow],
          ),
          child: Stack(
            children: [
              Positioned.fill(child: _HeroWash(palette: palette)),
              for (var i = 0; i < _heroBubbles.length; i++)
                _DriftingBubble(
                  palette: palette,
                  animation: ambient,
                  spec: _heroBubbles[i],
                  phase: i * .78,
                  availableWidth: constraints.maxWidth,
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: sheen,
                      builder: (context, _) {
                        final x = -constraints.maxWidth * .7 +
                            sheen.value * constraints.maxWidth * 1.9;
                        return Transform.translate(
                          offset: Offset(x, 0),
                          child: Transform.rotate(
                            angle: -.18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: constraints.maxWidth * .25,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(
                                        alpha: palette.dark ? .07 : .28,
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  mobile ? 18 : 24,
                  mobile ? 20 : 24,
                  mobile ? 18 : 24,
                  mobile ? 16 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 16,
                      runSpacing: 14,
                      children: [
                        SizedBox(
                          width: mobile
                              ? math.max(0, constraints.maxWidth - 36)
                              : math.min(540, constraints.maxWidth * .62),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _GlowDot(color: palette.goldFill),
                                  const SizedBox(width: 7),
                                  Text(
                                    'DEALS · NEGOTIATION COMMAND',
                                    style: GoogleFonts.archivo(
                                      color: palette.gold,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.55,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'Bargaining',
                                style: GoogleFonts.newsreader(
                                  color: palette.ink,
                                  fontSize: titleSize,
                                  height: 1,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: -.5,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'Shape rates, terms and timing without losing the thread.',
                                style: GoogleFonts.archivo(
                                  color: palette.muted,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _LiveChip(palette: palette, ambient: ambient),
                            ],
                          ),
                        ),
                        _HeroActions(
                          palette: palette,
                          mobile: mobile,
                          onFindTalent: onFindTalent,
                          onRefresh: onRefresh,
                          refreshSpin: refreshSpin,
                          refreshing: refreshing,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _HeroStats(
                      palette: palette,
                      mobile: mobile,
                      stats: [
                        _HeroStatData('$open', 'Open threads'),
                        _HeroStatData('$yourMove', 'Your move'),
                        _HeroStatData('$locked', 'Locked'),
                        _HeroStatData(liveValue, 'Live offer value'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroActions extends StatelessWidget {
  final _BargainingPalette palette;
  final bool mobile;
  final VoidCallback onFindTalent;
  final VoidCallback onRefresh;
  final Animation<double> refreshSpin;
  final bool refreshing;

  const _HeroActions({
    required this.palette,
    required this.mobile,
    required this.onFindTalent,
    required this.onRefresh,
    required this.refreshSpin,
    required this.refreshing,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      _GlassButton(
        palette: palette,
        iconWidget: RotationTransition(
          turns: refreshSpin,
          child: Icon(Icons.refresh_rounded, color: palette.gold, size: 16),
        ),
        label: refreshing ? 'Refreshing…' : 'Refresh',
        onTap: refreshing ? null : onRefresh,
      ),
      _GoldButton(
        palette: palette,
        icon: Icons.manage_search_rounded,
        label: 'Find talent',
        onTap: onFindTalent,
      ),
    ];
    if (!mobile) {
      return Row(mainAxisSize: MainAxisSize.min, children: [children[0], const SizedBox(width: 8), children[1]]);
    }
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(child: children[0]),
          const SizedBox(width: 8),
          Expanded(child: children[1]),
        ],
      ),
    );
  }
}

class _HeroStats extends StatelessWidget {
  final _BargainingPalette palette;
  final bool mobile;
  final List<_HeroStatData> stats;

  const _HeroStats({required this.palette, required this.mobile, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
      decoration: BoxDecoration(
        color: palette.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.glassLine),
      ),
      child: mobile
          ? Wrap(
              runSpacing: 12,
              children: [
                for (var i = 0; i < stats.length; i++)
                  SizedBox(
                    width: (MediaQuery.sizeOf(context).width - 64) / 2,
                    child: _HeroStat(palette: palette, data: stats[i]),
                  ),
              ],
            )
          : Row(
              children: [
                for (final stat in stats)
                  Expanded(child: _HeroStat(palette: palette, data: stat)),
              ],
            ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final _BargainingPalette palette;
  final _HeroStatData data;

  const _HeroStat({required this.palette, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: palette.goldFill, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.archivo(
              color: palette.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -.35,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.archivo(color: palette.ink2, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _FilterCommandBar extends StatelessWidget {
  final _BargainingPalette palette;
  final List<String> filters;
  final String active;
  final TextEditingController queryController;
  final String query;
  final Animation<double> sheen;
  final Map<String, int> counts;
  final ValueChanged<String> onFilter;
  final ValueChanged<String> onQuery;
  final bool mobile;

  const _FilterCommandBar({
    required this.palette,
    required this.filters,
    required this.active,
    required this.queryController,
    required this.query,
    required this.sheen,
    required this.counts,
    required this.onFilter,
    required this.onQuery,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    final chips = _SlidingFilters(
      palette: palette,
      filters: filters,
      active: active,
      counts: counts,
      sheen: sheen,
      onChanged: onFilter,
    );
    final search = _SearchBox(
      palette: palette,
      controller: queryController,
      value: query,
      onChanged: onQuery,
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.line),
        boxShadow: [palette.shadow],
      ),
      child: mobile
          ? Column(
              children: [
                SizedBox(width: double.infinity, child: chips),
                const SizedBox(height: 7),
                SizedBox(width: double.infinity, child: search),
              ],
            )
          : Row(
              children: [
                Expanded(child: chips),
                const SizedBox(width: 8),
                SizedBox(width: 250, child: search),
              ],
            ),
    );
  }
}

class _SlidingFilters extends StatelessWidget {
  final _BargainingPalette palette;
  final List<String> filters;
  final String active;
  final Map<String, int> counts;
  final Animation<double> sheen;
  final ValueChanged<String> onChanged;

  const _SlidingFilters({
    required this.palette,
    required this.filters,
    required this.active,
    required this.counts,
    required this.sheen,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final widths = filters.map((label) => _chipWidth(label, counts[label] ?? 0)).toList();
    var activeLeft = 0.0;
    var activeWidth = widths.first;
    for (var i = 0; i < filters.length; i++) {
      if (filters[i] == active) {
        activeWidth = widths[i];
        break;
      }
      activeLeft += widths[i] + 4;
    }
    final totalWidth = widths.fold<double>(0, (sum, value) => sum + value) +
        math.max(0, widths.length - 1) * 4;

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          height: 42,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: const Cubic(.65, 0, .25, 1),
                left: activeLeft,
                top: 2,
                width: activeWidth,
                height: 34,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.goldLight.withValues(alpha: .50),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: palette.goldFill.withValues(alpha: .35),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: const Cubic(.65, 0, .25, 1),
                left: activeLeft,
                top: 2,
                width: activeWidth,
                height: 34,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [palette.goldLight, palette.goldFill],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: sheen,
                          builder: (context, _) {
                            final x = -activeWidth + sheen.value * activeWidth * 2.2;
                            return Transform.translate(
                              offset: Offset(x, 0),
                              child: Container(
                                width: activeWidth * .32,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: .78),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: const Cubic(.65, 0, .25, 1),
                left: activeLeft,
                bottom: 0,
                width: activeWidth,
                height: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.goldFill,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: palette.goldFill.withValues(alpha: .7),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < filters.length; i++) ...[
                    SizedBox(
                      width: widths[i],
                      height: 38,
                      child: InkWell(
                        onTap: () => onChanged(filters[i]),
                        borderRadius: BorderRadius.circular(999),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              filters[i],
                              style: GoogleFonts.archivo(
                                color: filters[i] == active
                                    ? palette.onGold
                                    : palette.ink2,
                                fontSize: 12,
                                fontWeight: filters[i] == active
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              constraints: const BoxConstraints(minWidth: 18),
                              height: 18,
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: filters[i] == active
                                    ? Colors.white.withValues(alpha: .45)
                                    : palette.goldSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${counts[filters[i]] ?? 0}',
                                style: GoogleFonts.archivo(
                                  color: filters[i] == active
                                      ? palette.onGold
                                      : palette.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i != filters.length - 1) const SizedBox(width: 4),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _chipWidth(String label, int count) {
    return (label.length * 7.0 + count.toString().length * 6 + 52)
        .clamp(86.0, 150.0)
        .toDouble();
  }
}

class _SearchBox extends StatelessWidget {
  final _BargainingPalette palette;
  final TextEditingController controller;
  final String value;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.palette,
    required this.controller,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: palette.card2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, color: palette.muted, size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.archivo(color: palette.ink, fontSize: 12),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Search deals, talent, projects…',
                hintStyle: GoogleFonts.archivo(color: palette.muted, fontSize: 11.5),
              ),
            ),
          ),
          if (value.isNotEmpty)
            InkWell(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              borderRadius: BorderRadius.circular(99),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close_rounded, color: palette.muted, size: 14),
              ),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _NegotiationList extends StatelessWidget {
  final _BargainingPalette palette;
  final List<NegotiationThread> items;
  final String Function(NegotiationThread) projectTitle;
  final String? hoveredId;
  final bool mobile;
  final Animation<double> entry;
  final ValueChanged<String?> onHover;
  final ValueChanged<String> onOpen;
  final VoidCallback onFindTalent;
  final bool queryActive;

  const _NegotiationList({
    required this.palette,
    required this.items,
    required this.projectTitle,
    required this.hoveredId,
    required this.mobile,
    required this.entry,
    required this.onHover,
    required this.onOpen,
    required this.onFindTalent,
    required this.queryActive,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyPanel(
        palette: palette,
        title: queryActive ? 'No matching negotiations' : 'No negotiations yet',
        message: queryActive
            ? 'Try another status or search term.'
            : 'Open Marketplace and send a booking request to start bargaining.',
        button: queryActive ? null : 'Find talent',
        onTap: queryActive ? null : onFindTalent,
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _EntryReveal(
            animation: entry,
            index: i,
            total: items.length,
            child: _NegotiationCard(
              palette: palette,
              thread: items[i],
              projectTitle: projectTitle(items[i]),
              hovered: hoveredId == items[i].publicId,
              dimmed: hoveredId != null && hoveredId != items[i].publicId,
              mobile: mobile,
              onHover: onHover,
              onOpen: () => onOpen(items[i].publicId),
            ),
          ),
          if (i != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _EntryReveal extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final int total;
  final Widget child;

  const _EntryReveal({
    required this.animation,
    required this.index,
    required this.total,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index * .06).clamp(0.0, .55).toDouble();
    final end = (start + .45).clamp(.45, 1.0).toDouble();
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: const Cubic(.2, .8, .2, 1)),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: Transform.scale(scale: .985 + .015 * t, child: child),
          ),
        );
      },
    );
  }
}

class _NegotiationCard extends StatelessWidget {
  final _BargainingPalette palette;
  final NegotiationThread thread;
  final String projectTitle;
  final bool hovered;
  final bool dimmed;
  final bool mobile;
  final ValueChanged<String?> onHover;
  final VoidCallback onOpen;

  const _NegotiationCard({
    required this.palette,
    required this.thread,
    required this.projectTitle,
    required this.hovered,
    required this.dimmed,
    required this.mobile,
    required this.onHover,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final booking = thread.booking;
    final stage = _dealStage(thread);
    final tone = _DealTone.forStage(stage, palette);
    final offer = thread.currentOffer;
    final initials = _initials(booking.provider.displayName);
    final requirement = booking.requirementTitle?.trim().isNotEmpty == true
        ? booking.requirementTitle!
        : _titleCase(booking.category);
    final conditions = offer?.conditions?.trim();
    final rounds = math.max(thread.rounds.length, offer?.revision ?? 0);
    final expiry = _expiryLabel(offer?.expiresAt ?? booking.expiresAt);
    final dates = '${_shortDate(booking.startAt)} – ${_shortDate(booking.endAt)}';

    return MouseRegion(
      onEnter: (_) => onHover(thread.publicId),
      onExit: (_) => onHover(null),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: dimmed ? .66 : 1,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 400),
          curve: const Cubic(.2, .9, .25, 1),
          scale: hovered ? 1.018 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: const Cubic(.2, .9, .25, 1),
            padding: EdgeInsets.all(mobile ? 12 : 14),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hovered ? palette.goldFill : palette.line,
              ),
              boxShadow: [
                palette.shadow,
                if (hovered)
                  BoxShadow(
                    color: palette.goldFill.withValues(alpha: .24),
                    blurRadius: 28,
                    spreadRadius: -8,
                  ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: tone.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Avatar(
                            palette: palette,
                            initials: initials,
                            tone: tone,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        booking.provider.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.archivo(
                                          color: palette.ink,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _StatusPill(
                                      palette: palette,
                                      stage: stage,
                                      tone: tone,
                                      pulse: stage == 'Your move',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$projectTitle · $requirement',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.archivo(
                                    color: palette.muted,
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 5,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _SoftTag(
                                      palette: palette,
                                      text: _titleCase(booking.category),
                                      tone: tone,
                                    ),
                                    _MetaChip(
                                      palette: palette,
                                      icon: Icons.location_on_outlined,
                                      text: booking.projectCity ?? 'Location TBD',
                                    ),
                                    _MetaChip(
                                      palette: palette,
                                      icon: Icons.calendar_month_outlined,
                                      text: dates,
                                    ),
                                    _MetaChip(
                                      palette: palette,
                                      icon: Icons.repeat_rounded,
                                      text: '$rounds ${rounds == 1 ? 'round' : 'rounds'}',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: palette.holo,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: palette.glassLine),
                        ),
                        child: mobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _OfferBlock(
                                    palette: palette,
                                    fee: offer?.feeLabel ?? 'Rate TBD',
                                    expiry: expiry,
                                  ),
                                  const SizedBox(height: 9),
                                  _RoundLadder(
                                    palette: palette,
                                    thread: thread,
                                    tone: tone,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _OfferBlock(
                                      palette: palette,
                                      fee: offer?.feeLabel ?? 'Rate TBD',
                                      expiry: expiry,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 42,
                                    color: palette.goldLine,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    flex: 3,
                                    child: _RoundLadder(
                                      palette: palette,
                                      thread: thread,
                                      tone: tone,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      if (conditions != null && conditions.isNotEmpty) ...[
                        const SizedBox(height: 9),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.notes_rounded, size: 14, color: palette.muted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                conditions,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.archivo(
                                  color: palette.ink2,
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 11),
                      if (mobile)
                        SizedBox(
                          width: double.infinity,
                          child: _GoldButton(
                            palette: palette,
                            icon: Icons.forum_outlined,
                            label: 'Open deal room',
                            onTap: onOpen,
                          ),
                        )
                      else
                        Row(
                          children: [
                            Text(
                              thread.publicId,
                              style: GoogleFonts.archivo(
                                color: palette.muted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .45,
                              ),
                            ),
                            const Spacer(),
                            _GlassButton(
                              palette: palette,
                              icon: Icons.timeline_rounded,
                              label: 'History',
                              onTap: onOpen,
                            ),
                            const SizedBox(width: 7),
                            _GoldButton(
                              palette: palette,
                              icon: Icons.forum_outlined,
                              label: 'Open deal room',
                              onTap: onOpen,
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
      ),
    );
  }
}

class _OfferBlock extends StatelessWidget {
  final _BargainingPalette palette;
  final String fee;
  final String expiry;

  const _OfferBlock({required this.palette, required this.fee, required this.expiry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURRENT OFFER',
          style: GoogleFonts.archivo(
            color: palette.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          fee,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.newsreader(
            color: palette.ink,
            fontSize: 23,
            fontWeight: FontWeight.w600,
            letterSpacing: -.35,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(Icons.schedule_rounded, size: 12, color: palette.gold),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                expiry,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.archivo(
                  color: palette.ink2,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundLadder extends StatelessWidget {
  final _BargainingPalette palette;
  final NegotiationThread thread;
  final _DealTone tone;

  const _RoundLadder({required this.palette, required this.thread, required this.tone});

  @override
  Widget build(BuildContext context) {
    final rounds = thread.rounds;
    final visible = rounds.length <= 4 ? rounds : rounds.sublist(rounds.length - 4);
    if (visible.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OFFER FLOW',
            style: GoogleFonts.archivo(
              color: palette.muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Waiting for the first revision.',
            style: GoogleFonts.archivo(color: palette.ink2, fontSize: 11),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'OFFER FLOW',
              style: GoogleFonts.archivo(
                color: palette.muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
            const Spacer(),
            Text(
              'R${rounds.length}',
              style: GoogleFonts.archivo(
                color: palette.gold,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: i == visible.length - 1 ? tone.line : palette.goldSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: tone.line),
                        boxShadow: i == visible.length - 1
                            ? [BoxShadow(color: tone.line.withValues(alpha: .45), blurRadius: 8)]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      visible[i].offer.feeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.archivo(
                        color: i == visible.length - 1 ? palette.ink : palette.muted,
                        fontSize: 9.5,
                        fontWeight: i == visible.length - 1 ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (i != visible.length - 1)
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: palette.goldLine,
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DealPulsePanel extends StatelessWidget {
  final _BargainingPalette palette;
  final List<NegotiationThread> negotiations;
  final bool horizontal;
  final Animation<double> ambient;
  final ValueChanged<String> onOpen;

  const _DealPulsePanel({
    required this.palette,
    required this.negotiations,
    required this.horizontal,
    required this.ambient,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final yourMove = negotiations.where((e) => _dealStage(e) == 'Your move').length;
    final replied = negotiations.where((e) => _dealStage(e) == 'Replied').length;
    final locked = negotiations.where(_isLocked).length;
    final urgent = negotiations
        .where((e) => _dealStage(e) == 'Your move')
        .take(3)
        .toList();

    final cards = <Widget>[
      _PulseMetric(
        palette: palette,
        ambient: ambient,
        index: 0,
        icon: Icons.bolt_rounded,
        label: 'Your move',
        value: '$yourMove',
        tone: _DealTone.warning(palette),
      ),
      _PulseMetric(
        palette: palette,
        ambient: ambient,
        index: 1,
        icon: Icons.mark_chat_unread_outlined,
        label: 'Awaiting reply',
        value: '$replied',
        tone: _DealTone.info(palette),
      ),
      _PulseMetric(
        palette: palette,
        ambient: ambient,
        index: 2,
        icon: Icons.verified_rounded,
        label: 'Locked',
        value: '$locked',
        tone: _DealTone.success(palette),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.line),
        boxShadow: [palette.shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Deal pulse',
                style: GoogleFonts.newsreader(
                  color: palette.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _GlowDot(color: palette.goldFill),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: GoogleFonts.archivo(
                  color: palette.gold,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (horizontal)
            SizedBox(
              height: 94,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => SizedBox(width: 190, child: cards[index]),
              ),
            )
          else
            for (var i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i != cards.length - 1) const SizedBox(height: 8),
            ],
          if (!horizontal) ...[
            const SizedBox(height: 14),
            Text(
              'Needs attention',
              style: GoogleFonts.archivo(
                color: palette.muted,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            if (urgent.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, color: palette.gold, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No deal is waiting on you right now.',
                        style: GoogleFonts.archivo(color: palette.ink2, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (var i = 0; i < urgent.length; i++) ...[
                _UrgentDealRow(
                  palette: palette,
                  thread: urgent[i],
                  onTap: () => onOpen(urgent[i].publicId),
                ),
                if (i != urgent.length - 1) const SizedBox(height: 6),
              ],
          ],
        ],
      ),
    );
  }
}

class _PulseMetric extends StatelessWidget {
  final _BargainingPalette palette;
  final Animation<double> ambient;
  final int index;
  final IconData icon;
  final String label;
  final String value;
  final _DealTone tone;

  const _PulseMetric({
    required this.palette,
    required this.ambient,
    required this.index,
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, _) {
        final a = (ambient.value + index * .21) * math.pi * 2;
        return Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(math.sin(a), math.cos(a)),
              end: Alignment(-math.sin(a), -math.cos(a)),
              colors: palette.holo,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.glassLine),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tone.soft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: tone.ink, size: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.newsreader(
                        color: palette.ink,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.archivo(
                        color: palette.ink2,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UrgentDealRow extends StatelessWidget {
  final _BargainingPalette palette;
  final NegotiationThread thread;
  final VoidCallback onTap;

  const _UrgentDealRow({required this.palette, required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: palette.card2,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: palette.line),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: palette.peachSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(thread.booking.provider.displayName),
                style: GoogleFonts.newsreader(
                  color: palette.peachInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.booking.provider.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.archivo(
                      color: palette.ink,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    thread.currentOffer?.feeLabel ?? 'Rate TBD',
                    style: GoogleFonts.archivo(
                      color: palette.gold,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.gold, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final _BargainingPalette palette;
  final String initials;
  final _DealTone tone;

  const _Avatar({required this.palette, required this.initials, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.soft, palette.card2],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: tone.line.withValues(alpha: .55)),
      ),
      child: Text(
        initials,
        style: GoogleFonts.newsreader(
          color: tone.ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusPill extends StatefulWidget {
  final _BargainingPalette palette;
  final String stage;
  final _DealTone tone;
  final bool pulse;

  const _StatusPill({
    required this.palette,
    required this.stage,
    required this.tone,
    required this.pulse,
  });

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _StatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulse != widget.pulse) {
      _pulse?.dispose();
      _pulse = null;
      if (widget.pulse) {
        _pulse = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1800),
        )..repeat();
      }
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final core = Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.tone.soft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: widget.tone.line.withValues(alpha: .55)),
      ),
      child: Text(
        widget.stage,
        style: GoogleFonts.archivo(
          color: widget.tone.ink,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: .3,
        ),
      ),
    );
    if (_pulse == null) return core;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _pulse!,
          builder: (context, _) {
            final t = _pulse!.value;
            return Transform.scale(
              scale: 1 + t * .28,
              child: Opacity(
                opacity: (1 - t) * .5,
                child: Container(
                  height: 22,
                  width: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: widget.tone.line),
                  ),
                ),
              ),
            );
          },
        ),
        core,
      ],
    );
  }
}

class _SoftTag extends StatelessWidget {
  final _BargainingPalette palette;
  final String text;
  final _DealTone tone;

  const _SoftTag({required this.palette, required this.text, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.archivo(
          color: tone.ink,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final _BargainingPalette palette;
  final IconData icon;
  final String text;

  const _MetaChip({required this.palette, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: palette.muted),
        const SizedBox(width: 3),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.archivo(color: palette.ink2, fontSize: 10.5),
          ),
        ),
      ],
    );
  }
}

class _LiveChip extends StatelessWidget {
  final _BargainingPalette palette;
  final Animation<double> ambient;

  const _LiveChip({required this.palette, required this.ambient});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, _) {
        final a = ambient.value * math.pi * 2;
        return Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(math.cos(a), math.sin(a)),
              end: Alignment(-math.cos(a), -math.sin(a)),
              colors: palette.holo,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.glassLine),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GlowDot(color: const Color(0xFF70C68B)),
              const SizedBox(width: 7),
              Text(
                'Live bargaining room',
                style: GoogleFonts.archivo(
                  color: palette.ink2,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GoldButton extends StatelessWidget {
  final _BargainingPalette palette;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _GoldButton({
    required this.palette,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? .5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [palette.goldLight, palette.goldFill]),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: palette.goldFill.withValues(alpha: .35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -9,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: palette.onGold, size: 15),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: GoogleFonts.archivo(
                    color: palette.onGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

class _GlassButton extends StatelessWidget {
  final _BargainingPalette palette;
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final VoidCallback? onTap;

  const _GlassButton({
    required this.palette,
    this.icon,
    this.iconWidget,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? .5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: palette.glass,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: palette.goldLine),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget ?? Icon(icon, color: palette.gold, size: 15),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.archivo(
                    color: palette.gold,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
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

class _LoadingPanel extends StatelessWidget {
  final _BargainingPalette palette;

  const _LoadingPanel({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.line),
      ),
      child: Center(child: CircularProgressIndicator(color: palette.gold)),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final _BargainingPalette palette;
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.palette, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _EmptyPanel(
      palette: palette,
      title: 'Negotiations unavailable',
      message: message,
      button: 'Retry',
      onTap: onRetry,
      icon: Icons.cloud_off_rounded,
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final _BargainingPalette palette;
  final String title;
  final String message;
  final String? button;
  final VoidCallback? onTap;
  final IconData icon;

  const _EmptyPanel({
    required this.palette,
    required this.title,
    required this.message,
    required this.button,
    required this.onTap,
    this.icon = Icons.forum_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 38),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.goldLine),
        boxShadow: [palette.shadow],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: palette.holo),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.glassLine),
            ),
            child: Icon(icon, color: palette.gold, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.newsreader(
              color: palette.ink,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.archivo(color: palette.muted, fontSize: 12),
          ),
          if (button != null && onTap != null) ...[
            const SizedBox(height: 13),
            _GoldButton(
              palette: palette,
              icon: Icons.arrow_forward_rounded,
              label: button!,
              onTap: onTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroWash extends StatelessWidget {
  final _BargainingPalette palette;

  const _HeroWash({required this.palette});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: palette.dark
              ? [
                  const Color(0xFF14202A).withValues(alpha: .38),
                  Colors.transparent,
                  const Color(0xFF332D46).withValues(alpha: .26),
                  const Color(0xFF3C3320).withValues(alpha: .20),
                ]
              : [
                  const Color(0xFFDDEBF5).withValues(alpha: .70),
                  Colors.white.withValues(alpha: .25),
                  const Color(0xFFE7E0F7).withValues(alpha: .62),
                  const Color(0xFFF4E9CC).withValues(alpha: .72),
                ],
        ),
      ),
    );
  }
}

class _DriftingBubble extends StatelessWidget {
  final _BargainingPalette palette;
  final Animation<double> animation;
  final _BubbleSpec spec;
  final double phase;
  final double availableWidth;

  const _DriftingBubble({
    required this.palette,
    required this.animation,
    required this.spec,
    required this.phase,
    required this.availableWidth,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final a = animation.value * math.pi * 2 * spec.speed + phase;
        final dx = math.sin(a) * spec.dx;
        final dy = math.cos(a * .83) * spec.dy;
        return Positioned(
          left: spec.left * availableWidth,
          top: spec.top * 190,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: IgnorePointer(
              child: Container(
                width: spec.size,
                height: spec.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-.36, -.44),
                    colors: palette.bubble,
                    stops: const [0, .18, .44, .66, 1],
                  ),
                  border: Border.all(color: palette.bubbleBorder),
                  boxShadow: [
                    BoxShadow(
                      color: palette.goldFill.withValues(alpha: .08),
                      blurRadius: 10,
                      offset: const Offset(-2, -2),
                    ),
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

class _GlowDot extends StatelessWidget {
  final Color color;

  const _GlowDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .65), blurRadius: 10, spreadRadius: 2),
        ],
      ),
    );
  }
}

class _DealTone {
  final Color soft;
  final Color ink;
  final Color line;

  const _DealTone({required this.soft, required this.ink, required this.line});

  static _DealTone forStage(String stage, _BargainingPalette palette) {
    return switch (stage) {
      'Your move' => warning(palette),
      'Replied' => info(palette),
      'Locked' => success(palette),
      'Closed' => danger(palette),
      _ => info(palette),
    };
  }

  static _DealTone warning(_BargainingPalette p) =>
      _DealTone(soft: p.sandSoft, ink: p.sandInk, line: p.sandLine);
  static _DealTone info(_BargainingPalette p) =>
      _DealTone(soft: p.iceSoft, ink: p.iceInk, line: p.iceLine);
  static _DealTone success(_BargainingPalette p) =>
      _DealTone(soft: p.mintSoft, ink: p.mintInk, line: p.mintLine);
  static _DealTone danger(_BargainingPalette p) =>
      _DealTone(soft: p.peachSoft, ink: p.peachInk, line: p.peachLine);
}

class _BargainingPalette {
  final bool dark;
  final Color card;
  final Color card2;
  final Color line;
  final Color goldLine;
  final Color ink;
  final Color ink2;
  final Color muted;
  final Color gold;
  final Color goldFill;
  final Color goldLight;
  final Color onGold;
  final Color goldSoft;
  final Color glass;
  final Color glassLine;
  final Color sheet;
  final Color iceSoft;
  final Color mintSoft;
  final Color peachSoft;
  final Color sandSoft;
  final Color iceInk;
  final Color mintInk;
  final Color peachInk;
  final Color sandInk;
  final Color iceLine;
  final Color mintLine;
  final Color peachLine;
  final Color sandLine;
  final List<Color> holo;
  final List<Color> bubble;
  final Color bubbleBorder;
  final BoxShadow shadow;

  const _BargainingPalette({
    required this.dark,
    required this.card,
    required this.card2,
    required this.line,
    required this.goldLine,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.gold,
    required this.goldFill,
    required this.goldLight,
    required this.onGold,
    required this.goldSoft,
    required this.glass,
    required this.glassLine,
    required this.sheet,
    required this.iceSoft,
    required this.mintSoft,
    required this.peachSoft,
    required this.sandSoft,
    required this.iceInk,
    required this.mintInk,
    required this.peachInk,
    required this.sandInk,
    required this.iceLine,
    required this.mintLine,
    required this.peachLine,
    required this.sandLine,
    required this.holo,
    required this.bubble,
    required this.bubbleBorder,
    required this.shadow,
  });

  static _BargainingPalette of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return _BargainingPalette(
        dark: true,
        card: const Color(0xFF131316),
        card2: const Color(0xFF17171B),
        line: Colors.white.withValues(alpha: .08),
        goldLine: const Color(0xFFE5C46E).withValues(alpha: .32),
        ink: const Color(0xFFF3F0E7),
        ink2: const Color(0xFFC6C0B0),
        muted: const Color(0xFF8B8677),
        gold: const Color(0xFFE5C46E),
        goldFill: const Color(0xFFD4AF37),
        goldLight: const Color(0xFFEDD48A),
        onGold: const Color(0xFF16120A),
        goldSoft: const Color(0xFFD4AF37).withValues(alpha: .13),
        glass: Colors.white.withValues(alpha: .05),
        glassLine: Colors.white.withValues(alpha: .12),
        sheet: const Color(0xFF141418),
        iceSoft: const Color(0xFF8FC2E6).withValues(alpha: .12),
        mintSoft: const Color(0xFF8FD3A9).withValues(alpha: .12),
        peachSoft: const Color(0xFFE8AE94).withValues(alpha: .12),
        sandSoft: const Color(0xFFDCC27A).withValues(alpha: .12),
        iceInk: const Color(0xFFA9D4F2),
        mintInk: const Color(0xFFA8E0C0),
        peachInk: const Color(0xFFF2C6B2),
        sandInk: const Color(0xFFE8D08E),
        iceLine: const Color(0xFF8FC2E6),
        mintLine: const Color(0xFF8FD3A9),
        peachLine: const Color(0xFFE8AE94),
        sandLine: const Color(0xFFDCC27A),
        holo: [
          Colors.white.withValues(alpha: .08),
          const Color(0xFF8CBEFF).withValues(alpha: .12),
          const Color(0xFFBEA0FF).withValues(alpha: .10),
          const Color(0xFFFFCD96).withValues(alpha: .12),
        ],
        bubble: [
          Colors.white.withValues(alpha: .70),
          const Color(0xFFBEDFFF).withValues(alpha: .28),
          const Color(0xFFCDBEFF).withValues(alpha: .16),
          const Color(0xFFFFCDB4).withValues(alpha: .10),
          Colors.white.withValues(alpha: .02),
        ],
        bubbleBorder: const Color(0xFFD2E6FF).withValues(alpha: .30),
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: .42),
          blurRadius: 30,
          offset: const Offset(0, 16),
          spreadRadius: -18,
        ),
      );
    }
    return _BargainingPalette(
      dark: false,
      card: Colors.white,
      card2: const Color(0xFFFBFAF6),
      line: const Color(0xFF17150E).withValues(alpha: .08),
      goldLine: const Color(0xFFB08A26).withValues(alpha: .35),
      ink: const Color(0xFF17150E),
      ink2: const Color(0xFF4A463B),
      muted: const Color(0xFF8A8475),
      gold: const Color(0xFF9C7614),
      goldFill: const Color(0xFFD3B55F),
      goldLight: const Color(0xFFEBD48F),
      onGold: const Color(0xFF1A1408),
      goldSoft: const Color(0xFFF8F1DE),
      glass: Colors.white.withValues(alpha: .62),
      glassLine: Colors.white.withValues(alpha: .95),
      sheet: Colors.white.withValues(alpha: .94),
      iceSoft: const Color(0xFFEEF6FC),
      mintSoft: const Color(0xFFEEF8F1),
      peachSoft: const Color(0xFFFCF1EB),
      sandSoft: const Color(0xFFFAF4E3),
      iceInk: const Color(0xFF3F6E8F),
      mintInk: const Color(0xFF3C7A55),
      peachInk: const Color(0xFFA0593C),
      sandInk: const Color(0xFF8A6A18),
      iceLine: const Color(0xFFA9D0EC),
      mintLine: const Color(0xFFA9DDBC),
      peachLine: const Color(0xFFEFC3AE),
      sandLine: const Color(0xFFE6D196),
      holo: [
        Colors.white.withValues(alpha: .88),
        const Color(0xFFD2EAFF).withValues(alpha: .68),
        const Color(0xFFECDFFF).withValues(alpha: .62),
        const Color(0xFFFFECD6).withValues(alpha: .72),
      ],
      bubble: [
        Colors.white.withValues(alpha: .98),
        const Color(0xFFD6ECFF).withValues(alpha: .50),
        const Color(0xFFE4DCFF).withValues(alpha: .32),
        const Color(0xFFFFE2CE).withValues(alpha: .20),
        Colors.white.withValues(alpha: 0),
      ],
      bubbleBorder: Colors.white.withValues(alpha: .90),
      shadow: BoxShadow(
        color: const Color(0xFF16130A).withValues(alpha: .13),
        blurRadius: 30,
        offset: const Offset(0, 14),
        spreadRadius: -20,
      ),
    );
  }
}

class _HeroStatData {
  final String value;
  final String label;

  const _HeroStatData(this.value, this.label);
}

class _BubbleSpec {
  final double left;
  final double top;
  final double size;
  final double speed;
  final double dx;
  final double dy;

  const _BubbleSpec(this.left, this.top, this.size, this.speed, this.dx, this.dy);
}

const _heroBubbles = <_BubbleSpec>[
  _BubbleSpec(.52, .10, 34, .92, 12, 18),
  _BubbleSpec(.64, .58, 14, 1.08, 10, 14),
  _BubbleSpec(.91, .06, 48, .78, 13, 17),
  _BubbleSpec(.40, .20, 10, 1.18, 9, 12),
  _BubbleSpec(.80, .44, 20, .98, 11, 16),
  _BubbleSpec(.24, .08, 12, 1.24, 8, 13),
  _BubbleSpec(.72, .16, 16, .85, 12, 15),
];

String _dealStage(NegotiationThread thread) {
  if (_isLocked(thread)) return 'Locked';
  if (_isClosed(thread)) return 'Closed';
  final current = thread.currentOffer;
  if (current == null) return 'Your move';
  final providerId = thread.booking.provider.publicId;
  if (providerId.isNotEmpty && current.sender.publicId == providerId) {
    return 'Your move';
  }
  return 'Replied';
}

bool _isLocked(NegotiationThread thread) {
  final status = thread.status.toLowerCase();
  final booking = thread.booking.status.toLowerCase();
  return status == 'accepted' ||
      status == 'locked' ||
      thread.lockedAt != null ||
      booking == 'accepted' ||
      booking == 'secured';
}

bool _isClosed(NegotiationThread thread) {
  final status = thread.status.toLowerCase();
  final booking = thread.booking.status.toLowerCase();
  return status == 'rejected' ||
      status == 'closed' ||
      status == 'cancelled' ||
      booking == 'rejected' ||
      booking == 'cancelled';
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'CC';
  if (parts.length == 1) {
    final word = parts.first;
    return word.substring(0, math.min(2, word.length)).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _shortDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _expiryLabel(DateTime? date) {
  if (date == null) return 'No expiry set';
  final diff = date.difference(DateTime.now());
  if (diff.isNegative) return 'Expired';
  if (diff.inMinutes < 60) return '${math.max(1, diff.inMinutes)}m left';
  if (diff.inHours < 24) return '${diff.inHours}h left';
  if (diff.inDays <= 7) return '${diff.inDays}d left';
  return 'Expires ${_shortDate(date)}';
}

String _moneyCompact(int amount) {
  if (amount >= 10000000) return 'PKR ${(amount / 10000000).toStringAsFixed(1)}Cr';
  if (amount >= 100000) return 'PKR ${(amount / 100000).toStringAsFixed(1)}L';
  if (amount >= 1000) return 'PKR ${(amount / 1000).toStringAsFixed(0)}k';
  return 'PKR $amount';
}
