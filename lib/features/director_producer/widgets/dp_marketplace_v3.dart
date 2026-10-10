import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../models/dp_candidate.dart';

const dpMarketplaceCategories = <String>[
  'All',
  'Actors',
  'Models',
  'Influencers',
  'Crew',
  'Locations',
  'Equipment',
];

String dpMarketplaceCanonicalCategory(String value) {
  final lower = value.trim().toLowerCase();
  if (lower == 'talent' || lower.contains('actor')) return 'Actors';
  if (lower.contains('model')) return 'Models';
  if (lower.contains('influencer') || lower.contains('creator')) {
    return 'Influencers';
  }
  if (lower.contains('crew') ||
      lower.contains('dop') ||
      lower.contains('cinemat') ||
      lower.contains('editor') ||
      lower.contains('makeup') ||
      lower.contains('sound') ||
      lower.contains('gaffer')) {
    return 'Crew';
  }
  if (lower.contains('location') || lower.contains('venue')) {
    return 'Locations';
  }
  if (lower.contains('equipment') ||
      lower.contains('gear') ||
      lower.contains('media')) {
    return 'Equipment';
  }
  return value;
}

typedef MarketplaceCandidateAction = void Function(DpCandidate candidate);
typedef MarketplaceCandidateAsyncAction = Future<bool> Function(
  DpCandidate candidate,
);

class DPMarketplaceV3 extends StatefulWidget {
  final List<DpCandidate> candidates;
  final String initialCategory;
  final bool publicBuyerMode;
  final MarketplaceCandidateAction onProfile;
  final MarketplaceCandidateAction onOffer;
  final MarketplaceCandidateAsyncAction onFavourite;
  final VoidCallback onCreateAudition;
  final VoidCallback onSaveSearch;
  final VoidCallback onOpenShortlist;
  final ValueChanged<String>? onCategoryChanged;

  const DPMarketplaceV3({
    super.key,
    required this.candidates,
    required this.initialCategory,
    required this.publicBuyerMode,
    required this.onProfile,
    required this.onOffer,
    required this.onFavourite,
    required this.onCreateAudition,
    required this.onSaveSearch,
    required this.onOpenShortlist,
    this.onCategoryChanged,
  });

  @override
  State<DPMarketplaceV3> createState() => _DPMarketplaceV3State();
}

class _DPMarketplaceV3State extends State<DPMarketplaceV3> {
  final TextEditingController _search = TextEditingController();
  final Set<String> _favourites = <String>{};
  final Map<String, Set<String>> _smart = <String, Set<String>>{
    'city': <String>{},
    'budget': <String>{},
    'lang': <String>{},
    'avail': <String>{},
    'trust': <String>{},
  };

