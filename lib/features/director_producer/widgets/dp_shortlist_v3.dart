import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/marketplace/marketplace_models.dart';

class DPShortlistV3 extends StatefulWidget {
  final bool loading;
  final String? error;
  final String? notice;
  final MarketplaceShortlistBundle? bundle;
  final String? activeBoardId;
  final String? mutatingId;
  final Set<String> checkedIds;
  final Map<String, bool> alertState;
  final Map<String, int> rankBumps;
  final VoidCallback onRetry;
  final VoidCallback onDiscover;
  final VoidCallback onCreateShortlist;
  final ValueChanged<String> onBoardChanged;
  final void Function(String id, bool checked) onCheckItem;
  final VoidCallback onToggleAll;
  final ValueChanged<MarketplaceShortlistItem> onMoveUp;
  final ValueChanged<MarketplaceShortlistItem> onMoveDown;
  final ValueChanged<MarketplaceShortlistItem> onToggleSelect;
  final ValueChanged<MarketplaceShortlistItem> onRemoveItem;
  final VoidCallback onSelectChecked;
  final VoidCallback onRemoveChecked;
  final VoidCallback onClearChecked;
  final ValueChanged<MarketplaceSavedSearch> onToggleAlert;
  final ValueChanged<MarketplaceSavedSearch> onRunSearch;
  final ValueChanged<MarketplaceSavedSearch> onDeleteSearch;

  const DPShortlistV3({
    super.key,
    required this.loading,
    required this.error,
    required this.notice,
    required this.bundle,
    required this.activeBoardId,
    required this.mutatingId,
    required this.checkedIds,
    required this.alertState,
    required this.rankBumps,
    required this.onRetry,
    required this.onDiscover,
    required this.onCreateShortlist,
    required this.onBoardChanged,
    required this.onCheckItem,
    required this.onToggleAll,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onToggleSelect,
    required this.onRemoveItem,
    required this.onSelectChecked,
    required this.onRemoveChecked,
    required this.onClearChecked,
    required this.onToggleAlert,
    required this.onRunSearch,
    required this.onDeleteSearch,
  });

  @override
  State<DPShortlistV3> createState() => _DPShortlistV3State();
}

