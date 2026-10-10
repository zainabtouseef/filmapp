import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/cineplanner/cineplanner_controller.dart';

class DPCinePlannerV3 extends StatefulWidget {
  final CinePlannerController controller;
  final Map<String, dynamic> snapshot;
  final Future<void> Function() onUploadScript;
  final Future<void> Function() onNewProject;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onScriptConsole;

  const DPCinePlannerV3({
    super.key,
    required this.controller,
    required this.snapshot,
    required this.onUploadScript,
    required this.onNewProject,
    required this.onRefresh,
    required this.onScriptConsole,
  });

  @override
  State<DPCinePlannerV3> createState() => _DPCinePlannerV3State();
}

class _DPCinePlannerV3State extends State<DPCinePlannerV3>
    with TickerProviderStateMixin {
  static const _modules = <_PlannerModule>[
    _PlannerModule(
      'dashboard',
      'Dashboard',
      Icons.grid_view_rounded,
      '',
      '',
    ),
    _PlannerModule(
      'screenplay',
      'Screenplay',
      Icons.description_outlined,
      'Upload, version and read the script with scene markers.',
      'Upload script',
    ),
    _PlannerModule(
      'scenes',
      'Scenes',
      Icons.movie_filter_outlined,
      'Every scene with page count, cast, location and complexity.',
      'Add scene',
    ),
    _PlannerModule(
      'characters',
      'Characters',
      Icons.theater_comedy_outlined,
      'Characters extracted from the script, with leads flagged.',
      'Add character',
    ),
    _PlannerModule(
      'casting',
      'Casting',
      Icons.groups_2_outlined,
      'Match characters to shortlisted talent and track offers.',
      'Start casting',
    ),
    _PlannerModule(
      'locations',
      'Locations',
      Icons.location_city_outlined,
      'Script locations mapped to booked or scouted places.',
      'Add location',
    ),
    _PlannerModule(
      'props',
      'Props',
      Icons.inventory_2_outlined,
      'Props per scene, with sourcing and continuity notes.',
      'Add prop',
    ),
    _PlannerModule(
      'wardrobe',
      'Wardrobe',
      Icons.checkroom_outlined,
      'Looks per character and scene, fittings and changes.',
      'Add look',
    ),
    _PlannerModule(
      'makeup',
      'Makeup',
      Icons.face_retouching_natural_outlined,
      'Makeup and hair plans per character and shoot day.',
      'Add plan',
    ),
    _PlannerModule(
      'vehicles',
      'Vehicles',
      Icons.directions_car_outlined,
      'Picture cars and unit transport per shoot day.',
      'Add vehicle',
    ),
    _PlannerModule(
      'extras',
      'Extras',
      Icons.groups_outlined,
      'Background headcount by scene and call time.',
      'Add extras',
    ),
    _PlannerModule(
      'stunts',
      'Stunts',
      Icons.bolt_outlined,
      'Stunt sequences, coordinators and safety sign-off.',
      'Add stunt',
    ),
    _PlannerModule(
      'vfx',
      'VFX / SFX',
      Icons.layers_outlined,
      'Effects shots, vendors and turnaround.',
      'Add shot',
    ),
    _PlannerModule(
      'equipment',
      'Equipment',
      Icons.videocam_outlined,
      'Camera, lighting and grip packages per day.',
      'Add package',
    ),
  ];

  late final AnimationController _ambient;
  late final AnimationController _sheen;
  late final AnimationController _count;
  late final AnimationController _pulse;
  late final AnimationController _refreshSpin;
  final ScrollController _moduleScroll = ScrollController();
  final TextEditingController _search = TextEditingController();

  String _selectedModule = 'dashboard';
  bool _productionOpen = false;
  bool _conflictsOpen = false;
  bool _newProjectPressed = false;
  String _query = '';

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
    _count = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _refreshSpin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(covariant DPCinePlannerV3 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.selectedProductionId !=
        widget.controller.selectedProductionId) {
      _restartCount();
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    _sheen.dispose();
    _count.dispose();
    _pulse.dispose();
    _refreshSpin.dispose();
    _moduleScroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _restartCount() {
    _count
      ..stop()
      ..reset()
      ..forward();
  }

  Future<void> _selectProduction(String id) async {
    setState(() {
      _productionOpen = false;
      _conflictsOpen = false;
    });
    await widget.controller.selectProduction(id);
    if (mounted) _restartCount();
  }

  Future<void> _refresh() async {
    _refreshSpin
      ..stop()
      ..reset()
      ..repeat();
    try {
      await widget.onRefresh();
      if (mounted) _restartCount();
    } finally {
      if (mounted) {
        await _refreshSpin.animateTo(
          1,
          duration: const Duration(milliseconds: 220),
        );
        _refreshSpin.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _PlannerPalette.of(context);
    final size = MediaQuery.sizeOf(context);
    final mobile = size.width < 760;

    return ColoredBox(
      color: p.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              mobile ? 0 : 2,
              0,
              mobile ? 0 : 2,
              mobile ? 96 : 28,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHero(context, p, mobile),
                  const SizedBox(height: 12),
                  _buildModuleStrip(context, p, mobile),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .035),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _selectedModule == 'dashboard'
                        ? _buildDashboard(context, p, mobile)
                        : _buildModulePlaceholder(context, p, mobile),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    _PlannerPalette p,
    bool mobile,
  ) {
    final dashboard = _dashboard;
    final production = _production;
    final title = '${dashboard['screenplay_title'] ?? production['title'] ?? 'Untitled production'}';
    final progress = _number(dashboard['production_progress']).clamp(0, 100).toDouble();
    final nextShoot = _nextShootLabel(dashboard['upcoming_shoot']);
    final countdown = _countdownLabel(dashboard['upcoming_shoot']);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AnimatedBuilder(
        animation: Listenable.merge([_ambient, _sheen]),
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: p.line),
              boxShadow: [p.shadow],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PlannerHeroPainter(
                      p: p,
                      drift: _ambient.value,
                      sheen: _sheen.value,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(mobile ? 16 : 21),
                  child: mobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _heroIdentity(p),
                            const SizedBox(height: 15),
                            _heroTitle(p, title, nextShoot, countdown, mobile),
                            const SizedBox(height: 17),
                            _heroActions(p, progress, mobile),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _heroIdentity(p),
                                  const SizedBox(height: 16),
                                  _heroTitle(
                                    p,
                                    title,
                                    nextShoot,
                                    countdown,
                                    mobile,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 22),
                            SizedBox(
                              width: 390,
                              child: _heroActions(p, progress, mobile),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _heroIdentity(_PlannerPalette p) {
    final selected = _selectedProduction;
    final productions = widget.controller.productions;
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: p.goldGradient,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: p.gold.withValues(alpha: .28),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(Icons.description_outlined, color: p.onGold, size: 18),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CinePlanner',
              style: GoogleFonts.archivo(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Production intelligence',
              style: GoogleFonts.archivo(
                fontSize: 10.5,
                color: p.muted,
              ),
            ),
          ],
        ),
        if (productions.isNotEmpty)
          PopupMenuButton<String>(
            tooltip: 'Switch production',
            onOpened: () => setState(() => _productionOpen = true),
            onCanceled: () => setState(() => _productionOpen = false),
            onSelected: _selectProduction,
            color: p.sheet,
            elevation: 18,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: p.glassLine),
            ),
            itemBuilder: (context) => productions.map((item) {
              final id = '${item['public_id'] ?? ''}';
              final title = '${item['title'] ?? item['name'] ?? 'Production'}';
              final active = id == widget.controller.selectedProductionId;
              return PopupMenuItem<String>(
                value: id,
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            p.goldLight.withValues(alpha: .66),
                            p.ice.withValues(alpha: .78),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.archivo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                    ),
                    if (active)
                      Icon(Icons.check_rounded, color: p.gold, size: 17),
                  ],
                ),
              );
            }).toList(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: p.glass,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: p.goldLine),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6FBF8B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6FBF8B).withValues(alpha: .55),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: Text(
                      '${selected['title'] ?? selected['name'] ?? 'Engine in motion'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.archivo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _productionOpen ? .5 : 0,
                    duration: const Duration(milliseconds: 280),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 17,
                      color: p.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _heroTitle(
    _PlannerPalette p,
    String title,
    String nextShoot,
    String countdown,
    bool mobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: p.gold,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: p.gold.withValues(alpha: .55),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'PRODUCTION COMMAND CENTER',
              style: GoogleFonts.archivo(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.55,
                color: p.goldDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.newsreader(
            fontSize: mobile ? 26 : 31,
            fontWeight: FontWeight.w600,
            height: 1.06,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined, size: 13, color: p.muted),
                const SizedBox(width: 5),
                Text(
                  'Next shoot · $nextShoot',
                  style: GoogleFonts.archivo(
                    fontSize: 12,
                    color: p.ink2,
                  ),
                ),
              ],
            ),
            _HolographicPill(label: countdown, palette: p),
          ],
        ),
      ],
    );
  }

  Widget _heroActions(_PlannerPalette p, num progress, bool mobile) {
    final ringSize = mobile ? 82.0 : 78.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _count,
          builder: (context, _) => SizedBox(
            width: ringSize,
            height: ringSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(ringSize),
                  painter: _ProgressRingPainter(
                    progress: ((progress / 100) * Curves.easeOutCubic.transform(_count.value)).toDouble(),
                    track: p.ring,
                    start: p.goldLight,
                    end: p.goldDark,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * Curves.easeOutCubic.transform(_count.value)).round()}%',
                      style: GoogleFonts.archivo(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PREP',
                      style: GoogleFonts.archivo(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: p.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _GoldButton(
                      label: 'Upload script',
                      icon: Icons.upload_rounded,
                      palette: p,
                      onTap: widget.onUploadScript,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RoundGlassButton(
                    tooltip: 'Script console',
                    icon: Icons.terminal_rounded,
                    palette: p,
                    onTap: () => widget.onScriptConsole(),
                  ),
                  const SizedBox(width: 8),
                  _RoundGlassButton(
                    tooltip: 'Refresh',
                    iconWidget: RotationTransition(
                      turns: _refreshSpin,
                      child: Icon(Icons.refresh_rounded, color: p.gold, size: 18),
                    ),
                    palette: p,
                    onTap: _refresh,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Listener(
                onPointerDown: (_) => setState(() => _newProjectPressed = true),
                onPointerUp: (_) => setState(() => _newProjectPressed = false),
                onPointerCancel: (_) => setState(() => _newProjectPressed = false),
                child: GestureDetector(
                  onTap: widget.onNewProject,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 39,
                    decoration: BoxDecoration(
                      gradient: _newProjectPressed ? p.goldGradient : null,
                      color: _newProjectPressed ? null : p.glass,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: p.goldLine),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: _newProjectPressed ? p.onGold : p.gold,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'New project',
                            style: GoogleFonts.archivo(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _newProjectPressed ? p.onGold : p.gold,
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
    );
  }

  Widget _buildModuleStrip(
    BuildContext context,
    _PlannerPalette p,
    bool mobile,
  ) {
    final widths = _modules
        .map((m) => 45.0 + (m.label.length * 7.1).clamp(35, 110).toDouble())
        .toList();
    final selectedIndex = _modules.indexWhere((m) => m.key == _selectedModule);
    final left = selectedIndex <= 0
        ? 0.0
        : widths.take(selectedIndex).fold<double>(0, (a, b) => a + b + 4);
    final selectedWidth = widths[selectedIndex < 0 ? 0 : selectedIndex];
    final contentWidth = widths.fold<double>(0, (a, b) => a + b) +
        ((_modules.length - 1) * 4);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
        boxShadow: [p.shadow],
      ),
      child: Flex(
        direction: mobile ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!mobile)
            Expanded(
              child: _moduleScroller(
                p,
                widths,
                left,
                selectedWidth,
                contentWidth,
              ),
            )
          else
            _moduleScroller(
              p,
              widths,
              left,
              selectedWidth,
              contentWidth,
              height: 44,
            ),
          SizedBox(width: mobile ? 0 : 8, height: mobile ? 8 : 0),
          SizedBox(
            width: mobile ? double.infinity : 225,
            height: 36,
            child: TextField(
              controller: _search,
              onChanged: (value) => setState(() => _query = value.trim()),
              style: GoogleFonts.archivo(fontSize: 12, color: p.ink),
              decoration: InputDecoration(
                hintText: _selectedModule == 'dashboard'
                    ? 'Search metrics…'
                    : 'Search ${_activeModule.label.toLowerCase()}…',
                hintStyle: GoogleFonts.archivo(fontSize: 12, color: p.muted),
                prefixIcon: Icon(Icons.search_rounded, size: 16, color: p.muted),
                prefixIconConstraints: const BoxConstraints(minWidth: 34),
                filled: true,
                fillColor: p.card2,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: p.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: p.goldLine),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moduleScroller(
    _PlannerPalette p,
    List<double> widths,
    double left,
    double selectedWidth,
    double contentWidth, {
    double? height,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_moduleScroll.hasClients) return;
      final viewport = _moduleScroll.position.viewportDimension;
      final target = (left + selectedWidth / 2 - viewport / 2)
          .clamp(0.0, _moduleScroll.position.maxScrollExtent)
          .toDouble();
      _moduleScroll.animateTo(
        target,
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeOutCubic,
      );
    });

    final child = SingleChildScrollView(
      controller: _moduleScroll,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        width: contentWidth,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 620),
              curve: const Cubic(.65, 0, .25, 1),
              left: left,
              top: 4,
              width: selectedWidth,
              height: 34,
              child: Container(
                decoration: BoxDecoration(
                  color: p.goldLight.withValues(alpha: .32),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: p.gold.withValues(alpha: .32),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 480),
              curve: const Cubic(.65, 0, .25, 1),
              left: left,
              top: 4,
              width: selectedWidth,
              height: 34,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: AnimatedBuilder(
                  animation: _sheen,
                  builder: (context, _) => Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: p.goldGradient,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      FractionalTranslation(
                        translation: Offset(-1.35 + (_sheen.value * 2.7), 0),
                        child: Transform.rotate(
                          angle: -.12,
                          child: Container(
                            width: selectedWidth * .25,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: .8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 480),
              curve: const Cubic(.65, 0, .25, 1),
              left: left,
              top: 41,
              width: selectedWidth,
              height: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: p.gold,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: p.gold.withValues(alpha: .65),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < _modules.length; i++) ...[
                  SizedBox(
                    width: widths[i],
                    height: 42,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          setState(() {
                            _selectedModule = _modules[i].key;
                            _query = '';
                            _search.clear();
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _modules[i].icon,
                              size: 15,
                              color: _selectedModule == _modules[i].key
                                  ? p.onGold
                                  : p.ink2,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _modules[i].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.archivo(
                                  fontSize: 12,
                                  fontWeight: _selectedModule == _modules[i].key
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: _selectedModule == _modules[i].key
                                      ? p.onGold
                                      : p.ink2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (i != _modules.length - 1) const SizedBox(width: 4),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    if (height == null) return child;
    return SizedBox(height: height, child: child);
  }

  Widget _buildDashboard(
    BuildContext context,
    _PlannerPalette p,
    bool mobile,
  ) {
    final metrics = _metrics(p).where((item) {
      final q = _query.toLowerCase();
      return q.isEmpty || item.label.toLowerCase().contains(q);
    }).toList();

    return Column(
      key: const ValueKey('cineplanner-dashboard-v3'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (metrics.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.goldLine),
            ),
            child: Text(
              'No metrics match “$_query”.',
              textAlign: TextAlign.center,
              style: GoogleFonts.archivo(fontSize: 12.5, color: p.muted),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: mobile ? 2 : _desktopColumns(context),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: mobile ? 84 : 72,
            ),
            itemCount: metrics.length,
            itemBuilder: (context, index) => _MetricTile(
              item: metrics[index],
              palette: p,
              count: _count,
              delay: Duration(milliseconds: index * 38),
            ),
          ),
        const SizedBox(height: 12),
        _buildConflicts(context, p, mobile),
      ],
    );
  }

  int _desktopColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1500) return 5;
    if (width >= 1180) return 4;
    if (width >= 900) return 3;
    return 2;
  }

  Widget _buildConflicts(
    BuildContext context,
    _PlannerPalette p,
    bool mobile,
  ) {
    final dashboardCount = _number(_dashboard['schedule_conflicts']).round();
    final schedule = widget.snapshot['schedule'] as Map<String, dynamic>? ?? const {};
    final conflicts = (schedule['conflicts'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
        boxShadow: [p.shadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _conflictsOpen = !_conflictsOpen),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      final v = _pulse.value;
                      return SizedBox(
                        width: 38,
                        height: 38,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 36 + (v * 12),
                              height: 36 + (v * 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13 + v * 5),
                                border: Border.all(
                                  color: p.peach.withValues(alpha: .65 * (1 - v)),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: p.peachSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: p.peachInk,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$dashboardCount open schedule conflicts',
                          style: GoogleFonts.archivo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: p.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Open the conflict center to inspect severity.',
                          style: GoogleFonts.archivo(
                            fontSize: 11.5,
                            color: p.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!mobile)
                    Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: p.goldLine),
                      ),
                      child: Text(
                        'Conflict center',
                        style: GoogleFonts.archivo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: p.gold,
                        ),
                      ),
                    ),
                  if (!mobile) const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: _conflictsOpen ? .5 : 0,
                    duration: const Duration(milliseconds: 320),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: p.line),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 17,
                        color: p.ink2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            child: !_conflictsOpen
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(17, 0, 14, 12),
                    child: Column(
                      children: [
                        if (conflicts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              dashboardCount > 0
                                  ? 'Conflict details will appear here when returned by CinePlanner.'
                                  : 'No open conflicts.',
                              style: GoogleFonts.archivo(
                                fontSize: 11.5,
                                color: p.muted,
                              ),
                            ),
                          )
                        else
                          for (var i = 0; i < conflicts.length; i++)
                            _ConflictRow(
                              conflict: conflicts[i],
                              palette: p,
                              onResolve: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Open the conflict workflow to resolve this item.',
                                      style: GoogleFonts.archivo(),
                                    ),
                                  ),
                                );
                              },
                            ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulePlaceholder(
    BuildContext context,
    _PlannerPalette p,
    bool mobile,
  ) {
    final module = _activeModule;
    return Container(
      key: ValueKey('cineplanner-module-${module.key}'),
      padding: EdgeInsets.all(mobile ? 16 : 21),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.line),
        boxShadow: [p.shadow],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -36,
            child: _SoftBubble(size: 130, color: p.ice.withValues(alpha: .16)),
          ),
          Positioned(
            left: -40,
            bottom: -50,
            child: _SoftBubble(size: 150, color: p.lavender.withValues(alpha: .13)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _HolographicIcon(icon: module.icon, palette: p),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: mobile ? double.infinity : 620,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.label,
                          style: GoogleFonts.newsreader(
                            fontSize: 23,
                            fontWeight: FontWeight.w600,
                            color: p.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          module.description,
                          style: GoogleFonts.archivo(
                            fontSize: 12.5,
                            color: p.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (module.cta.isNotEmpty)
                    _GoldButton(
                      label: module.cta,
                      icon: Icons.add_rounded,
                      palette: p,
                      onTap: () async {
                        if (module.key == 'screenplay') {
                          await widget.onUploadScript();
                          return;
                        }
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${module.label} action slot is ready for its live workflow.'),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 17),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                decoration: BoxDecoration(
                  color: p.glass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.goldLine, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Text(
                      '${module.label} module content goes here',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.archivo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: p.ink2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The cinematic shell, motion system and data slot are ready for this module.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.archivo(fontSize: 11.5, color: p.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> get _dashboard =>
      widget.snapshot['dashboard'] as Map<String, dynamic>? ?? const {};

  Map<String, dynamic> get _production =>
      widget.snapshot['production'] as Map<String, dynamic>? ?? const {};

  Map<String, dynamic> get _selectedProduction {
    final id = widget.controller.selectedProductionId;
    for (final item in widget.controller.productions) {
      if ('${item['public_id'] ?? ''}' == id) return item;
    }
    return _production;
  }

  _PlannerModule get _activeModule =>
      _modules.firstWhere((module) => module.key == _selectedModule);

  List<_MetricData> _metrics(_PlannerPalette p) {
    final dashboard = _dashboard;
    final currency = '${_production['currency'] ?? dashboard['currency'] ?? 'PKR'}';
    return [
      _MetricData('Pages', _number(dashboard['total_pages']), Icons.menu_book_outlined, p.sand, p.sandSoft, p.sandInk),
      _MetricData('Scenes', _number(dashboard['total_scenes']), Icons.movie_filter_outlined, p.ice, p.iceSoft, p.iceInk),
      _MetricData('Characters', _number(dashboard['characters']), Icons.theater_comedy_outlined, p.lavender, p.lavenderSoft, p.lavenderInk),
      _MetricData('Leads', _number(dashboard['lead_characters']), Icons.star_outline_rounded, p.sand, p.sandSoft, p.sandInk),
      _MetricData('Locations', _number(dashboard['locations']), Icons.location_city_outlined, p.mint, p.mintSoft, p.mintInk),
      _MetricData('Props', _number(dashboard['props']), Icons.inventory_2_outlined, p.ice, p.iceSoft, p.iceInk),
      _MetricData('Shoot days', _number(dashboard['scheduled_shoot_days']), Icons.calendar_month_outlined, p.mint, p.mintSoft, p.mintInk),
      _MetricData('Progress', _number(dashboard['production_progress']), Icons.donut_large_rounded, p.sand, p.sandSoft, p.sandInk, suffix: '%'),
      _MetricData('Estimated budget', _number(dashboard['estimated_budget_minor']), Icons.account_balance_wallet_outlined, p.mint, p.mintSoft, p.mintInk, currency: currency, moneyMinor: true),
      _MetricData('Open conflicts', _number(dashboard['schedule_conflicts']), Icons.warning_amber_rounded, p.peach, p.peachSoft, p.peachInk, tag: _number(dashboard['schedule_conflicts']) > 0 ? 'REVIEW' : null),
      _MetricData('Availability', _number(dashboard['actor_availability_issues']), Icons.event_busy_outlined, p.ice, p.iceSoft, p.iceInk),
      _MetricData('AI review queue', _number(dashboard['unapproved_ai_items']), Icons.auto_awesome_outlined, p.lavender, p.lavenderSoft, p.lavenderInk, tag: _number(dashboard['unapproved_ai_items']) > 0 ? 'QUEUE' : null),
      _MetricData('Complex scenes', _number(dashboard['high_complexity_scenes']), Icons.local_fire_department_outlined, p.peach, p.peachSoft, p.peachInk),
    ];
  }

  static num _number(dynamic value) {
    if (value is num) return value;
    return num.tryParse('$value') ?? 0;
  }

  static String _nextShootLabel(dynamic raw) {
    if (raw == null || '$raw'.trim().isEmpty) return 'Dates TBD';
    final text = '$raw';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return text;
    return DateFormat('d MMM yyyy').format(parsed);
  }

  static String _countdownLabel(dynamic raw) {
    if (raw == null || '$raw'.trim().isEmpty) return 'Awaiting schedule';
    final parsed = DateTime.tryParse('$raw');
    if (parsed == null) return 'Schedule active';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(parsed.year, parsed.month, parsed.day);
    final days = target.difference(today).inDays;
    if (days > 1) return 'in $days days';
    if (days == 1) return 'tomorrow';
    if (days == 0) return 'today';
    return 'in progress';
  }
}

class _PlannerModule {
  final String key;
  final String label;
  final IconData icon;
  final String description;
  final String cta;

  const _PlannerModule(
    this.key,
    this.label,
    this.icon,
    this.description,
    this.cta,
  );
}

class _MetricData {
  final String label;
  final num value;
  final IconData icon;
  final Color edge;
  final Color soft;
  final Color ink;
  final String? tag;
  final String suffix;
  final String? currency;
  final bool moneyMinor;

  const _MetricData(
    this.label,
    this.value,
    this.icon,
    this.edge,
    this.soft,
    this.ink, {
    this.tag,
    this.suffix = '',
    this.currency,
    this.moneyMinor = false,
  });

  String formatted(num animated) {
    if (moneyMinor) {
      final major = animated / 100;
      final code = currency ?? 'PKR';
      if (major >= 1000000) return '$code ${(major / 1000000).toStringAsFixed(1)}M';
      if (major >= 1000) return '$code ${(major / 1000).toStringAsFixed(1)}K';
      return '$code ${major.round()}';
    }
    return '${animated.round()}$suffix';
  }
}

class _MetricTile extends StatefulWidget {
  final _MetricData item;
  final _PlannerPalette palette;
  final AnimationController count;
  final Duration delay;

  const _MetricTile({
    required this.item,
    required this.palette,
    required this.count,
    required this.delay,
  });

  @override
  State<_MetricTile> createState() => _MetricTileState();
}

class _MetricTileState extends State<_MetricTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.05 : 1,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 360),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hovered ? p.gold : p.line),
            boxShadow: [
              p.shadow,
              if (_hovered)
                BoxShadow(
                  color: p.gold.withValues(alpha: .18),
                  blurRadius: 24,
                  spreadRadius: -7,
                ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.item.edge,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 9, 10, 9),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: widget.item.soft,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(widget.item.icon, size: 17, color: widget.item.ink),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.archivo(
                              fontSize: 10.5,
                              color: p.muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedBuilder(
                            animation: widget.count,
                            builder: (context, _) {
                              final curved = Curves.easeOutCubic.transform(widget.count.value);
                              return Text(
                                widget.item.formatted(widget.item.value * curved),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.archivo(
                                  fontSize: 18.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.4,
                                  color: p.ink,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (widget.item.tag != null)
                      Container(
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: widget.item.soft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.item.tag!,
                          style: GoogleFonts.archivo(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .35,
                            color: widget.item.ink,
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
    );
  }
}

class _ConflictRow extends StatelessWidget {
  final Map<String, dynamic> conflict;
  final _PlannerPalette palette;
  final VoidCallback onResolve;

  const _ConflictRow({
    required this.conflict,
    required this.palette,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final severity = '${conflict['severity'] ?? conflict['level'] ?? 'MED'}'.toUpperCase();
    final high = severity.contains('HIGH') || severity.contains('CRITICAL');
    final low = severity.contains('LOW');
    final soft = high ? p.peachSoft : low ? p.iceSoft : p.sandSoft;
    final ink = high ? p.peachInk : low ? p.iceInk : p.sandInk;
    final title = '${conflict['message'] ?? conflict['title'] ?? 'Schedule conflict'}';
    final meta = '${conflict['type'] ?? conflict['meta'] ?? 'Conflict'}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: Row(
        children: [
          Container(
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              severity,
              style: GoogleFonts.archivo(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
                color: ink,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.archivo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  meta,
                  style: GoogleFonts.archivo(fontSize: 11, color: p.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onResolve,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.goldSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Resolve',
                style: GoogleFonts.archivo(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: p.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final _PlannerPalette palette;
  final Future<void> Function() onTap;

  const _GoldButton({
    required this.label,
    required this.icon,
    required this.palette,
    required this.onTap,
  });

  @override
  State<_GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<_GoldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? .97 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              gradient: p.goldGradient,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: p.gold.withValues(alpha: .23),
                  blurRadius: 15,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 16, color: p.onGold),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.archivo(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w800,
                      color: p.onGold,
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

class _RoundGlassButton extends StatelessWidget {
  final String tooltip;
  final IconData? icon;
  final Widget? iconWidget;
  final _PlannerPalette palette;
  final Future<void> Function() onTap;

  const _RoundGlassButton({
    required this.tooltip,
    this.icon,
    this.iconWidget,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: p.glass,
              shape: BoxShape.circle,
              border: Border.all(color: p.line),
            ),
            child: Center(
              child: iconWidget ?? Icon(icon, color: p.gold, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class _HolographicPill extends StatefulWidget {
  final String label;
  final _PlannerPalette palette;

  const _HolographicPill({required this.label, required this.palette});

  @override
  State<_HolographicPill> createState() => _HolographicPillState();
}

class _HolographicPillState extends State<_HolographicPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shift = .5 + .5 * math.sin(_controller.value * math.pi * 2);
        return Container(
          height: 23,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + shift, -1),
              end: Alignment(1 - shift, 1),
              colors: p.holographic,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: p.glassLine),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.archivo(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: p.ink2,
            ),
          ),
        );
      },
    );
  }
}

class _HolographicIcon extends StatefulWidget {
  final IconData icon;
  final _PlannerPalette palette;

  const _HolographicIcon({required this.icon, required this.palette});

  @override
  State<_HolographicIcon> createState() => _HolographicIconState();
}

class _HolographicIconState extends State<_HolographicIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final x = math.sin(_controller.value * math.pi * 2) * .7;
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + x, -1),
              end: Alignment(1 - x, 1),
              colors: p.holographic,
            ),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: p.glassLine),
          ),
          child: Icon(widget.icon, size: 22, color: p.gold),
        );
      },
    );
  }
}

class _SoftBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftBubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.35, -.4),
          colors: [Colors.white.withValues(alpha: .48), color, Colors.transparent],
          stops: const [0, .38, 1],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color start;
  final Color end;

  const _ProgressRingPainter({
    required this.progress,
    required this.track,
    required this.start,
    required this.end,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..shader = SweepGradient(colors: [start, end]).createShader(rect);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.track != track ||
      oldDelegate.start != start ||
      oldDelegate.end != end;
}

class _PlannerHeroPainter extends CustomPainter {
  final _PlannerPalette p;
  final double drift;
  final double sheen;

  const _PlannerHeroPainter({
    required this.p,
    required this.drift,
    required this.sheen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final wash = Paint()
      ..shader = RadialGradient(
        colors: [p.ice.withValues(alpha: .22), Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * .92, size.height * .05),
          radius: size.width * .42,
        ),
      );
    canvas.drawRect(Offset.zero & size, wash);

    final wash2 = Paint()
      ..shader = RadialGradient(
        colors: [p.lavender.withValues(alpha: .18), Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * .04, size.height * .95),
          radius: size.width * .38,
        ),
      );
    canvas.drawRect(Offset.zero & size, wash2);

    const bubbles = <(double, double, double, double)>[
      (.46, .10, 34, 0),
      (.58, .62, 16, 1.2),
      (.92, .08, 50, .5),
      (.38, .70, 12, 2),
      (.84, .74, 22, .8),
      (.26, .18, 10, 1.6),
      (.03, .80, 20, 2.4),
    ];
    for (var i = 0; i < bubbles.length; i++) {
      final b = bubbles[i];
      final t = (drift + b.$4 / 12) * math.pi * 2;
      final dx = math.sin(t * (1 + i * .06)) * (6 + i % 3 * 2);
      final dy = math.cos(t * (1.1 + i * .04)) * (8 + i % 2 * 4);
      final center = Offset(size.width * b.$1 + dx, size.height * b.$2 + dy);
      final radius = b.$3 / 2;
      final bubble = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.4),
          colors: [
            Colors.white.withValues(alpha: p.dark ? .62 : .93),
            p.ice.withValues(alpha: p.dark ? .22 : .35),
            p.lavender.withValues(alpha: p.dark ? .10 : .18),
            Colors.transparent,
          ],
          stops: const [0, .2, .58, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, bubble);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = p.glassLine.withValues(alpha: .65),
      );
    }

    final sweepX = -size.width * .35 + (size.width * 1.7 * sheen);
    final sheenRect = Rect.fromLTWH(sweepX, -size.height, size.width * .22, size.height * 3);
    canvas.save();
    final pivot = Offset(size.width / 2, size.height / 2);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(-.24);
    canvas.translate(-pivot.dx, -pivot.dy);
    canvas.drawRect(
      sheenRect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent, Colors.white.withValues(alpha: p.dark ? .08 : .18), Colors.transparent],
        ).createShader(sheenRect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlannerHeroPainter oldDelegate) =>
      oldDelegate.drift != drift || oldDelegate.sheen != sheen || oldDelegate.p != p;
}

class _PlannerPalette {
  final bool dark;
  final Color background;
  final Color card;
  final Color card2;
  final Color sheet;
  final Color ink;
  final Color ink2;
  final Color muted;
  final Color line;
  final Color gold;
  final Color goldDark;
  final Color goldLight;
  final Color goldSoft;
  final Color goldLine;
  final Color onGold;
  final Color glass;
  final Color glassLine;
  final Color ring;
  final Color ice;
  final Color mint;
  final Color lavender;
  final Color peach;
  final Color sand;
  final Color iceSoft;
  final Color mintSoft;
  final Color lavenderSoft;
  final Color peachSoft;
  final Color sandSoft;
  final Color iceInk;
  final Color mintInk;
  final Color lavenderInk;
  final Color peachInk;
  final Color sandInk;

  const _PlannerPalette({
    required this.dark,
    required this.background,
    required this.card,
    required this.card2,
    required this.sheet,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.line,
    required this.gold,
    required this.goldDark,
    required this.goldLight,
    required this.goldSoft,
    required this.goldLine,
    required this.onGold,
    required this.glass,
    required this.glassLine,
    required this.ring,
    required this.ice,
    required this.mint,
    required this.lavender,
    required this.peach,
    required this.sand,
    required this.iceSoft,
    required this.mintSoft,
    required this.lavenderSoft,
    required this.peachSoft,
    required this.sandSoft,
    required this.iceInk,
    required this.mintInk,
    required this.lavenderInk,
    required this.peachInk,
    required this.sandInk,
  });

  LinearGradient get goldGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [goldLight, gold],
      );

  List<Color> get holographic => dark
      ? [
          Colors.white.withValues(alpha: .07),
          ice.withValues(alpha: .14),
          lavender.withValues(alpha: .12),
          peach.withValues(alpha: .12),
          Colors.white.withValues(alpha: .05),
        ]
      : [
          Colors.white.withValues(alpha: .88),
          ice.withValues(alpha: .46),
          lavender.withValues(alpha: .38),
          peach.withValues(alpha: .40),
          Colors.white.withValues(alpha: .88),
        ];

  BoxShadow get shadow => dark
      ? const BoxShadow(
          color: Color(0x66000000),
          blurRadius: 34,
          spreadRadius: -22,
          offset: Offset(0, 15),
        )
      : const BoxShadow(
          color: Color(0x2416130A),
          blurRadius: 30,
          spreadRadius: -20,
          offset: Offset(0, 14),
        );

  static _PlannerPalette of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return const _PlannerPalette(
        dark: true,
        background: Color(0xFF09090B),
        card: Color(0xFF131316),
        card2: Color(0xFF17171B),
        sheet: Color(0xFF1A1A1E),
        ink: Color(0xFFF3F0E7),
        ink2: Color(0xFFC6C0B0),
        muted: Color(0xFF8B8677),
        line: Color(0x14FFFFFF),
        gold: Color(0xFFD4AF37),
        goldDark: Color(0xFFE5C46E),
        goldLight: Color(0xFFEDD48A),
        goldSoft: Color(0x21D4AF37),
        goldLine: Color(0x52E5C46E),
        onGold: Color(0xFF16120A),
        glass: Color(0x0DFFFFFF),
        glassLine: Color(0x28FFFFFF),
        ring: Color(0x14FFFFFF),
        ice: Color(0xFF8FC2E6),
        mint: Color(0xFF8FD3A9),
        lavender: Color(0xFFB2A4EC),
        peach: Color(0xFFE8AE94),
        sand: Color(0xFFDCC27A),
        iceSoft: Color(0x1F8FC2E6),
        mintSoft: Color(0x1F8FD3A9),
        lavenderSoft: Color(0x1FB2A4EC),
        peachSoft: Color(0x1FE8AE94),
        sandSoft: Color(0x1FDCC27A),
        iceInk: Color(0xFFA9D4F2),
        mintInk: Color(0xFFA8E0C0),
        lavenderInk: Color(0xFFC9BDF5),
        peachInk: Color(0xFFF2C6B2),
        sandInk: Color(0xFFE8D08E),
      );
    }
    return const _PlannerPalette(
      dark: false,
      background: Color(0xFFF7F5F0),
      card: Colors.white,
      card2: Color(0xFFFBFAF6),
      sheet: Color(0xFFFDFCF8),
      ink: Color(0xFF17150E),
      ink2: Color(0xFF4A463B),
      muted: Color(0xFF8A8475),
      line: Color(0x1517150E),
      gold: Color(0xFFD3B55F),
      goldDark: Color(0xFF9C7614),
      goldLight: Color(0xFFEBD48F),
      goldSoft: Color(0xFFF8F1DE),
      goldLine: Color(0x599C7614),
      onGold: Color(0xFF1A1408),
      glass: Color(0x9EFFFFFF),
      glassLine: Color(0xF2FFFFFF),
      ring: Color(0xFFEFE7D2),
      ice: Color(0xFFA9D0EC),
      mint: Color(0xFFA9DDBC),
      lavender: Color(0xFFC4B9EE),
      peach: Color(0xFFEFC3AE),
      sand: Color(0xFFE6D196),
      iceSoft: Color(0xFFEEF6FC),
      mintSoft: Color(0xFFEEF8F1),
      lavenderSoft: Color(0xFFF3F0FC),
      peachSoft: Color(0xFFFCF1EB),
      sandSoft: Color(0xFFFAF4E3),
      iceInk: Color(0xFF3F6E8F),
      mintInk: Color(0xFF3C7A55),
      lavenderInk: Color(0xFF5E52A0),
      peachInk: Color(0xFFA0593C),
      sandInk: Color(0xFF8A6A18),
    );
  }
}