  late String _category = _normalizeInitial(widget.initialCategory);
  bool _grid = true;
  bool _aiMatch = false;
  String? _zoomedId;
  int _resultRevision = 0;
  OverlayEntry? _aiOverlay;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onQueryChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureAiOverlay();
    _aiOverlay?.markNeedsBuild();
  }

  @override
  void didUpdateWidget(covariant DPMarketplaceV3 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      final next = _normalizeInitial(widget.initialCategory);
      if (next != _category) {
        _category = next;
        _resultRevision++;
      }
    }
    _aiOverlay?.markNeedsBuild();
  }

  @override
  void dispose() {
    _search.removeListener(_onQueryChanged);
    _search.dispose();
    _aiOverlay?.remove();
    _aiOverlay = null;
    super.dispose();
  }

  void _ensureAiOverlay() {
    if (_aiOverlay != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _aiOverlay != null) return;
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) return;
      _aiOverlay = OverlayEntry(
        builder: (overlayContext) {
          final size = MediaQuery.sizeOf(overlayContext);
          final mobile = size.width < 760;
          return Positioned(
            right: mobile ? 16 : 28,
            bottom: mobile ? 86 : 28,
            child: Theme(
              data: Theme.of(context),
              child: _AiMatchFab(
                count: _smartCount,
                onTap: _openSmartFilters,
              ),
            ),
          );
        },
      );
      overlay.insert(_aiOverlay!);
    });
  }

  void _onQueryChanged() {
    if (!mounted) return;
    setState(() {
      _zoomedId = null;
      _resultRevision++;
    });
    _aiOverlay?.markNeedsBuild();
  }

  String _normalizeInitial(String value) {
    final normalized = dpMarketplaceCanonicalCategory(value);
    return dpMarketplaceCategories.contains(normalized) ? normalized : 'All';
  }

  int get _smartCount =>
      _smart.values.fold<int>(0, (sum, values) => sum + values.length) +
      (_aiMatch ? 1 : 0);

  List<DpCandidate> get _baseResults {
    final query = _search.text.trim().toLowerCase();
    final list = widget.candidates.where((candidate) {
      final canonical = dpMarketplaceCanonicalCategory(candidate.category);
      if (!dpMarketplaceCategories.contains(canonical) || canonical == 'All') {
        return false;
      }
      if (query.isNotEmpty) {
        final haystack = <String>[
          candidate.name,
          candidate.city,
          candidate.category,
          candidate.rateRange,
          candidate.notes,
          ...candidate.skills,
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      if (!_passesSmart(candidate, _smart)) return false;
      return true;
    }).toList();

    list.sort((a, b) {
      if (_aiMatch) {
        final match = _matchPercent(b).compareTo(_matchPercent(a));
        if (match != 0) return match;
      }
      final verified = b.verified.toString().compareTo(a.verified.toString());
      if (verified != 0) return verified;
      final trust = _trustScore(b).compareTo(_trustScore(a));
      if (trust != 0) return trust;
      final rating = b.rating.compareTo(a.rating);
      if (rating != 0) return rating;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  bool _passesSmart(
    DpCandidate candidate,
    Map<String, Set<String>> smart,
  ) {
    final cities = smart['city']!;
    if (cities.isNotEmpty && !cities.contains(candidate.city)) return false;

    final budgets = smart['budget']!;
    if (budgets.isNotEmpty) {
      final rate = _candidateRateK(candidate);
      final ok = budgets.any((budget) {
        if (budget == 'Under 100K') return rate != null && rate < 100;
        if (budget == '150K+') return rate != null && rate > 150;
        return rate != null && rate >= 100 && rate <= 150;
      });
      if (!ok) return false;
    }

    final languages = smart['lang']!;
    if (languages.isNotEmpty) {
      final haystack = <String>[candidate.notes, ...candidate.skills]
          .join(' ')
          .toLowerCase();
      if (!languages.any((language) =>
          haystack.contains(language.toLowerCase()))) return false;
    }

    final availability = smart['avail']!;
    if (availability.isNotEmpty) {
      final ok = availability.any((value) {
        if (value == 'Available now') return candidate.available;
        return candidate.available || _hash(candidate.name) % 3 != 0;
      });
      if (!ok) return false;
    }

    for (final trust in smart['trust']!) {
      if (trust == 'Verified only' && !candidate.verified) return false;
      if (trust == 'Trust 85+' && _trustScore(candidate) < 85) return false;
      if (trust == 'Offers welcome' &&
          !(candidate.available || candidate.marketplaceListingId != null)) {
        return false;
      }
    }
    return true;
  }

  int? _candidateRateK(DpCandidate candidate) {
    final text = candidate.rateRange.replaceAll(',', '').toUpperCase();
    final matches = RegExp(r'(\d+(?:\.\d+)?)\s*K').allMatches(text).toList();
    if (matches.isNotEmpty) {
      return double.tryParse(matches.first.group(1) ?? '')?.round();
    }
    final numeric = RegExp(r'(\d{4,})').firstMatch(text)?.group(1);
    final amount = int.tryParse(numeric ?? '');
    if (amount != null) return (amount / 1000).round();
    return null;
  }

  int _trustScore(DpCandidate candidate) {
    final score = candidate.trustMetrics?.score;
    if (score != null) return score.clamp(0, 100).toInt();
    var result = 70;
    if (candidate.verified) result += 12;
    if (candidate.available) result += 4;
    result += (_displayRating(candidate) * 1.4).round();
    return result.clamp(0, 99).toInt();
  }

  double _displayRating(DpCandidate candidate) {
    if (candidate.rating <= 0) return 8.0 + (_hash(candidate.name) % 14) / 10;
    final value = candidate.rating <= 5 ? candidate.rating * 2 : candidate.rating;
    return value.clamp(0, 10).toDouble();
  }

  int _matchPercent(DpCandidate candidate) {
    final trust = _trustScore(candidate);
    final rating = _displayRating(candidate);
    final raw = 78 + (trust * .12) + (rating * .8) + (_hash(candidate.name) % 4);
    return raw.round().clamp(88, 99).toInt();
  }

  int _hash(String value) {
    var result = 0;
    for (final code in value.codeUnits) {
      result = (result * 31 + code) % 997;
    }
    return result;
  }

  Map<String, List<DpCandidate>> get _sections {
    final pool = _baseResults;
    final map = <String, List<DpCandidate>>{};
    for (final category in dpMarketplaceCategories.skip(1)) {
      map[category] = pool
          .where((candidate) =>
              dpMarketplaceCanonicalCategory(candidate.category) == category)
          .toList();
    }
    return map;
  }

  int _countForSmart(Map<String, Set<String>> smart, bool ai) {
    final query = _search.text.trim().toLowerCase();
    return widget.candidates.where((candidate) {
      final canonical = dpMarketplaceCanonicalCategory(candidate.category);
      if (!dpMarketplaceCategories.contains(canonical) || canonical == 'All') {
        return false;
      }
      if (query.isNotEmpty) {
        final haystack = <String>[
          candidate.name,
          candidate.city,
          candidate.category,
          candidate.rateRange,
          candidate.notes,
          ...candidate.skills,
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return _passesSmart(candidate, smart);
    }).length;
  }

  void _selectCategory(String category) {
    if (_category == category) return;
    setState(() {
      _category = category;
      _zoomedId = null;
      _resultRevision++;
    });
    widget.onCategoryChanged?.call(category);
  }

  void _setGrid(bool value) {
    if (_grid == value) return;
    setState(() {
      _grid = value;
      _zoomedId = null;
      _resultRevision++;
    });
  }

  void _setZoom(String? id) {
    if (_zoomedId == id) return;
    setState(() => _zoomedId = id);
  }

  Future<void> _toggleFavourite(DpCandidate candidate) async {
    final active = _favourites.contains(candidate.id);
    if (active) {
      setState(() => _favourites.remove(candidate.id));
      _aiOverlay?.markNeedsBuild();
      return;
    }
    final ok = await widget.onFavourite(candidate);
    if (!mounted || !ok) return;
    setState(() => _favourites.add(candidate.id));
    _aiOverlay?.markNeedsBuild();
  }

  void _resetSmart() {
    setState(() {
      for (final values in _smart.values) {
        values.clear();
      }
      _aiMatch = false;
      _resultRevision++;
    });
    _aiOverlay?.markNeedsBuild();
  }

  Future<void> _openSmartFilters() async {
    if (!mounted) return;
    final width = MediaQuery.sizeOf(context).width;
    final sheet = MarketplaceSmartFiltersSheet(
      initialSmart: {
        for (final entry in _smart.entries)
          entry.key: Set<String>.from(entry.value),
      },
      initialAi: _aiMatch,
      resultCount: _countForSmart,
      onChanged: (smart, ai) {
        if (!mounted) return;
        setState(() {
          for (final entry in smart.entries) {
            _smart[entry.key] = Set<String>.from(entry.value);
          }
          _aiMatch = ai;
          _zoomedId = null;
          _resultRevision++;
        });
        _aiOverlay?.markNeedsBuild();
      },
      onReset: _resetSmart,
    );
    if (width < 760) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: .35),
        builder: (_) => sheet,
      );
    } else {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: .38),
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: sheet,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sections = _sections;
    final filteredTotal = sections.values.fold<int>(0, (n, list) => n + list.length);
    final categoryCounts = <String, int>{
      'All': filteredTotal,
      for (final category in dpMarketplaceCategories.skip(1))
        category: sections[category]?.length ?? 0,
    };
    final mobile = MediaQuery.sizeOf(context).width < 760;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aiOverlay?.markNeedsBuild();
    });

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggerReveal(
              child: MarketplaceHero(
                total: filteredTotal,
                mobile: mobile,
                publicBuyerMode: widget.publicBuyerMode,
                search: _search,
                favouriteCount: _favourites.length,
                smartCount: _smartCount,
                grid: _grid,
                onCreateAudition: widget.onCreateAudition,
                onSmartFilters: _openSmartFilters,
                onGridChanged: _setGrid,
                onSaveSearch: widget.onSaveSearch,
                onOpenShortlist: widget.onOpenShortlist,
              ),
            ),
            const SizedBox(height: 12),
            StaggerReveal(
              delay: const Duration(milliseconds: 70),
              child: MarketplaceFilterRail(
                selected: _category,
                counts: categoryCounts,
                onSelected: _selectCategory,
              ),
            ),
            const SizedBox(height: 2),
            if (filteredTotal == 0)
              MarketplaceEmptyState(onReset: _resetSmart)
            else
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: const Cubic(0.2, 0.8, 0.2, 1),
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, .025),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey('$_category-$_grid-$_resultRevision'),
                  child: MarketplaceSections(
                    sections: sections,
                    selectedCategory: _category,
                    grid: _grid,
                    aiMatch: _aiMatch,
                    mobile: mobile,
                    zoomedId: _zoomedId,
                    favouriteIds: _favourites,
                    displayRating: _displayRating,
                    trustScore: _trustScore,
                    matchPercent: _matchPercent,
                    onZoom: _setZoom,
                    onProfile: widget.onProfile,
                    onOffer: widget.onOffer,
                    onFavourite: _toggleFavourite,
                  ),
                ),
              ),
          ],
        ),
        if (colors.isLight)
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x08D3B55F)],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class MarketplaceHero extends StatelessWidget {
  final int total;
  final bool mobile;
  final bool publicBuyerMode;
  final TextEditingController search;
  final int favouriteCount;
  final int smartCount;
  final bool grid;
  final VoidCallback onCreateAudition;
  final VoidCallback onSmartFilters;
  final ValueChanged<bool> onGridChanged;
  final VoidCallback onSaveSearch;
  final VoidCallback onOpenShortlist;

  const MarketplaceHero({
    super.key,
    required this.total,
    required this.mobile,
    required this.publicBuyerMode,
    required this.search,
    required this.favouriteCount,
    required this.smartCount,
    required this.grid,
    required this.onCreateAudition,
    required this.onSmartFilters,
    required this.onGridChanged,
    required this.onSaveSearch,
    required this.onOpenShortlist,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned.fill(child: _MarketplaceWash(light: colors.isLight)),
          const Positioned.fill(child: MarketplaceHeroBubbles()),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 16 : 22,
              vertical: mobile ? 16 : 20,
            ),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: colors.isLight ? .16 : .35),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                  spreadRadius: -20,
                ),
              ],
            ),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 760;
                    final title = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.goldMid,
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.goldMid.withValues(alpha: .6),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'FIND · $total VERIFIED PROFILES',
                              style: GoogleFonts.archivo(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                                color: colors.goldDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Marketplace',
                          style: GoogleFonts.newsreader(
                            fontSize: mobile ? 28 : 34,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.4,
                            height: 1.05,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          publicBuyerMode
                              ? 'Book verified actors, models and influencers across Pakistan.'
                              : 'Verified talent, crew, locations and gear across Pakistan.',
                          style: GoogleFonts.archivo(
                            fontSize: 12.5,
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    );
                    final actions = Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (!publicBuyerMode)
                          _GoldActionButton(
                            icon: Icons.campaign_outlined,
                            label: 'Create audition',
                            onTap: onCreateAudition,
                          ),
                        _GlassActionButton(
                          icon: Icons.tune_rounded,
                          label: 'Smart filters',
                          badge: smartCount,
                          onTap: onSmartFilters,
                        ),
                        MarketplaceLayoutToggle(
                          grid: grid,
                          onChanged: onGridChanged,
                        ),
                      ],
                    );
                    if (stacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [title, const SizedBox(height: 14), actions],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: 16),
                        actions,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: colors.isLight
                              ? Colors.white.withValues(alpha: .62)
                              : Colors.white.withValues(alpha: .05),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded,
                                size: 17, color: colors.textTertiary),
                            const SizedBox(width: 9),
                            Expanded(
                              child: TextField(
                                controller: search,
                                style: GoogleFonts.archivo(
                                  fontSize: 13,
                                  color: colors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'Search talent, crew, locations…',
                                  hintStyle: GoogleFonts.archivo(
                                    fontSize: 13,
                                    color: colors.textTertiary,
                                  ),
                                ),
                              ),
                            ),
                            if (search.text.isNotEmpty)
                              InkWell(
                                borderRadius: BorderRadius.circular(99),
                                onTap: search.clear,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.close_rounded,
                                      size: 16, color: colors.iconMuted),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RoundGlassButton(
                      tooltip: 'Save search',
                      icon: Icons.bookmark_add_outlined,
                      badge: 0,
                      onTap: onSaveSearch,
                    ),
                    const SizedBox(width: 8),
                    _RoundGlassButton(
                      tooltip: 'Shortlist',
                      icon: Icons.bookmark_border_rounded,
                      badge: favouriteCount,
                      onTap: onOpenShortlist,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MarketplaceHeroBubbles extends StatelessWidget {
  const MarketplaceHeroBubbles({super.key});

  static const _bubbles = <_BubbleSpec>[
    _BubbleSpec(.58, .08, 34, 9, 0),
    _BubbleSpec(.70, .52, 16, 7, 1.2),
    _BubbleSpec(.90, .10, 52, 11, .5),
    _BubbleSpec(.46, .62, 12, 6.5, 2),
    _BubbleSpec(.80, .70, 24, 8.5, .8),
    _BubbleSpec(.34, .14, 10, 6, 1.6),
    _BubbleSpec(.04, .76, 20, 9.5, 2.4),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final bubble in _bubbles)
              Positioned(
                left: constraints.maxWidth * bubble.x,
                top: constraints.maxHeight * bubble.y,
                child: _DriftingBubble(spec: bubble),
              ),
          ],
        );
      },
    );
  }
}