class _DPShortlistV3State extends State<DPShortlistV3>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _sheen;
  String? _hoveredId;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(covariant DPShortlistV3 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeBoardId != widget.activeBoardId) {
      _sheen.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _ShortlistPalette.of(context);
    final bundle = widget.bundle;
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 720;
    final compact = width < 980;

    if (widget.loading) {
      return _LoadingPanel(palette: palette);
    }
    if (widget.error != null) {
      return _ErrorPanel(
        palette: palette,
        message: widget.error!,
        onRetry: widget.onRetry,
      );
    }

    final live = bundle ?? const MarketplaceShortlistBundle(
      savedSearches: <MarketplaceSavedSearch>[],
      shortlists: <MarketplaceShortlist>[],
    );
    final activeBoard = _findActiveBoard(live.shortlists);
    final total = live.shortlists.fold<int>(0, (sum, board) => sum + board.items.length);
    final selected = live.shortlists.fold<int>(
      0,
      (sum, board) => sum + board.items.where((item) => item.status == 'selected').length,
    );
    final alerts = live.savedSearches.where((search) {
      return widget.alertState[search.publicId] ?? search.notifyEnabled;
    }).length;

    final content = SingleChildScrollView(
      padding: EdgeInsets.only(bottom: mobile ? 126 : 92),
      child: Column(
        children: [
          _Hero(
            palette: palette,
            ambient: _ambient,
            total: total,
            selected: selected,
            savedSearches: live.savedSearches.length,
            alertsOn: alerts,
            onDiscover: widget.onDiscover,
            onNewShortlist: widget.onCreateShortlist,
            creating: widget.mutatingId == '__new__',
          ),
          const SizedBox(height: 12),
          if (widget.notice != null) ...[
            _NoticeBar(palette: palette, text: widget.notice!),
            const SizedBox(height: 12),
          ],
          if (compact) ...[
            _SavedSearchPanel(
              palette: palette,
              searches: live.savedSearches,
              horizontal: true,
              alertState: widget.alertState,
              mutatingId: widget.mutatingId,
              onToggleAlert: widget.onToggleAlert,
              onRun: widget.onRunSearch,
              onRemove: widget.onDeleteSearch,
              onDiscover: widget.onDiscover,
              ambient: _ambient,
            ),
            const SizedBox(height: 12),
            _BoardPanel(
              palette: palette,
              boards: live.shortlists,
              activeBoard: activeBoard,
              checkedIds: widget.checkedIds,
              rankBumps: widget.rankBumps,
              mutatingId: widget.mutatingId,
              hoveredId: _hoveredId,
              mobile: mobile,
              sheen: _sheen,
              onHover: (id) => setState(() => _hoveredId = id),
              onBoardChanged: widget.onBoardChanged,
              onToggleAll: widget.onToggleAll,
              onCheckItem: widget.onCheckItem,
              onMoveUp: widget.onMoveUp,
              onMoveDown: widget.onMoveDown,
              onToggleSelect: widget.onToggleSelect,
              onRemove: widget.onRemoveItem,
              onDiscover: widget.onDiscover,
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _BoardPanel(
                    palette: palette,
                    boards: live.shortlists,
                    activeBoard: activeBoard,
                    checkedIds: widget.checkedIds,
                    rankBumps: widget.rankBumps,
                    mutatingId: widget.mutatingId,
                    hoveredId: _hoveredId,
                    mobile: false,
                    sheen: _sheen,
                    onHover: (id) => setState(() => _hoveredId = id),
                    onBoardChanged: widget.onBoardChanged,
                    onToggleAll: widget.onToggleAll,
                    onCheckItem: widget.onCheckItem,
                    onMoveUp: widget.onMoveUp,
                    onMoveDown: widget.onMoveDown,
                    onToggleSelect: widget.onToggleSelect,
                    onRemove: widget.onRemoveItem,
                    onDiscover: widget.onDiscover,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 320,
                  child: _SavedSearchPanel(
                    palette: palette,
                    searches: live.savedSearches,
                    horizontal: false,
                    alertState: widget.alertState,
                    mutatingId: widget.mutatingId,
                    onToggleAlert: widget.onToggleAlert,
                    onRun: widget.onRunSearch,
                    onRemove: widget.onDeleteSearch,
                    onDiscover: widget.onDiscover,
                    ambient: _ambient,
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    return Stack(
      children: [
        Positioned.fill(child: content),
        if (widget.checkedIds.isNotEmpty)
          Positioned(
            left: mobile ? 10 : 24,
            right: mobile ? 10 : 24,
            bottom: mobile ? 8 : 20,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _BulkBar(
                palette: palette,
                count: widget.checkedIds.length,
                busy: widget.mutatingId == '__bulk_select__' ||
                    widget.mutatingId == '__bulk_remove__',
                mobile: mobile,
                onSelectAll: widget.onSelectChecked,
                onRemove: widget.onRemoveChecked,
                onClear: widget.onClearChecked,
              ),
            ),
          ),
      ],
    );
  }

  MarketplaceShortlist? _findActiveBoard(List<MarketplaceShortlist> boards) {
    if (boards.isEmpty) return null;
    for (final board in boards) {
      if (board.publicId == widget.activeBoardId) return board;
    }
    return boards.first;
  }
}

class _Hero extends StatelessWidget {
  final _ShortlistPalette palette;
  final Animation<double> ambient;
  final int total;
  final int selected;
  final int savedSearches;
  final int alertsOn;
  final VoidCallback onDiscover;
  final VoidCallback onNewShortlist;
  final bool creating;

  const _Hero({
    required this.palette,
    required this.ambient,
    required this.total,
    required this.selected,
    required this.savedSearches,
    required this.alertsOn,
    required this.onDiscover,
    required this.onNewShortlist,
    required this.creating,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 720;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.line),
          boxShadow: [palette.shadow],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
          children: [
            Positioned.fill(child: _HeroWash(palette: palette)),
            ..._heroBubbles.asMap().entries.map(
              (entry) => _DriftingBubble(
                palette: palette,
                animation: ambient,
                spec: entry.value,
                phase: entry.key * 0.87,
                availableWidth: constraints.maxWidth,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: ambient,
                  builder: (context, _) {
                    final x = -1.7 + ambient.value * 3.4;
                    return Transform.translate(
                      offset: Offset(x * MediaQuery.sizeOf(context).width * .36, 0),
                      child: Transform.rotate(
                        angle: -.19,
                        child: Container(
                          width: 130,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: palette.dark ? .06 : .20),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(mobile ? 16 : 22),
              child: Column(
                children: [
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      SizedBox(
                        width: mobile ? double.infinity : 500,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _GlowDot(color: palette.goldFill),
                                const SizedBox(width: 7),
                                Text(
                                  'SHORTLISTS · SAVED TALENT',
                                  style: GoogleFonts.archivo(
                                    color: palette.gold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.6,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Shortlist',
                              style: GoogleFonts.newsreader(
                                color: palette.ink,
                                fontSize: mobile ? 31 : 39,
                                height: 1.02,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -.4,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Rank, compare and lock talent for each production.',
                              style: GoogleFonts.archivo(
                                color: palette.muted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!mobile) const SizedBox(width: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _GlassPillButton(
                            palette: palette,
                            icon: Icons.add_rounded,
                            label: creating ? 'Creating…' : 'New shortlist',
                            onTap: creating ? null : onNewShortlist,
                          ),
                          _GoldPillButton(
                            palette: palette,
                            icon: Icons.manage_search_rounded,
                            label: 'Discover',
                            onTap: onDiscover,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
                    decoration: BoxDecoration(
                      color: palette.glass,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.glassLine),
                    ),
                    child: Row(
                      children: [
                        _HeroStat(palette: palette, value: '$total', label: 'Shortlisted'),
                        _HeroStat(palette: palette, value: '$selected', label: 'Selected'),
                        _HeroStat(palette: palette, value: '$savedSearches', label: 'Saved searches'),
                        _HeroStat(palette: palette, value: '$alertsOn', label: 'Alerts on'),
                      ],
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

class _HeroStat extends StatelessWidget {
  final _ShortlistPalette palette;
  final String value;
  final String label;

  const _HeroStat({required this.palette, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: palette.goldFill, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              style: GoogleFonts.archivo(
                color: palette.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -.4,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.archivo(
                color: palette.ink2,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardPanel extends StatelessWidget {
  final _ShortlistPalette palette;
  final List<MarketplaceShortlist> boards;
  final MarketplaceShortlist? activeBoard;
  final Set<String> checkedIds;
  final Map<String, int> rankBumps;
  final String? mutatingId;
  final String? hoveredId;
  final bool mobile;
  final Animation<double> sheen;
  final ValueChanged<String?> onHover;
  final ValueChanged<String> onBoardChanged;
  final VoidCallback onToggleAll;
  final void Function(String id, bool checked) onCheckItem;
  final ValueChanged<MarketplaceShortlistItem> onMoveUp;
  final ValueChanged<MarketplaceShortlistItem> onMoveDown;
  final ValueChanged<MarketplaceShortlistItem> onToggleSelect;
  final ValueChanged<MarketplaceShortlistItem> onRemove;
  final VoidCallback onDiscover;

  const _BoardPanel({
    required this.palette,
    required this.boards,
    required this.activeBoard,
    required this.checkedIds,
    required this.rankBumps,
    required this.mutatingId,
    required this.hoveredId,
    required this.mobile,
    required this.sheen,
    required this.onHover,
    required this.onBoardChanged,
    required this.onToggleAll,
    required this.onCheckItem,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onToggleSelect,
    required this.onRemove,
    required this.onDiscover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.line),
        boxShadow: [palette.shadow],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SlidingTabs(
                  palette: palette,
                  boards: boards,
                  activeId: activeBoard?.publicId,
                  sheen: sheen,
                  onChanged: onBoardChanged,
                ),
              ),
              const SizedBox(width: 8),
              _AllButton(
                palette: palette,
                enabled: activeBoard?.items.isNotEmpty ?? false,
                checked: activeBoard != null &&
                    activeBoard!.items.isNotEmpty &&
                    activeBoard!.items.every((item) => checkedIds.contains(item.publicId)),
                onTap: onToggleAll,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (activeBoard == null || activeBoard!.items.isEmpty)
            _EmptyBoard(palette: palette, onDiscover: onDiscover)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = mobile || constraints.maxWidth < 640;
                final rowHeight = narrow ? 126.0 : 82.0;
                final gap = 8.0;
                final ordered = [...activeBoard!.items]
                  ..sort((a, b) => a.rank.compareTo(b.rank));
                return SizedBox(
                  height: math.max(0.0, ordered.length * (rowHeight + gap) - gap),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var index = 0; index < ordered.length; index++)
                        AnimatedPositioned(
                          key: ValueKey(ordered[index].publicId),
                          duration: const Duration(milliseconds: 600),
                          curve: const Cubic(0.65, 0, 0.25, 1),
                          left: 0,
                          right: 0,
                          top: index * (rowHeight + gap),
                          height: rowHeight,
                          child: _RankedRow(
                            palette: palette,
                            item: ordered[index],
                            displayRank: index + 1,
                            boardName: activeBoard!.name,
                            narrow: narrow,
                            isFirst: index == 0,
                            isLast: index == ordered.length - 1,
                            checked: checkedIds.contains(ordered[index].publicId),
                            hovered: hoveredId == ordered[index].publicId,
                            busy: mutatingId == ordered[index].publicId,
                            bump: rankBumps[ordered[index].publicId] ?? 0,
                            onHover: onHover,
                            onCheck: onCheckItem,
                            onMoveUp: () => onMoveUp(ordered[index]),
                            onMoveDown: () => onMoveDown(ordered[index]),
                            onSelect: () => onToggleSelect(ordered[index]),
                            onRemove: () => onRemove(ordered[index]),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SlidingTabs extends StatelessWidget {
  final _ShortlistPalette palette;
  final List<MarketplaceShortlist> boards;
  final String? activeId;
  final Animation<double> sheen;
  final ValueChanged<String> onChanged;

  const _SlidingTabs({
    required this.palette,
    required this.boards,
    required this.activeId,
    required this.sheen,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (boards.isEmpty) {
      return SizedBox(
        height: 42,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'No shortlist yet',
            style: GoogleFonts.archivo(color: palette.muted, fontSize: 12),
          ),
        ),
      );
    }
    final widths = boards.map(_tabWidth).toList();
    var activeLeft = 0.0;
    var activeWidth = widths.first;
    for (var i = 0; i < boards.length; i++) {
      if (boards[i].publicId == activeId) {
        activeWidth = widths[i];
        break;
      }
      activeLeft += widths[i] + 4;
    }
    final totalWidth = widths.fold<double>(0, (sum, width) => sum + width) +
        math.max(0, boards.length - 1).toDouble() * 4;

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
                curve: const Cubic(0.65, 0, 0.25, 1),
                left: activeLeft,
                top: 2,
                width: activeWidth,
                height: 34,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.goldLight.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(color: palette.goldFill.withValues(alpha: .35), blurRadius: 18),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: const Cubic(0.65, 0, 0.25, 1),
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
                curve: const Cubic(0.65, 0, 0.25, 1),
                left: activeLeft,
                bottom: 0,
                width: activeWidth,
                height: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.goldFill,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(color: palette.goldFill.withValues(alpha: .7), blurRadius: 10),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < boards.length; i++) ...[
                    SizedBox(
                      width: widths[i],
                      height: 38,
                      child: InkWell(
                        onTap: () => onChanged(boards[i].publicId),
                        borderRadius: BorderRadius.circular(999),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _tabLabel(boards[i].name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.archivo(
                                  color: boards[i].publicId == activeId
                                      ? palette.onGold
                                      : palette.ink2,
                                  fontSize: 12,
                                  fontWeight: boards[i].publicId == activeId
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Container(
                              constraints: const BoxConstraints(minWidth: 18),
                              height: 18,
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: boards[i].publicId == activeId
                                    ? Colors.white.withValues(alpha: .48)
                                    : palette.goldSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${boards[i].items.length}',
                                style: GoogleFonts.archivo(
                                  color: boards[i].publicId == activeId
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
                    if (i != boards.length - 1) const SizedBox(width: 4),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _tabWidth(MarketplaceShortlist board) {
    final label = _tabLabel(board.name);
    return (label.length * 7.2 + 62).clamp(126.0, 235.0).toDouble();
  }

  String _tabLabel(String name) {
    final clean = name.trim();
    if (clean.toLowerCase().endsWith(' shortlist')) {
      return clean.substring(0, clean.length - 10).trim();
    }
    return clean;
  }
}

class _RankedRow extends StatelessWidget {
  final _ShortlistPalette palette;
  final MarketplaceShortlistItem item;
  final int displayRank;
  final String boardName;
  final bool narrow;
  final bool isFirst;
  final bool isLast;
  final bool checked;
  final bool hovered;
  final bool busy;
  final int bump;
  final ValueChanged<String?> onHover;
  final void Function(String id, bool checked) onCheck;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  const _RankedRow({
    required this.palette,
    required this.item,
    required this.displayRank,
    required this.boardName,
    required this.narrow,
    required this.isFirst,
    required this.isLast,
    required this.checked,
    required this.hovered,
    required this.busy,
    required this.bump,
    required this.onHover,
    required this.onCheck,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final candidate = item.listing.toCandidate();
    final selected = item.status == 'selected';
    final cat = _CategoryTone.forName(candidate.category, palette);
    final role = item.listing.summary.trim().isNotEmpty
        ? item.listing.summary.trim()
        : candidate.category;
    final seed = item.notes?.trim().isNotEmpty == true
        ? item.notes!.trim()
        : 'Seeded from $boardName';

    return MouseRegion(
      onEnter: (_) => onHover(item.publicId),
      onExit: (_) => onHover(null),
      child: AnimatedScale(
        scale: hovered ? 1.015 : 1,
        duration: const Duration(milliseconds: 380),
        curve: const Cubic(0.2, 0.9, 0.25, 1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          curve: const Cubic(0.2, 0.9, 0.25, 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: palette.dark
                        ? [
                            Colors.white.withValues(alpha: .07),
                            const Color(0xFF29405D).withValues(alpha: .25),
                            const Color(0xFF5A456C).withValues(alpha: .18),
                            const Color(0xFF70502E).withValues(alpha: .18),
                          ]
                        : [
                            Colors.white.withValues(alpha: .90),
                            const Color(0xFFD9ECFA).withValues(alpha: .80),
                            const Color(0xFFE9DFFB).withValues(alpha: .75),
                            const Color(0xFFFFE8D5).withValues(alpha: .82),
                          ],
                  )
                : null,
            color: selected ? null : palette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected || hovered ? palette.goldFill : palette.line,
            ),
            boxShadow: hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: palette.dark ? .38 : .12),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: palette.goldFill.withValues(alpha: .22),
                      blurRadius: 26,
                    ),
                  ]
                : selected
                    ? [
                        BoxShadow(color: palette.goldFill.withValues(alpha: .14), blurRadius: 18),
                      ]
                    : [palette.shadow],
          ),
          child: Stack(
            children: [
              Positioned(
                left: -12,
                top: -10,
                bottom: -10,
                width: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected ? palette.goldFill : cat.line,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        key: ValueKey('${item.publicId}:$bump'),
                        tween: Tween(begin: bump > 0 ? 1.25 : 1, end: 1),
                        duration: const Duration(milliseconds: 500),
                        curve: const Cubic(0.3, 1.4, 0.4, 1),
                        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                        child: SizedBox(
                          width: 32,
                          child: Text(
                            displayRank.toString().padLeft(2, '0'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.newsreader(
                              color: palette.gold,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _CheckBox(
                        palette: palette,
                        checked: checked,
                        onTap: () => onCheck(item.publicId, !checked),
                      ),
                      const SizedBox(width: 11),
                      _Thumb(
                        palette: palette,
                        imageUrl: candidate.imageUrl,
                        initials: candidate.avatarLabel,
                        tone: cat,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    candidate.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.archivo(
                                      color: palette.ink,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.2,
                                    ),
                                  ),
                                ),
                                if (selected) ...[
                                  const SizedBox(width: 6),
                                  _SelectedTag(palette: palette),
                                ],
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              role,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.archivo(
                                color: palette.muted,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 3,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _CategoryTag(tone: cat, label: candidate.category),
                                _Meta(icon: Icons.location_on_outlined, text: candidate.city, palette: palette),
                                Text(
                                  candidate.rateRange,
                                  style: GoogleFonts.archivo(
                                    color: palette.gold,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (!narrow)
                                  Text(
                                    '· $seed',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.archivo(color: palette.muted, fontSize: 10.5),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!narrow) ...[
                        const SizedBox(width: 10),
                        _RowActions(
                          palette: palette,
                          selected: selected,
                          busy: busy,
                          verticalArrows: true,
                          upEnabled: !isFirst,
                          downEnabled: !isLast,
                          onMoveUp: onMoveUp,
                          onMoveDown: onMoveDown,
                          onSelect: onSelect,
                          onRemove: onRemove,
                        ),
                      ],
                    ],
                  ),
                  if (narrow) ...[
                    const SizedBox(height: 9),
                    _RowActions(
                      palette: palette,
                      selected: selected,
                      busy: busy,
                      verticalArrows: false,
                      upEnabled: !isFirst,
                      downEnabled: !isLast,
                      onMoveUp: onMoveUp,
                      onMoveDown: onMoveDown,
                      onSelect: onSelect,
                      onRemove: onRemove,
                    ),
                  ],
                ],
              ),
              if (busy)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.gold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  final _ShortlistPalette palette;
  final bool selected;
  final bool busy;
  final bool verticalArrows;
  final bool upEnabled;
  final bool downEnabled;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  const _RowActions({
    required this.palette,
    required this.selected,
    required this.busy,
    required this.verticalArrows,
    required this.upEnabled,
    required this.downEnabled,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (verticalArrows) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              _ArrowButton(palette: palette, up: true, enabled: upEnabled && !busy, onTap: onMoveUp),
              const SizedBox(height: 3),
              _ArrowButton(palette: palette, up: false, enabled: downEnabled && !busy, onTap: onMoveDown),
            ],
          ),
          const SizedBox(width: 6),
          _SelectButton(palette: palette, selected: selected, busy: busy, onTap: onSelect),
          const SizedBox(width: 6),
          _RemoveButton(palette: palette, enabled: !busy, onTap: onRemove, round: true),
        ],
      );
    }
    return Row(
      children: [
        _ArrowButton(palette: palette, up: true, enabled: upEnabled && !busy, onTap: onMoveUp, large: true),
        const SizedBox(width: 6),
        _ArrowButton(palette: palette, up: false, enabled: downEnabled && !busy, onTap: onMoveDown, large: true),
        const SizedBox(width: 6),
        Expanded(
          child: _SelectButton(
            palette: palette,
            selected: selected,
            busy: busy,
            onTap: onSelect,
            fullWidth: true,
          ),
        ),
        const SizedBox(width: 6),
        _RemoveButton(palette: palette, enabled: !busy, onTap: onRemove, round: false),
      ],
    );
  }
}

class _SavedSearchPanel extends StatelessWidget {
  final _ShortlistPalette palette;
  final List<MarketplaceSavedSearch> searches;
  final bool horizontal;
  final Map<String, bool> alertState;
  final String? mutatingId;
  final ValueChanged<MarketplaceSavedSearch> onToggleAlert;
  final ValueChanged<MarketplaceSavedSearch> onRun;
  final ValueChanged<MarketplaceSavedSearch> onRemove;
  final VoidCallback onDiscover;
  final Animation<double> ambient;

  const _SavedSearchPanel({
    required this.palette,
    required this.searches,
    required this.horizontal,
    required this.alertState,
    required this.mutatingId,
    required this.onToggleAlert,
    required this.onRun,
    required this.onRemove,
    required this.onDiscover,
    required this.ambient,
  });

  @override
  Widget build(BuildContext context) {
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
                'Saved searches',
                style: GoogleFonts.newsreader(
                  color: palette.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${searches.length} saved',
                style: GoogleFonts.archivo(color: palette.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (searches.isEmpty)
            _SaveSearchEmpty(palette: palette, onTap: onDiscover)
          else if (horizontal)
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: searches.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == searches.length) {
                    return SizedBox(
                      width: 240,
                      child: _SaveSearchEmpty(palette: palette, onTap: onDiscover),
                    );
                  }
                  final search = searches[index];
                  return SizedBox(
                    width: 270,
                    child: _SavedSearchCard(
                      palette: palette,
                      search: search,
                      alertOn: alertState[search.publicId] ?? search.notifyEnabled,
                      busy: mutatingId == search.publicId,
                      ambient: ambient,
                      index: index,
                      onToggleAlert: () => onToggleAlert(search),
                      onRun: () => onRun(search),
                      onRemove: () => onRemove(search),
                    ),
                  );
                },
              ),
            )
          else ...[
            for (var i = 0; i < searches.length; i++) ...[
              _SavedSearchCard(
                palette: palette,
                search: searches[i],
                alertOn: alertState[searches[i].publicId] ?? searches[i].notifyEnabled,
                busy: mutatingId == searches[i].publicId,
                ambient: ambient,
                index: i,
                onToggleAlert: () => onToggleAlert(searches[i]),
                onRun: () => onRun(searches[i]),
                onRemove: () => onRemove(searches[i]),
              ),
              const SizedBox(height: 8),
            ],
            _SaveSearchEmpty(palette: palette, onTap: onDiscover),
          ],
        ],
      ),
    );
  }
}

class _SavedSearchCard extends StatelessWidget {
  final _ShortlistPalette palette;
  final MarketplaceSavedSearch search;
  final bool alertOn;
  final bool busy;
  final Animation<double> ambient;
  final int index;
  final VoidCallback onToggleAlert;
  final VoidCallback onRun;
  final VoidCallback onRemove;

  const _SavedSearchCard({
    required this.palette,
    required this.search,
    required this.alertOn,
    required this.busy,
    required this.ambient,
    required this.index,
    required this.onToggleAlert,
    required this.onRun,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, _) {
        final t = (ambient.value + index * .17) % 1;
        final angle = t * math.pi * 2;
        return Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(math.cos(angle), math.sin(angle)),
              end: Alignment(-math.cos(angle), -math.sin(angle)),
              colors: palette.holo,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.glassLine),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: palette.goldSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.manage_search_rounded, color: palette.gold, size: 15),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          search.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.archivo(
                            color: palette.ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _searchMeta(search, alertOn),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.archivo(color: palette.ink2, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: busy ? null : onRemove,
                    borderRadius: BorderRadius.circular(99),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: busy
                          ? Padding(
                              padding: const EdgeInsets.all(5),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: palette.gold,
                              ),
                            )
                          : Icon(Icons.close_rounded, color: palette.muted, size: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  InkWell(
                    onTap: onToggleAlert,
                    borderRadius: BorderRadius.circular(99),
                    child: Row(
                      children: [
                        _MiniSwitch(palette: palette, on: alertOn),
                        const SizedBox(width: 7),
                        Text(
                          alertOn ? 'Alerts on' : 'Alerts off',
                          style: GoogleFonts.archivo(
                            color: palette.ink2,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _RunButton(palette: palette, onTap: onRun),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _searchMeta(MarketplaceSavedSearch search, bool alertOn) {
    final parts = <String>[
      if (search.listingType?.isNotEmpty == true) search.listingType!,
      if (search.queryText?.isNotEmpty == true) '"${search.queryText}"',
      'alerts ${alertOn ? 'on' : 'off'}',
    ];
    return parts.join(' · ');
  }
}

class _BulkBar extends StatelessWidget {
  final _ShortlistPalette palette;
  final int count;
  final bool busy;
  final bool mobile;
  final VoidCallback onSelectAll;
  final VoidCallback onRemove;
  final VoidCallback onClear;

  const _BulkBar({
    required this.palette,
    required this.count,
    required this.busy,
    required this.mobile,
    required this.onSelectAll,
    required this.onRemove,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: mobile ? double.infinity : 560),
        padding: const EdgeInsets.fromLTRB(14, 7, 7, 7),
        decoration: BoxDecoration(
          color: palette.sheet.withValues(alpha: .95),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.glassLine),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: .22), blurRadius: 34, offset: const Offset(0, 16)),
            BoxShadow(color: palette.goldFill.withValues(alpha: .25), blurRadius: 30),
          ],
        ),
        child: Row(
          mainAxisSize: mobile ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Text(
              '$count checked',
              style: GoogleFonts.archivo(
                color: palette.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            if (mobile)
              Expanded(
                child: _GoldPillButton(
                  palette: palette,
                  icon: Icons.done_all_rounded,
                  label: busy ? 'Working…' : 'Select all',
                  onTap: busy ? null : onSelectAll,
                  compact: true,
                ),
              )
            else
              _GoldPillButton(
                palette: palette,
                icon: Icons.done_all_rounded,
                label: busy ? 'Working…' : 'Select all',
                onTap: busy ? null : onSelectAll,
                compact: true,
              ),
            const SizedBox(width: 6),
            _GlassPillButton(
              palette: palette,
              icon: Icons.delete_outline_rounded,
              label: 'Remove',
              onTap: busy ? null : onRemove,
              danger: true,
              compact: true,
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Clear',
              onPressed: busy ? null : onClear,
              icon: Icon(Icons.close_rounded, color: palette.muted, size: 17),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _AllButton extends StatelessWidget {
  final _ShortlistPalette palette;
  final bool enabled;
  final bool checked;
  final VoidCallback onTap;

  const _AllButton({
    required this.palette,
    required this.enabled,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.line),
          ),
          child: Row(
            children: [
              _CheckBox(palette: palette, checked: checked, onTap: enabled ? onTap : null, small: true),
              const SizedBox(width: 6),
              Text(
                'All',
                style: GoogleFonts.archivo(
                  color: palette.ink2,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final _ShortlistPalette palette;
  final bool checked;
  final VoidCallback? onTap;
  final bool small;

  const _CheckBox({
    required this.palette,
    required this.checked,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 14.0 : 18.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: checked
              ? LinearGradient(colors: [palette.goldLight, palette.goldFill])
              : null,
          borderRadius: BorderRadius.circular(small ? 5 : 6),
          border: Border.all(color: checked ? palette.goldFill : palette.goldLine, width: 1.5),
        ),
        child: checked
            ? Icon(Icons.check_rounded, size: small ? 9 : 11, color: palette.onGold)
            : null,
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final _ShortlistPalette palette;
  final String? imageUrl;
  final String initials;
  final _CategoryTone tone;

  const _Thumb({
    required this.palette,
    required this.imageUrl,
    required this.initials,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 48,
        height: 48,
        child: imageUrl != null && imageUrl!.trim().isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ThumbFallback(palette: palette, initials: initials, tone: tone),
              )
            : _ThumbFallback(palette: palette, initials: initials, tone: tone),
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  final _ShortlistPalette palette;
  final String initials;
  final _CategoryTone tone;

  const _ThumbFallback({required this.palette, required this.initials, required this.tone});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.soft, palette.card2],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.newsreader(
            color: tone.ink,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final _CategoryTone tone;
  final String label;

  const _CategoryTag({required this.tone, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.archivo(
          color: tone.ink,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  final _ShortlistPalette palette;

  const _Meta({required this.icon, required this.text, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: palette.muted, size: 10),
        const SizedBox(width: 3),
        Text(text, style: GoogleFonts.archivo(color: palette.ink2, fontSize: 10.5)),
      ],
    );
  }
}

class _SelectedTag extends StatelessWidget {
  final _ShortlistPalette palette;

  const _SelectedTag({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [palette.goldLight, palette.goldFill]),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        'SELECTED',
        style: GoogleFonts.archivo(
          color: palette.onGold,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .6,
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final _ShortlistPalette palette;
  final bool up;
  final bool enabled;
  final VoidCallback onTap;
  final bool large;

  const _ArrowButton({
    required this.palette,
    required this.up,
    required this.enabled,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(large ? 10 : 8),
        child: Container(
          width: large ? 34 : 28,
          height: large ? 32 : 21,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(large ? 10 : 8),
            border: Border.all(color: palette.line),
          ),
          child: Icon(
            up ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            color: palette.ink2,
            size: large ? 18 : 15,
          ),
        ),
      ),
    );
  }
}

class _SelectButton extends StatelessWidget {
  final _ShortlistPalette palette;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;
  final bool fullWidth;

  const _SelectButton({
    required this.palette,
    required this.selected,
    required this.busy,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: fullWidth ? 32 : 34,
        padding: EdgeInsets.symmetric(horizontal: fullWidth ? 12 : 13),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [palette.goldLight, palette.goldFill])
              : null,
          color: selected ? null : palette.glass,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? Colors.transparent : palette.goldLine),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
              color: selected ? palette.onGold : palette.gold,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              selected ? 'Selected' : 'Select',
              style: GoogleFonts.archivo(
                color: selected ? palette.onGold : palette.gold,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final _ShortlistPalette palette;
  final bool enabled;
  final VoidCallback onTap;
  final bool round;

  const _RemoveButton({
    required this.palette,
    required this.enabled,
    required this.onTap,
    required this.round,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(round ? 999 : 10),
        child: Container(
          width: 34,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(round ? 999 : 10),
            border: Border.all(color: palette.line),
          ),
          child: Icon(Icons.delete_outline_rounded, color: palette.muted, size: 16),
        ),
      ),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  final _ShortlistPalette palette;
  final bool on;

  const _MiniSwitch({required this.palette, required this.on});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 31,
      height: 18,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: on ? LinearGradient(colors: [palette.goldLight, palette.goldFill]) : null,
        color: on ? null : palette.line,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.line),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 300),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _RunButton extends StatelessWidget {
  final _ShortlistPalette palette;
  final VoidCallback onTap;

  const _RunButton({required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 27,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.goldLine),
        ),
        child: Row(
          children: [
            Text(
              'Run',
              style: GoogleFonts.archivo(
                color: palette.gold,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.chevron_right_rounded, color: palette.gold, size: 15),
          ],
        ),
      ),
    );
  }
}

class _SaveSearchEmpty extends StatelessWidget {
  final _ShortlistPalette palette;
  final VoidCallback onTap;

  const _SaveSearchEmpty({required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.goldLine, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: palette.gold, size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Save a search from Discover',
                textAlign: TextAlign.center,
                style: GoogleFonts.archivo(
                  color: palette.gold,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  final _ShortlistPalette palette;
  final VoidCallback onDiscover;

  const _EmptyBoard({required this.palette, required this.onDiscover});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.goldLine),
      ),
      child: Column(
        children: [
          Text(
            'This shortlist is empty',
            style: GoogleFonts.newsreader(
              color: palette.ink,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Save talent from Discover or the Marketplace to rank them here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.archivo(color: palette.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          _GoldPillButton(
            palette: palette,
            icon: Icons.manage_search_rounded,
            label: 'Open Discover',
            onTap: onDiscover,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _NoticeBar extends StatelessWidget {
  final _ShortlistPalette palette;
  final String text;

  const _NoticeBar({required this.palette, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.goldSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.goldLine),
      ),
      child: Text(
        text,
        style: GoogleFonts.archivo(
          color: palette.gold,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GoldPillButton extends StatefulWidget {
  final _ShortlistPalette palette;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool compact;

  const _GoldPillButton({
    required this.palette,
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_GoldPillButton> createState() => _GoldPillButtonState();
}

class _GoldPillButtonState extends State<_GoldPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            },
      child: AnimatedScale(
        scale: _pressed ? .96 : 1,
        duration: const Duration(milliseconds: 140),
        child: Container(
          height: widget.compact ? 32 : 36,
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 12 : 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [widget.palette.goldLight, widget.palette.goldFill]),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: widget.palette.goldFill.withValues(alpha: .34),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.palette.onGold, size: 15),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.archivo(
                  color: widget.palette.onGold,
                  fontSize: widget.compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPillButton extends StatelessWidget {
  final _ShortlistPalette palette;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  final bool compact;

  const _GlassPillButton({
    required this.palette,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? .5 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: compact ? 32 : 36,
          padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 13),
          decoration: BoxDecoration(
            color: palette.glass,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: danger ? palette.peachLine : palette.goldLine),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: danger ? palette.peachInk : palette.gold, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.archivo(
                  color: danger ? palette.peachInk : palette.gold,
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroWash extends StatelessWidget {
  final _ShortlistPalette palette;

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
  final _ShortlistPalette palette;
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
        boxShadow: [BoxShadow(color: color.withValues(alpha: .65), blurRadius: 10, spreadRadius: 2)],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  final _ShortlistPalette palette;

  const _LoadingPanel({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(color: palette.gold));
  }
}

class _ErrorPanel extends StatelessWidget {
  final _ShortlistPalette palette;
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.palette, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: palette.gold, size: 30),
            const SizedBox(height: 10),
            Text('Shortlists unavailable', style: GoogleFonts.newsreader(color: palette.ink, fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.archivo(color: palette.muted, fontSize: 12.5)),
            const SizedBox(height: 14),
            _GoldPillButton(palette: palette, icon: Icons.refresh_rounded, label: 'Retry', onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

class _CategoryTone {
  final Color soft;
  final Color ink;
  final Color line;

  const _CategoryTone({required this.soft, required this.ink, required this.line});

  static _CategoryTone forName(String name, _ShortlistPalette palette) {
    final lower = name.toLowerCase();
    if (lower.contains('model')) {
      return _CategoryTone(soft: palette.peachSoft, ink: palette.peachInk, line: palette.peachLine);
    }
    if (lower.contains('location')) {
      return _CategoryTone(soft: palette.mintSoft, ink: palette.mintInk, line: palette.mintLine);
    }
    if (lower.contains('equipment') || lower.contains('media')) {
      return _CategoryTone(soft: palette.iceSoft, ink: palette.iceInk, line: palette.iceLine);
    }
    return _CategoryTone(soft: palette.lavSoft, ink: palette.lavInk, line: palette.lavLine);
  }
}

class _ShortlistPalette {
  final bool dark;
  final Color bg;
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
  final Color lavSoft;
  final Color peachSoft;
  final Color iceInk;
  final Color mintInk;
  final Color lavInk;
  final Color peachInk;
  final Color iceLine;
  final Color mintLine;
  final Color lavLine;
  final Color peachLine;
  final List<Color> holo;
  final List<Color> bubble;
  final Color bubbleBorder;
  final BoxShadow shadow;

  const _ShortlistPalette({
    required this.dark,
    required this.bg,
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
    required this.lavSoft,
    required this.peachSoft,
    required this.iceInk,
    required this.mintInk,
    required this.lavInk,
    required this.peachInk,
    required this.iceLine,
    required this.mintLine,
    required this.lavLine,
    required this.peachLine,
    required this.holo,
    required this.bubble,
    required this.bubbleBorder,
    required this.shadow,
  });

  static _ShortlistPalette of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return _ShortlistPalette(
        dark: true,
        bg: const Color(0xFF09090B),
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
        lavSoft: const Color(0xFFB2A4EC).withValues(alpha: .12),
        peachSoft: const Color(0xFFE8AE94).withValues(alpha: .12),
        iceInk: const Color(0xFFA9D4F2),
        mintInk: const Color(0xFFA8E0C0),
        lavInk: const Color(0xFFC9BDF5),
        peachInk: const Color(0xFFF2C6B2),
        iceLine: const Color(0xFF8FC2E6),
        mintLine: const Color(0xFF8FD3A9),
        lavLine: const Color(0xFFB2A4EC),
        peachLine: const Color(0xFFE8AE94),
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
    return _ShortlistPalette(
      dark: false,
      bg: const Color(0xFFF7F5F0),
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
      lavSoft: const Color(0xFFF3F0FC),
      peachSoft: const Color(0xFFFCF1EB),
      iceInk: const Color(0xFF3F6E8F),
      mintInk: const Color(0xFF3C7A55),
      lavInk: const Color(0xFF5E52A0),
      peachInk: const Color(0xFFA0593C),
      iceLine: const Color(0xFFA9D0EC),
      mintLine: const Color(0xFFA9DDBC),
      lavLine: const Color(0xFFC4B9EE),
      peachLine: const Color(0xFFEFC3AE),
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