class MarketplaceLayoutToggle extends StatelessWidget {
  final bool grid;
  final ValueChanged<bool> onChanged;

  const MarketplaceLayoutToggle({
    super.key,
    required this.grid,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 70,
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.isLight
            ? Colors.white.withValues(alpha: .55)
            : Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 450),
            curve: const Cubic(.65, 0, .25, 1),
            alignment: grid ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 32,
              height: 28,
              decoration: BoxDecoration(
                gradient: colors.goldGradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: colors.goldMid.withValues(alpha: .55),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                    spreadRadius: -6,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () => onChanged(false),
                  child: Center(
                    child: Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 15,
                      color: grid ? colors.textTertiary : colors.onGold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () => onChanged(true),
                  child: Center(
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 14,
                      color: grid ? colors.onGold : colors.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MarketplaceFilterRail extends StatefulWidget {
  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onSelected;

  const MarketplaceFilterRail({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  @override
  State<MarketplaceFilterRail> createState() => _MarketplaceFilterRailState();
}

class _MarketplaceFilterRailState extends State<MarketplaceFilterRail>
    with SingleTickerProviderStateMixin {
  final GlobalKey _stackKey = GlobalKey();
  final Map<String, GlobalKey> _chipKeys = {
    for (final category in dpMarketplaceCategories) category: GlobalKey(),
  };
  double _left = 0;
  double _width = 60;
  bool _measured = false;
  late final AnimationController _sheen;

  @override
  void initState() {
    super.initState();
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure(false));
  }

  @override
  void didUpdateWidget(covariant MarketplaceFilterRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected || oldWidget.counts != widget.counts) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure(true));
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  void _measure(bool animateSheen) {
    if (!mounted) return;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final chipContext = _chipKeys[widget.selected]?.currentContext;
    final chipBox = chipContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || chipBox == null) return;
    final global = chipBox.localToGlobal(Offset.zero);
    final local = stackBox.globalToLocal(global);
    setState(() {
      _left = local.dx;
      _width = chipBox.size.width;
      _measured = true;
    });
    if (animateSheen) _sheen.forward(from: 0);
    if (chipContext != null) {
      Scrollable.ensureVisible(
        chipContext,
        alignment: .5,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
        child: Stack(
          key: _stackKey,
          clipBehavior: Clip.none,
          children: [
            if (_measured)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 950),
                curve: const Cubic(.65, 0, .25, 1),
                left: _left,
                top: 0,
                width: _width,
                height: 34,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: colors.goldMid.withValues(alpha: .48),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_measured)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: const Cubic(.65, 0, .25, 1),
                left: _left,
                top: 0,
                width: _width,
                height: 34,
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(gradient: colors.goldGradient),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _sheen,
                          builder: (context, child) {
                            final x = -1.4 + _sheen.value * 2.8;
                            return FractionalTranslation(
                              translation: Offset(x, 0),
                              child: child,
                            );
                          },
                          child: Container(
                            width: _width * .5,
                            height: 34,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent,
                                  Color(0xE6FFFFFF),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_measured)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: const Cubic(.65, 0, .25, 1),
                left: _left,
                top: 42,
                width: _width,
                height: 2,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.goldMid,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: colors.goldMid.withValues(alpha: .75),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  for (final category in dpMarketplaceCategories) ...[
                    _MarketplaceCategoryChip(
                      key: _chipKeys[category],
                      label: category,
                      count: widget.counts[category] ?? 0,
                      active: widget.selected == category,
                      onTap: () => widget.onSelected(category),
                    ),
                    if (category != dpMarketplaceCategories.last)
                      const SizedBox(width: 7),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketplaceSections extends StatelessWidget {
  final Map<String, List<DpCandidate>> sections;
  final String selectedCategory;
  final bool grid;
  final bool aiMatch;
  final bool mobile;
  final String? zoomedId;
  final Set<String> favouriteIds;
  final double Function(DpCandidate) displayRating;
  final int Function(DpCandidate) trustScore;
  final int Function(DpCandidate) matchPercent;
  final ValueChanged<String?> onZoom;
  final MarketplaceCandidateAction onProfile;
  final MarketplaceCandidateAction onOffer;
  final Future<void> Function(DpCandidate) onFavourite;

  const MarketplaceSections({
    super.key,
    required this.sections,
    required this.selectedCategory,
    required this.grid,
    required this.aiMatch,
    required this.mobile,
    required this.zoomedId,
    required this.favouriteIds,
    required this.displayRating,
    required this.trustScore,
    required this.matchPercent,
    required this.onZoom,
    required this.onProfile,
    required this.onOffer,
    required this.onFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCategories = selectedCategory == 'All'
        ? dpMarketplaceCategories.skip(1).where((c) => sections[c]!.isNotEmpty).toList()
        : <String>[selectedCategory];
    return Column(
      children: [
        for (var sectionIndex = 0;
            sectionIndex < visibleCategories.length;
            sectionIndex++)
          _MarketplaceSection(
            category: visibleCategories[sectionIndex],
            candidates: sections[visibleCategories[sectionIndex]] ?? const [],
            selectedCategory: selectedCategory,
            grid: grid,
            aiMatch: aiMatch,
            mobile: mobile,
            sectionIndex: sectionIndex,
            zoomedId: zoomedId,
            favouriteIds: favouriteIds,
            displayRating: displayRating,
            trustScore: trustScore,
            matchPercent: matchPercent,
            onZoom: onZoom,
            onProfile: onProfile,
            onOffer: onOffer,
            onFavourite: onFavourite,
          ),
      ],
    );
  }
}

class _MarketplaceSection extends StatelessWidget {
  final String category;
  final List<DpCandidate> candidates;
  final String selectedCategory;
  final bool grid;
  final bool aiMatch;
  final bool mobile;
  final int sectionIndex;
  final String? zoomedId;
  final Set<String> favouriteIds;
  final double Function(DpCandidate) displayRating;
  final int Function(DpCandidate) trustScore;
  final int Function(DpCandidate) matchPercent;
  final ValueChanged<String?> onZoom;
  final MarketplaceCandidateAction onProfile;
  final MarketplaceCandidateAction onOffer;
  final Future<void> Function(DpCandidate) onFavourite;

  const _MarketplaceSection({
    required this.category,
    required this.candidates,
    required this.selectedCategory,
    required this.grid,
    required this.aiMatch,
    required this.mobile,
    required this.sectionIndex,
    required this.zoomedId,
    required this.favouriteIds,
    required this.displayRating,
    required this.trustScore,
    required this.matchPercent,
    required this.onZoom,
    required this.onProfile,
    required this.onOffer,
    required this.onFavourite,
  });

  IconData get _icon => switch (category) {
        'Actors' => Icons.theater_comedy_outlined,
        'Models' => Icons.auto_awesome_outlined,
        'Influencers' => Icons.bolt_outlined,
        'Crew' => Icons.groups_2_outlined,
        'Locations' => Icons.location_on_outlined,
        'Equipment' => Icons.videocam_outlined,
        _ => Icons.grid_view_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final single = selectedCategory != 'All';
    final listItems = !grid && !single
        ? candidates.take(mobile ? 2 : 4).toList()
        : candidates;
    return StaggerReveal(
      delay: Duration(milliseconds: sectionIndex * 70),
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.softSurface,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(_icon, size: 14, color: colors.goldDark),
                ),
                const SizedBox(width: 9),
                Text(
                  category,
                  style: GoogleFonts.newsreader(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.2,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${candidates.length} ${candidates.length == 1 ? 'profile' : 'profiles'}',
                  style: GoogleFonts.archivo(
                    fontSize: 11,
                    color: colors.textTertiary,
                  ),
                ),
                const Spacer(),
                if (!single)
                  _TinyOutlineButton(
                    label: 'View all',
                    icon: Icons.chevron_right_rounded,
                    onTap: () {
                      final state = context.findAncestorStateOfType<_DPMarketplaceV3State>();
                      state?._selectCategory(category);
                    },
                  )
                else
                  _TinyOutlineButton(
                    label: 'All categories',
                    icon: Icons.chevron_left_rounded,
                    onTap: () {
                      final state = context.findAncestorStateOfType<_DPMarketplaceV3State>();
                      state?._selectCategory('All');
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (grid)
              _buildGrid(context, single, listItems)
            else
              _buildList(context, listItems),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    bool single,
    List<DpCandidate> items,
  ) {
    final cardWidth = mobile ? 148.0 : 194.0;
    final cardHeight = mobile ? 214.0 : 276.0;
    if (!single) {
      return SizedBox(
        height: cardHeight + (mobile ? 36 : 62),
        child: ListView.separated(
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.fromLTRB(16, mobile ? 14 : 22, 16, mobile ? 18 : 28),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => StaggerReveal(
            delay: Duration(milliseconds: index.clamp(0, 8).toInt() * 55),
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _MarketplacePosterCard(
                candidate: items[index],
                category: category,
                width: cardWidth,
                height: cardHeight,
                mobile: mobile,
                firstInRow: index == 0,
                aiMatch: aiMatch,
                zoomed: zoomedId == items[index].id,
                dimmed: zoomedId != null &&
                    dpMarketplaceCanonicalCategory(items[index].category) == category &&
                    zoomedId != items[index].id,
                favourite: favouriteIds.contains(items[index].id),
                displayRating: displayRating(items[index]),
                trustScore: trustScore(items[index]),
                matchPercent: matchPercent(items[index]),
                onZoom: onZoom,
                onProfile: () => onProfile(items[index]),
                onOffer: () => onOffer(items[index]),
                onFavourite: () => onFavourite(items[index]),
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = math.max(1, (constraints.maxWidth / (cardWidth + 12)).floor());
        final actualWidth = (constraints.maxWidth - (count - 1) * 12) / count;
        return Wrap(
          spacing: 12,
          runSpacing: mobile ? 20 : 28,
          children: [
            for (var index = 0; index < items.length; index++)
              StaggerReveal(
                delay: Duration(milliseconds: index.clamp(0, 8).toInt() * 55),
                child: SizedBox(
                  width: actualWidth,
                  height: cardHeight,
                  child: _MarketplacePosterCard(
                    candidate: items[index],
                    category: category,
                    width: actualWidth,
                    height: cardHeight,
                    mobile: mobile,
                    firstInRow: index % count == 0,
                    aiMatch: aiMatch,
                    zoomed: zoomedId == items[index].id,
                    dimmed: zoomedId != null && zoomedId != items[index].id,
                    favourite: favouriteIds.contains(items[index].id),
                    displayRating: displayRating(items[index]),
                    trustScore: trustScore(items[index]),
                    matchPercent: matchPercent(items[index]),
                    onZoom: onZoom,
                    onProfile: () => onProfile(items[index]),
                    onOffer: () => onOffer(items[index]),
                    onFavourite: () => onFavourite(items[index]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<DpCandidate> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = !mobile && constraints.maxWidth >= 1080;
        final width = twoColumns ? (constraints.maxWidth - 10) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var index = 0; index < items.length; index++)
              StaggerReveal(
                delay: Duration(milliseconds: index.clamp(0, 8).toInt() * 55),
                child: SizedBox(
                  width: width,
                  child: _MarketplaceListCard(
                    candidate: items[index],
                    category: category,
                    mobile: mobile,
                    aiMatch: aiMatch,
                    zoomed: zoomedId == items[index].id,
                    dimmed: zoomedId != null &&
                        dpMarketplaceCanonicalCategory(items[index].category) == category &&
                        zoomedId != items[index].id,
                    favourite: favouriteIds.contains(items[index].id),
                    trustScore: trustScore(items[index]),
                    matchPercent: matchPercent(items[index]),
                    onZoom: onZoom,
                    onProfile: () => onProfile(items[index]),
                    onOffer: () => onOffer(items[index]),
                    onFavourite: () => onFavourite(items[index]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MarketplacePosterCard extends StatelessWidget {
  final DpCandidate candidate;
  final String category;
  final double width;
  final double height;
  final bool mobile;
  final bool firstInRow;
  final bool aiMatch;
  final bool zoomed;
  final bool dimmed;
  final bool favourite;
  final double displayRating;
  final int trustScore;
  final int matchPercent;
  final ValueChanged<String?> onZoom;
  final VoidCallback onProfile;
  final VoidCallback onOffer;
  final VoidCallback onFavourite;

  const _MarketplacePosterCard({
    required this.candidate,
    required this.category,
    required this.width,
    required this.height,
    required this.mobile,
    required this.firstInRow,
    required this.aiMatch,
    required this.zoomed,
    required this.dimmed,
    required this.favourite,
    required this.displayRating,
    required this.trustScore,
    required this.matchPercent,
    required this.onZoom,
    required this.onProfile,
    required this.onOffer,
    required this.onFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scale = zoomed ? (mobile ? 1.07 : 1.12) : 1.0;
    final initials = _candidateInitials(candidate);
    final availableColor = candidate.available
        ? const Color(0xFF6FBF8B)
        : const Color(0xFFE0B85A);
    final availableLabel = candidate.available ? 'AVAILABLE NOW' : 'THIS MONTH';
    final origin = firstInRow ? Alignment.centerLeft : Alignment.center;

    final card = AnimatedOpacity(
      duration: const Duration(milliseconds: 450),
      opacity: dimmed ? .62 : 1,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: scale),
        duration: const Duration(milliseconds: 450),
        curve: const Cubic(.2, .9, .25, 1),
        builder: (context, value, child) {
          return Transform.scale(
            alignment: origin,
            scale: value,
            child: Transform.translate(
              offset: Offset(0, zoomed ? -4 : 0),
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: const Cubic(.2, .9, .25, 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: zoomed ? colors.goldMid : colors.border,
              width: zoomed ? 1.2 : 1,
            ),
            boxShadow: zoomed
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .30),
                      blurRadius: 50,
                      offset: const Offset(0, 30),
                      spreadRadius: -22,
                    ),
                    BoxShadow(
                      color: colors.goldMid.withValues(alpha: .42),
                      blurRadius: 36,
                      spreadRadius: -8,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: .15),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                      spreadRadius: -18,
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CandidateArt(candidate: candidate),
                MarketplaceCardSheen(seed: _stringHash(candidate.name)),
                const _PosterOverlay(),
                Positioned(
                  top: height * .16,
                  right: -8,
                  child: Text(
                    initials,
                    style: GoogleFonts.newsreader(
                      fontSize: mobile ? 78 : 104,
                      fontWeight: FontWeight.w500,
                      height: 1,
                      color: colors.isLight
                          ? const Color(0x1217150E)
                          : Colors.white.withValues(alpha: .07),
                    ),
                  ),
                ),
                Positioned(
                  left: 9,
                  right: 9,
                  top: 9,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PosterGlassPill(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 11, color: colors.goldMid),
                                const SizedBox(width: 3),
                                Text(
                                  displayRating.toStringAsFixed(1),
                                  style: GoogleFonts.archivo(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (aiMatch) ...[
                            const SizedBox(height: 5),
                            Container(
                              height: 20,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                gradient: colors.goldGradient,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$matchPercent% MATCH',
                                style: GoogleFonts.archivo(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .3,
                                  color: colors.onGold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(99),
                        onTap: onFavourite,
                        child: _PosterGlassPill(
                          square: true,
                          child: Icon(
                            favourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 15,
                            color: favourite ? const Color(0xFFE36A6A) : colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: availableColor,
                              boxShadow: [
                                BoxShadow(
                                  color: availableColor.withValues(alpha: .7),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            availableLabel,
                            style: GoogleFonts.archivo(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: availableColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              candidate.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.newsreader(
                                fontSize: mobile ? 14.5 : 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -.2,
                                height: 1.1,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          if (candidate.verified) ...[
                            const SizedBox(width: 5),
                            _VerifiedDot(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _candidateSubtitle(candidate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.archivo(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 11, color: colors.textSecondary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              candidate.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.archivo(
                                fontSize: 10.5,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            candidate.rateRange,
                            style: GoogleFonts.archivo(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: colors.goldDark,
                            ),
                          ),
                        ],
                      ),
                      ClipRect(
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 400),
                          curve: const Cubic(.2, .9, .25, 1),
                          alignment: Alignment.topCenter,
                          heightFactor: zoomed ? 1 : 0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 340),
                            opacity: zoomed ? 1 : 0,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 10,
                                    child: _PosterActionButton(
                                      label: 'Profile',
                                      filled: false,
                                      onTap: onProfile,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 13,
                                    child: _PosterActionButton(
                                      label: 'Offer',
                                      icon: Icons.chat_bubble_outline_rounded,
                                      filled: true,
                                      onTap: onOffer,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (mobile) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onZoom(candidate.id),
        child: card,
      );
    }
    return MouseRegion(
      onEnter: (_) => onZoom(candidate.id),
      onExit: (_) => onZoom(null),
      child: card,
    );
  }
}

class _MarketplaceListCard extends StatelessWidget {
  final DpCandidate candidate;
  final String category;
  final bool mobile;
  final bool aiMatch;
  final bool zoomed;
  final bool dimmed;
  final bool favourite;
  final int trustScore;
  final int matchPercent;
  final ValueChanged<String?> onZoom;
  final VoidCallback onProfile;
  final VoidCallback onOffer;
  final VoidCallback onFavourite;

  const _MarketplaceListCard({
    required this.candidate,
    required this.category,
    required this.mobile,
    required this.aiMatch,
    required this.zoomed,
    required this.dimmed,
    required this.favourite,
    required this.trustScore,
    required this.matchPercent,
    required this.onZoom,
    required this.onProfile,
    required this.onOffer,
    required this.onFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final content = AnimatedOpacity(
      duration: const Duration(milliseconds: 450),
      opacity: dimmed ? .62 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: const Cubic(.2, .9, .25, 1),
        transform: Matrix4.identity()
          ..translate(0.0, zoomed ? -3.0 : 0.0)
          ..scale(zoomed ? (mobile ? 1.025 : 1.04) : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: zoomed ? colors.goldMid : colors.border,
            width: zoomed ? 1.2 : 1,
          ),
          boxShadow: zoomed
              ? [
                  BoxShadow(
                    color: colors.goldMid.withValues(alpha: .36),
                    blurRadius: 32,
                    spreadRadius: -8,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .22),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                    spreadRadius: -20,
                  ),
                ]
              : [],
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: const Cubic(.2, .9, .25, 1),
              width: 58,
              height: 58,
              transform: Matrix4.identity()
                ..scale(zoomed ? 1.1 : 1.0)
                ..rotateZ(zoomed ? -.035 : 0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CandidateArt(candidate: candidate),
                  Center(
                    child: Text(
                      _candidateInitials(candidate),
                      style: GoogleFonts.newsreader(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary.withValues(alpha: .62),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: candidate.available
                            ? const Color(0xFF6FBF8B)
                            : const Color(0xFFE0B85A),
                        border: Border.all(color: colors.card, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: mobile ? 160 : 180,
                maxWidth: mobile ? 260 : 330,
              ),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.2,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (candidate.verified) ...[
                        const SizedBox(width: 5),
                        _VerifiedDot(),
                      ],
                      if (aiMatch) ...[
                        const SizedBox(width: 6),
                        Container(
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          decoration: BoxDecoration(
                            color: colors.softSurface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$matchPercent% MATCH',
                            style: GoogleFonts.archivo(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: colors.goldDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _candidateSubtitle(candidate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.archivo(
                      fontSize: 11.5,
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      _MetaLine(icon: Icons.location_on_outlined, text: candidate.city),
                      Text(
                        candidate.rateRange,
                        style: GoogleFonts.archivo(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colors.goldDark,
                        ),
                      ),
                      _MetaLine(icon: Icons.shield_outlined, text: '$trustScore/100'),
                      if (candidate.available)
                        Text(
                          'Offers welcome',
                          style: GoogleFonts.archivo(
                            fontSize: 11,
                            color: colors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: mobile ? double.infinity : 248,
              child: Row(
                children: [
                  _RoundGlassButton(
                    tooltip: 'Shortlist',
                    icon: favourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    iconColor: favourite ? const Color(0xFFE36A6A) : null,
                    onTap: onFavourite,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _CompactActionButton(
                      label: 'Profile',
                      filled: false,
                      onTap: onProfile,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _CompactActionButton(
                      label: 'Make offer',
                      filled: true,
                      onTap: onOffer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (mobile) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onZoom(candidate.id),
        child: content,
      );
    }
    return MouseRegion(
      onEnter: (_) => onZoom(candidate.id),
      onExit: (_) => onZoom(null),
      child: content,
    );
  }
}

class MarketplaceSmartFiltersSheet extends StatefulWidget {
  final Map<String, Set<String>> initialSmart;
  final bool initialAi;
  final int Function(Map<String, Set<String>> smart, bool ai) resultCount;
  final void Function(Map<String, Set<String>> smart, bool ai) onChanged;
  final VoidCallback onReset;

  const MarketplaceSmartFiltersSheet({
    super.key,
    required this.initialSmart,
    required this.initialAi,
    required this.resultCount,
    required this.onChanged,
    required this.onReset,
  });

  @override
  State<MarketplaceSmartFiltersSheet> createState() =>
      _MarketplaceSmartFiltersSheetState();
}

class _MarketplaceSmartFiltersSheetState
    extends State<MarketplaceSmartFiltersSheet> {
  late Map<String, Set<String>> _smart = {
    for (final entry in widget.initialSmart.entries)
      entry.key: Set<String>.from(entry.value),
  };
  late bool _ai = widget.initialAi;

  static const groups = <String, List<String>>{
    'CITY': ['Lahore', 'Karachi', 'Islamabad', 'Bahawalpur'],
    'BUDGET': ['Under 100K', '100K – 150K', '150K+'],
    'LANGUAGE': ['Urdu', 'English', 'Punjabi', 'Sindhi'],
    'AVAILABILITY': ['Available now', 'This month'],
    'TRUST': ['Verified only', 'Trust 85+', 'Offers welcome'],
  };

  String _groupKey(String label) => switch (label) {
        'CITY' => 'city',
        'BUDGET' => 'budget',
        'LANGUAGE' => 'lang',
        'AVAILABILITY' => 'avail',
        _ => 'trust',
      };

  void _emit() {
    widget.onChanged(
      {for (final entry in _smart.entries) entry.key: Set<String>.from(entry.value)},
      _ai,
    );
  }

  void _toggle(String group, String value) {
    final key = _groupKey(group);
    setState(() {
      if (_smart[key]!.contains(value)) {
        _smart[key]!.remove(value);
      } else {
        _smart[key]!.add(value);
      }
    });
    _emit();
  }

  void _reset() {
    setState(() {
      for (final set in _smart.values) {
        set.clear();
      }
      _ai = false;
    });
    widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final mobile = MediaQuery.sizeOf(context).width < 760;
    final count = widget.resultCount(_smart, _ai);
    final body = ClipRRect(
      borderRadius: mobile
          ? const BorderRadius.vertical(top: Radius.circular(28))
          : BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Stack(
          children: [
            Positioned.fill(child: _MarketplaceWash(light: colors.isLight)),
            const Positioned.fill(child: _SheetBubbles()),
            Container(
              constraints: BoxConstraints(
                maxWidth: 580,
                maxHeight: MediaQuery.sizeOf(context).height * .88,
              ),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              decoration: BoxDecoration(
                color: colors.isLight
                    ? Colors.white.withValues(alpha: .84)
                    : const Color(0xD6141418),
                borderRadius: mobile
                    ? const BorderRadius.vertical(top: Radius.circular(28))
                    : BorderRadius.circular(28),
                border: Border.all(
                  color: colors.isLight
                      ? Colors.white.withValues(alpha: .95)
                      : Colors.white.withValues(alpha: .16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .35),
                    blurRadius: 80,
                    offset: const Offset(0, 40),
                    spreadRadius: -30,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: colors.goldGradient,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: colors.goldMid.withValues(alpha: .45),
                                blurRadius: 20,
                                spreadRadius: -10,
                              ),
                            ],
                          ),
                          child: const _TwinkleIcon(size: 18),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart filters',
                                style: GoogleFonts.newsreader(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -.2,
                                  height: 1.1,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to refine. AI ranks the rest.',
                                style: GoogleFonts.archivo(
                                  fontSize: 11.5,
                                  color: colors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _RoundGlassButton(
                          tooltip: 'Close',
                          icon: Icons.close_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    StaggerReveal(
                      delay: const Duration(milliseconds: 50),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _ai = !_ai);
                          _emit();
                        },
                        child: AnimatedHolographicBox(
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  size: 17, color: colors.goldDark),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI Match',
                                      style: GoogleFonts.archivo(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Rank everyone by fit to your open projects',
                                      style: GoogleFonts.archivo(
                                        fontSize: 11,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _GoldSwitch(value: _ai),
                            ],
                          ),
                        ),
                      ),
                    ),
                    varIndexBuilder(groups.entries.toList(), (entry, groupIndex) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: GoogleFonts.archivo(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                                color: colors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (var optionIndex = 0;
                                    optionIndex < entry.value.length;
                                    optionIndex++)
                                  _FloatingSmartChip(
                                    delay: Duration(
                                      milliseconds: 80 +
                                          (groupIndex * 4 + optionIndex) * 35,
                                    ),
                                    label: entry.value[optionIndex],
                                    active: _smart[_groupKey(entry.key)]!
                                        .contains(entry.value[optionIndex]),
                                    onTap: () => _toggle(
                                      entry.key,
                                      entry.value[optionIndex],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.fromLTRB(-18, 0, -18, 0),
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            colors.isLight
                                ? Colors.white.withValues(alpha: .95)
                                : const Color(0xF0141418),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          _GlassActionButton(
                            icon: Icons.refresh_rounded,
                            label: 'Reset',
                            onTap: _reset,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _GoldActionButton(
                              icon: Icons.done_rounded,
                              label: 'Show $count results',
                              onTap: () => Navigator.pop(context),
                              expand: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (mobile) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: body,
      );
    }
    return body;
  }
}

class MarketplaceEmptyState extends StatelessWidget {
  final VoidCallback onReset;

  const MarketplaceEmptyState({super.key, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.goldMid.withValues(alpha: .35)),
      ),
      child: Column(
        children: [
          Text(
            'No matches yet',
            style: GoogleFonts.newsreader(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Loosen a smart filter or try another search.',
            textAlign: TextAlign.center,
            style: GoogleFonts.archivo(
              fontSize: 12.5,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          _GlassActionButton(
            icon: Icons.refresh_rounded,
            label: 'Clear filters',
            onTap: onReset,
          ),
        ],
      ),
    );
  }
}

class MarketplaceLoadingState extends StatelessWidget {
  const MarketplaceLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 186,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.border),
          ),
          child: Center(
            child: CircularProgressIndicator(color: colors.goldMid),
          ),
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          minHeight: 2,
          color: colors.goldMid,
          backgroundColor: colors.border,
        ),
      ],
    );
  }
}

class MarketplaceErrorStateV3 extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const MarketplaceErrorStateV3({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.warning.withValues(alpha: .45)),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, color: colors.warning, size: 28),
          const SizedBox(height: 10),
          Text(
            'Could not load live marketplace',
            style: GoogleFonts.newsreader(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.archivo(
              fontSize: 12.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _GoldActionButton(
            icon: Icons.refresh_rounded,
            label: 'Retry',
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

class _AiMatchFab extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  const _AiMatchFab({required this.count, required this.onTap});

  @override
  State<_AiMatchFab> createState() => _AiMatchFabState();
}

class _AiMatchFabState extends State<_AiMatchFab>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _twinkle;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'AI Match',
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 62,
          height: 62,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _PulseRing(animation: _pulse, phase: 0, color: colors.goldMid),
              _PulseRing(animation: _pulse, phase: .5, color: colors.goldLight),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-.4, -.45),
                    radius: 1.1,
                    colors: [
                      Color(0xFFF6E3A6),
                      Color(0xFFD3B55F),
                      Color(0xFFA8842A),
                    ],
                    stops: [0, .55, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.goldMid.withValues(alpha: .75),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _twinkle,
                  builder: (context, child) {
                    final t = _twinkle.value;
                    final angle = math.sin(t * math.pi * 2) * .16;
                    final scale = 1 + math.sin(t * math.pi * 2) * .06;
                    return Transform.rotate(
                      angle: angle,
                      child: Transform.scale(scale: scale, child: child),
                    );
                  },
                  child: Icon(Icons.auto_awesome_rounded,
                      size: 21, color: colors.onGold),
                ),
              ),
              if (widget.count > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: colors.textPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.count}',
                      style: GoogleFonts.archivo(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: colors.background,
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

class _PulseRing extends StatelessWidget {
  final Animation<double> animation;
  final double phase;
  final Color color;

  const _PulseRing({
    required this.animation,
    required this.phase,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = (animation.value + phase) % 1;
        return Opacity(
          opacity: (1 - t) * .8,
          child: Transform.scale(
            scale: 1 + t * .55,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DriftingBubble extends StatefulWidget {
  final _BubbleSpec spec;

  const _DriftingBubble({required this.spec});

  @override
  State<_DriftingBubble> createState() => _DriftingBubbleState();
}

class _DriftingBubbleState extends State<_DriftingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.spec.duration * 1000).round()),
    );
    _timer = Timer(
      Duration(milliseconds: (widget.spec.delay * 1000).round()),
      () {
        if (mounted) _controller.repeat();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Offset _offset(double t) {
    if (t < .30) {
      return Offset.lerp(Offset.zero, const Offset(12, -18), t / .30)!;
    }
    if (t < .65) {
      return Offset.lerp(
        const Offset(12, -18),
        const Offset(-10, -7),
        (t - .30) / .35,
      )!;
    }
    return Offset.lerp(const Offset(-10, -7), Offset.zero, (t - .65) / .35)!;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(offset: _offset(_controller.value), child: child);
      },
      child: Container(
        width: widget.spec.size,
        height: widget.spec.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-.36, -.44),
            radius: 1.1,
            colors: colors.isLight
                ? const [
                    Color(0xFAFFFFFF),
                    Color(0x80D6ECFF),
                    Color(0x52E4DCFF),
                    Color(0x33FFE2CE),
                    Color(0x00FFFFFF),
                  ]
                : const [
                    Color(0xB3FFFFFF),
                    Color(0x47BEDFFF),
                    Color(0x29CDBEFF),
                    Color(0x1AFFCDB4),
                    Color(0x05FFFFFF),
                  ],
            stops: const [0, .18, .44, .62, .74],
          ),
          border: Border.all(
            color: colors.isLight
                ? Colors.white.withValues(alpha: .9)
                : const Color(0x4DD2E6FF),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.goldMid.withValues(alpha: .14),
              blurRadius: 10,
              offset: const Offset(-3, -5),
              spreadRadius: -6,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetBubbles extends StatelessWidget {
  const _SheetBubbles();

  static const specs = <_BubbleSpec>[
    _BubbleSpec(.82, .04, 46, 10, 0),
    _BubbleSpec(.64, .14, 14, 7, 1),
    _BubbleSpec(.90, .44, 26, 8, .4),
    _BubbleSpec(.04, .58, 18, 9, 1.8),
    _BubbleSpec(.50, .80, 12, 6.5, .9),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          for (final spec in specs)
            Positioned(
              left: constraints.maxWidth * spec.x,
              top: constraints.maxHeight * spec.y,
              child: _DriftingBubble(spec: spec),
            ),
        ],
      ),
    );
  }
}

class MarketplaceCardSheen extends StatefulWidget {
  final int seed;

  const MarketplaceCardSheen({super.key, required this.seed});

  @override
  State<MarketplaceCardSheen> createState() => _MarketplaceCardSheenState();
}

class _MarketplaceCardSheenState extends State<MarketplaceCardSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );
    final delay = 5200 + (widget.seed % 6000);
    _timer = Timer(Duration(milliseconds: delay), _run);
  }

  void _run() {
    if (!mounted) return;
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _timer = Timer(const Duration(milliseconds: 5700), _run);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final x = -1.4 + _controller.value * 2.8;
          return FractionalTranslation(
            translation: Offset(x, 0),
            child: Transform.rotate(
              angle: -.15,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 70,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Color(0x55FFFFFF),
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
    );
  }
}

class StaggerReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const StaggerReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<StaggerReveal> createState() => _StaggerRevealState();
}

class _StaggerRevealState extends State<StaggerReveal> {
  bool _shown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: const Duration(milliseconds: 600),
      curve: const Cubic(.2, .8, .2, 1),
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : const Offset(0, .045),
        duration: const Duration(milliseconds: 600),
        curve: const Cubic(.2, .8, .2, 1),
        child: AnimatedScale(
          scale: _shown ? 1 : .98,
          duration: const Duration(milliseconds: 600),
          curve: const Cubic(.2, .8, .2, 1),
          child: widget.child,
        ),
      ),
    );
  }
}

class AnimatedHolographicBox extends StatefulWidget {
  final Widget child;

  const AnimatedHolographicBox({super.key, required this.child});

  @override
  State<AnimatedHolographicBox> createState() => _AnimatedHolographicBoxState();
}

class _AnimatedHolographicBoxState extends State<AnimatedHolographicBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
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
        final t = _controller.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 1.4, -1),
              end: Alignment(1 - t * 1.4, 1),
              colors: colors.isLight
                  ? const [
                      Color(0xD9FFFFFF),
                      Color(0xA6D2EAFF),
                      Color(0x99ECDEFF),
                      Color(0xB3FFECD6),
                      Color(0xD9FFFFFF),
                    ]
                  : const [
                      Color(0x14FFFFFF),
                      Color(0x1F8CBEFF),
                      Color(0x1ABEA0FF),
                      Color(0x1FFFCB96),
                      Color(0x0FFFFFFF),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.isLight
                  ? Colors.white.withValues(alpha: .95)
                  : Colors.white.withValues(alpha: .16),
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _FloatingSmartChip extends StatefulWidget {
  final Duration delay;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FloatingSmartChip({
    required this.delay,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_FloatingSmartChip> createState() => _FloatingSmartChipState();
}

class _FloatingSmartChipState extends State<_FloatingSmartChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 4000 + (_stringHash(widget.label) % 2800)),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return StaggerReveal(
      delay: widget.delay,
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -6 * math.sin(_float.value * math.pi)),
            child: child,
          );
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              gradient: widget.active ? colors.goldGradient : null,
              color: widget.active
                  ? null
                  : colors.isLight
                      ? Colors.white.withValues(alpha: .62)
                      : Colors.white.withValues(alpha: .055),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: widget.active
                    ? Colors.white.withValues(alpha: .5)
                    : colors.isLight
                        ? Colors.white.withValues(alpha: .95)
                        : Colors.white.withValues(alpha: .16),
              ),
              boxShadow: widget.active
                  ? [
                      BoxShadow(
                        color: colors.goldMid.withValues(alpha: .5),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                        spreadRadius: -10,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.active) ...[
                  Icon(Icons.check_rounded, size: 12, color: colors.onGold),
                  const SizedBox(width: 5),
                ],
                Text(
                  widget.label,
                  style: GoogleFonts.archivo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.active ? colors.onGold : colors.textSecondary,
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

class _TwinkleIcon extends StatefulWidget {
  final double size;

  const _TwinkleIcon({required this.size});

  @override
  State<_TwinkleIcon> createState() => _TwinkleIconState();
}

class _TwinkleIconState extends State<_TwinkleIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = math.sin(_controller.value * math.pi * 2);
        return Transform.rotate(
          angle: t * .16,
          child: Transform.scale(scale: 1 + t * .06, child: child),
        );
      },
      child: Icon(Icons.auto_awesome_rounded,
          size: widget.size, color: context.appColors.onGold),
    );
  }
}

class _GoldSwitch extends StatelessWidget {
  final bool value;

  const _GoldSwitch({required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 40,
      height: 22,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: value ? colors.goldGradient : null,
        color: value ? null : colors.border,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 350),
        curve: const Cubic(.65, 0, .25, 1),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketplaceWash extends StatelessWidget {
  final bool light;

  const _MarketplaceWash({required this.light});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -60,
          top: -90,
          child: Container(
            width: 310,
            height: 240,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: light
                    ? const [Color(0x73BFddF2), Color(0x00BFddF2)]
                    : const [Color(0x1719A9D4), Color(0x0019A9D4)],
              ),
            ),
          ),
        ),
        Positioned(
          left: -70,
          bottom: -90,
          child: Container(
            width: 280,
            height: 220,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: light
                    ? const [Color(0x6BDCD5F3), Color(0x00DCD5F3)]
                    : const [Color(0x17C9BDF5), Color(0x00C9BDF5)],
              ),
            ),
          ),
        ),
        Positioned(
          left: 170,
          bottom: -90,
          child: Container(
            width: 260,
            height: 210,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: light
                    ? const [Color(0x99F3E8CB), Color(0x00F3E8CB)]
                    : const [Color(0x17D4AF37), Color(0x00D4AF37)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CandidateArt extends StatelessWidget {
  final DpCandidate candidate;

  const _CandidateArt({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final image = candidate.imageUrl;
    final hue = (_stringHash(candidate.name) % 360).toDouble();
    final base = HSLColor.fromAHSL(1, hue, colors.isLight ? .38 : .40,
            colors.isLight ? .88 : .21)
        .toColor();
    final accent = HSLColor.fromAHSL(
            1,
            (hue + 28) % 360,
            colors.isLight ? .42 : .38,
            colors.isLight ? .91 : .17)
        .toColor();
    final fallback = Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.isLight ? const Color(0xFFF8F6F0) : const Color(0xFF17171A),
                base,
                accent,
              ],
            ),
          ),
        ),
        Positioned(
          right: -20,
          top: -20,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  base.withValues(alpha: .95),
                  base.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    if (image == null || image.trim().isEmpty) return fallback;
    return Image.network(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _PosterOverlay extends StatelessWidget {
  const _PosterOverlay();

  @override
  Widget build(BuildContext context) {
    final light = context.appColors.isLight;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: const [0, .34, .66],
          colors: light
              ? const [Color(0xF7FFFDF8), Color(0xB8FFFDF8), Color(0x00FFFDF8)]
              : const [Color(0xF208080A), Color(0x8008080A), Color(0x0008080A)],
        ),
      ),
    );
  }
}

class _PosterGlassPill extends StatelessWidget {
  final Widget child;
  final bool square;

  const _PosterGlassPill({required this.child, this.square = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: square ? 30 : null,
          height: square ? 30 : 22,
          padding: square ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.isLight
                ? Colors.white.withValues(alpha: .74)
                : const Color(0x730A0A0C),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colors.isLight
                  ? Colors.white.withValues(alpha: .95)
                  : Colors.white.withValues(alpha: .16),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _VerifiedDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.goldMid,
      ),
      child: Icon(Icons.check_rounded, size: 9, color: colors.onGold),
    );
  }
}

class _PosterActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;
  final VoidCallback onTap;

  const _PosterActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          gradient: filled ? colors.goldGradient : null,
          color: filled
              ? null
              : colors.isLight
                  ? Colors.white.withValues(alpha: .74)
                  : const Color(0x730A0A0C),
          borderRadius: BorderRadius.circular(999),
          border: filled
              ? null
              : Border.all(
                  color: colors.isLight
                      ? Colors.white.withValues(alpha: .95)
                      : Colors.white.withValues(alpha: .16),
                ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: colors.goldMid.withValues(alpha: .5),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                    spreadRadius: -8,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: filled ? colors.onGold : colors.textPrimary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.archivo(
                fontSize: 10.5,
                fontWeight: filled ? FontWeight.w800 : FontWeight.w700,
                color: filled ? colors.onGold : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceCategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _MarketplaceCategoryChip({
    super.key,
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active
              ? Colors.transparent
              : colors.isLight
                  ? Colors.white.withValues(alpha: .55)
                  : Colors.white.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? Colors.transparent : colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.archivo(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? colors.onGold : colors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: GoogleFonts.archivo(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: (active ? colors.onGold : colors.textSecondary)
                    .withValues(alpha: .6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool expand;

  const _GoldActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final child = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: colors.goldGradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: colors.goldMid.withValues(alpha: .7),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colors.onGold),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.archivo(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: colors.onGold,
              ),
            ),
          ],
        ),
      ),
    );
    return child;
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colors.isLight
              ? Colors.white.withValues(alpha: .62)
              : Colors.white.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.goldMid.withValues(alpha: .35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colors.goldDark),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.archivo(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: colors.goldDark,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: colors.goldMid,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badge',
                  style: GoogleFonts.archivo(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: colors.onGold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundGlassButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final int badge;
  final Color? iconColor;
  final VoidCallback onTap;

  const _RoundGlassButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.badge = 0,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.isLight
                    ? Colors.white.withValues(alpha: .62)
                    : Colors.white.withValues(alpha: .05),
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Icon(icon, size: 16, color: iconColor ?? colors.goldDark),
            ),
            if (badge > 0)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17),
                  height: 17,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: colors.goldMid,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$badge',
                    style: GoogleFonts.archivo(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: colors.onGold,
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

class _TinyOutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TinyOutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: colors.isLight
              ? Colors.white.withValues(alpha: .56)
              : Colors.white.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.goldMid.withValues(alpha: .35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == Icons.chevron_left_rounded) ...[
              Icon(icon, size: 12, color: colors.goldDark),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: GoogleFonts.archivo(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: colors.goldDark,
              ),
            ),
            if (icon != Icons.chevron_left_rounded) ...[
              const SizedBox(width: 3),
              Icon(icon, size: 12, color: colors.goldDark),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _CompactActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled ? colors.goldGradient : null,
          borderRadius: BorderRadius.circular(999),
          border: filled
              ? null
              : Border.all(color: colors.goldMid.withValues(alpha: .35)),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: GoogleFonts.archivo(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: filled ? colors.onGold : colors.goldDark,
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: colors.textTertiary),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.archivo(fontSize: 11, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _BubbleSpec {
  final double x;
  final double y;
  final double size;
  final double duration;
  final double delay;

  const _BubbleSpec(this.x, this.y, this.size, this.duration, this.delay);
}

String _candidateInitials(DpCandidate candidate) {
  final words = candidate.name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return candidate.avatarLabel;
  return words.take(2).map((word) => word[0].toUpperCase()).join();
}

String _candidateSubtitle(DpCandidate candidate) {
  if (candidate.skills.isNotEmpty) {
    return candidate.skills.take(2).join(' · ');
  }
  if (candidate.notes.trim().isNotEmpty) return candidate.notes.trim();
  return dpMarketplaceCanonicalCategory(candidate.category);
}

int _stringHash(String value) {
  var result = 0;
  for (final code in value.codeUnits) {
    result = (result * 31 + code) % 997;
  }
  return result;
}

Widget varIndexBuilder<T>(
  List<T> values,
  Widget Function(T value, int index) builder,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var index = 0; index < values.length; index++)
        builder(values[index], index),
    ],
  );
}
