import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/core_ui/core_routes.dart';
import '../../../../core/director/director_dashboard_models.dart';
import '../../models/dp_payment.dart';
import '../../models/dp_project.dart';
import '../../routes/director_producer_routes.dart';
import 'dp_dashboard_v3_theme.dart';

class DPV3Dashboard extends StatefulWidget {
  final DirectorDashboard dashboard;

  const DPV3Dashboard({super.key, required this.dashboard});

  @override
  State<DPV3Dashboard> createState() => _DPV3DashboardState();
}

class _DPV3DashboardState extends State<DPV3Dashboard> {
  late DateTime _selectedDate;
  late DateTime _visibleMonth;
  late List<_PlanItem> _plans;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  String _projectFilter = 'All';
  String _discoverFilter = 'All';
  bool _adding = false;
  final _planTitle = TextEditingController();
  final _planMeta = TextEditingController();
  TimeOfDay _planTime = const TimeOfDay(hour: 10, minute: 0);
  String _planType = 'Meeting';

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _visibleMonth = DateTime(today.year, today.month);
    _plans = widget.dashboard.timeline.map(_PlanItem.fromTimeline).toList();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _planTitle.dispose();
    _planMeta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 700;
        final medium = constraints.maxWidth < 1100;
        return DefaultTextStyle(
          style: dpV3Sans(13, p),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RiseIn(
                delay: const Duration(milliseconds: 100),
                child: _HeroCard(
                  dashboard: widget.dashboard,
                  mobile: mobile,
                  onNewProject: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.createProject,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _RiseIn(
                delay: const Duration(milliseconds: 180),
                child: _LiveTicker(dashboard: widget.dashboard),
              ),
              const SizedBox(height: 18),
              _RiseIn(
                delay: const Duration(milliseconds: 240),
                child: _PlannerWorkspace(
                  dashboard: widget.dashboard,
                  now: _now,
                  visibleMonth: _visibleMonth,
                  selectedDate: _selectedDate,
                  plans: _plans,
                  adding: _adding,
                  planTitle: _planTitle,
                  planMeta: _planMeta,
                  planTime: _planTime,
                  planType: _planType,
                  medium: medium,
                  mobile: mobile,
                  onPrevMonth: () => setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month - 1,
                    );
                  }),
                  onNextMonth: () => setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month + 1,
                    );
                  }),
                  onToday: () => setState(() {
                    final t = DateTime.now();
                    _selectedDate = DateTime(t.year, t.month, t.day);
                    _visibleMonth = DateTime(t.year, t.month);
                  }),
                  onSelectDate: (date) => setState(() => _selectedDate = date),
                  onStartAdd: () => setState(() => _adding = true),
                  onCancelAdd: () => setState(() => _adding = false),
                  onType: (type) => setState(() => _planType = type),
                  onTime: () => _pickTime(context),
                  onRemove: (id) => setState(
                    () => _plans.removeWhere((item) => item.id == id),
                  ),
                  onSave: _savePlan,
                ),
              ),
              const SizedBox(height: 18),
              _RiseIn(
                delay: const Duration(milliseconds: 300),
                child: _AttentionPanel(dashboard: widget.dashboard),
              ),
              const SizedBox(height: 18),
              _RiseIn(
                delay: const Duration(milliseconds: 360),
                child: _ProjectDeckV3(
                  projects: widget.dashboard.dpProjects,
                  selected: _projectFilter,
                  onFilter: (value) => setState(() => _projectFilter = value),
                ),
              ),
              const SizedBox(height: 18),
              const _RiseIn(
                delay: Duration(milliseconds: 420),
                child: _CinePlannerFeature(),
              ),
              const SizedBox(height: 18),
              _RiseIn(
                delay: const Duration(milliseconds: 480),
                child: _DiscoverDeck(
                  selected: _discoverFilter,
                  onFilter: (value) => setState(() => _discoverFilter = value),
                ),
              ),
              const SizedBox(height: 18),
              _RiseIn(
                delay: const Duration(milliseconds: 540),
                child: _FinancialCommandCentre(dashboard: widget.dashboard),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: _planTime);
    if (picked != null && mounted) setState(() => _planTime = picked);
  }

  void _savePlan() {
    final title = _planTitle.text.trim();
    if (title.isEmpty) return;
    setState(() {
      final startsAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _planTime.hour,
        _planTime.minute,
      );
      _plans.add(
        _PlanItem(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          title: title,
          meta: _planMeta.text.trim().isEmpty
              ? 'Added from dashboard'
              : _planMeta.text.trim(),
          type: _planType,
          startsAt: startsAt,
        ),
      );
      _planTitle.clear();
      _planMeta.clear();
      _adding = false;
    });
  }
}

class _HeroCard extends StatelessWidget {
  final DirectorDashboard dashboard;
  final bool mobile;
  final VoidCallback onNewProject;

  const _HeroCard({
    required this.dashboard,
    required this.mobile,
    required this.onNewProject,
  });

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final auth = AuthScope.maybeOf(context);
    final name = auth?.user?.displayName.trim().isNotEmpty == true
        ? auth!.user!.displayName.trim()
        : 'Producer';
    final initials = _initials(name);
    final role = auth?.user?.primaryRole?.name ?? 'Producer';
    final summary = dashboard.summary;

    return _TraceCard(
      radius: 28,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            gradient: p.heroGradient,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: p.glassLine),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _DiagonalLinePainter(p)),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: _HeroBeamLayer(dark: p.dark),
                ),
              ),
              if (!mobile)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: _FloatingBubbleLayer(specs: _heroBubbleSpecs),
                  ),
                ),
              if (!mobile) const _HeroFloatingChips(),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: mobile ? 16 : 24,
                  vertical: mobile ? 18 : 22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 84),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: p.card,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: p.softShadow,
                            ),
                            child: Text(
                              initials,
                              style: dpV3Sans(
                                16,
                                p,
                                weight: FontWeight.w800,
                                color: p.gold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: dpV3Serif(
                                    25,
                                    p,
                                    weight: FontWeight.w600,
                                    height: 1.05,
                                    letterSpacing: -.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: p.goldTint,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_rounded,
                                        size: 11,
                                        color: p.gold,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'VERIFIED ${role.toUpperCase()}',
                                        style: dpV3Sans(
                                          10,
                                          p,
                                          weight: FontWeight.w800,
                                          color: p.gold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: p.glass,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: p.glassLine),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(
                              alpha: p.dark ? .035 : .24,
                            ),
                            blurRadius: 1,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _HeroStat(
                            value: '${summary.projectCount}',
                            label: 'Productions',
                          ),
                          _HeroStat(
                            value: _moneyMinor(
                              summary.committedBudgetMinor,
                              summary.currency,
                            ),
                            label: 'Committed',
                          ),
                          _HeroStat(
                            value: '${summary.securedBookings}',
                            label: 'Bookings secured',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _PressableNewProjectButton(onTap: onNewProject),
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

class _PressableNewProjectButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PressableNewProjectButton({required this.onTap});

  @override
  State<_PressableNewProjectButton> createState() =>
      _PressableNewProjectButtonState();
}

class _PressableNewProjectButtonState
    extends State<_PressableNewProjectButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final filled = _pressed;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? .985 : 1,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? p.goldFill : p.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _hover || filled ? p.goldFill : p.glassLine,
              ),
              boxShadow: p.softShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: filled ? const Color(0xFF1A1408) : p.ink,
                ),
                const SizedBox(width: 8),
                Text(
                  'New Project',
                  style: dpV3Sans(
                    13.5,
                    p,
                    weight: FontWeight.w700,
                    color: filled ? const Color(0xFF1A1408) : p.ink,
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

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: p.goldFill, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: dpV3Sans(
                18,
                p,
                weight: FontWeight.w800,
                letterSpacing: -.4,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: dpV3Sans(11, p, color: p.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFloatingChips extends StatelessWidget {
  const _HeroFloatingChips();

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final chips = [
      _HoloSpec(
        label: 'Drama',
        icon: Icons.theater_comedy_outlined,
        x: .02,
        top: 16,
        rotation: -4 * math.pi / 180,
        duration: const Duration(seconds: 7),
        delay: Duration.zero,
        color: p.violet,
      ),
      _HoloSpec(
        label: 'Action',
        icon: Icons.bolt_rounded,
        x: .27,
        top: 6,
        rotation: 5 * math.pi / 180,
        duration: const Duration(milliseconds: 8500),
        delay: const Duration(milliseconds: 600),
        color: p.negative,
      ),
      _HoloSpec(
        label: 'Production',
        icon: Icons.movie_creation_outlined,
        x: .52,
        top: 18,
        rotation: -3 * math.pi / 180,
        duration: const Duration(milliseconds: 7800),
        delay: const Duration(milliseconds: 1200),
        color: p.gold,
      ),
      _HoloSpec(
        label: 'REC 00:14:32',
        icon: Icons.fiber_manual_record_rounded,
        x: .77,
        top: 8,
        rotation: 3 * math.pi / 180,
        duration: const Duration(milliseconds: 6600),
        delay: const Duration(milliseconds: 300),
        color: p.negative,
      ),
      _HoloSpec(
        label: 'Scene 14 · Take 3',
        icon: Icons.movie_filter_outlined,
        x: .12,
        top: 62,
        rotation: -2 * math.pi / 180,
        duration: const Duration(seconds: 9),
        delay: const Duration(milliseconds: 900),
        color: p.info,
      ),
      _HoloSpec(
        label: 'Thriller',
        icon: Icons.star_outline_rounded,
        x: .44,
        top: 66,
        rotation: 4 * math.pi / 180,
        duration: const Duration(seconds: 8),
        delay: const Duration(milliseconds: 1800),
        color: p.gold,
      ),
      _HoloSpec(
        label: 'Commercial',
        icon: Icons.videocam_outlined,
        x: .68,
        top: 60,
        rotation: -5 * math.pi / 180,
        duration: const Duration(milliseconds: 7200),
        delay: const Duration(milliseconds: 2200),
        color: p.positive,
      ),
    ];

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: 112,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final left = constraints.maxWidth * .42;
          final width = math.max(0.0, constraints.maxWidth - left - 16);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final chip in chips)
                Positioned(
                  left: left + width * chip.x,
                  top: chip.top,
                  child: _FloatingHoloChip(spec: chip),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HoloSpec {
  final String label;
  final IconData icon;
  final double x;
  final double top;
  final double rotation;
  final Duration duration;
  final Duration delay;
  final Color color;

  const _HoloSpec({
    required this.label,
    required this.icon,
    required this.x,
    required this.top,
    required this.rotation,
    required this.duration,
    required this.delay,
    required this.color,
  });
}

class _FloatingHoloChip extends StatefulWidget {
  final _HoloSpec spec;
  const _FloatingHoloChip({required this.spec});

  @override
  State<_FloatingHoloChip> createState() => _FloatingHoloChipState();
}

class _FloatingHoloChipState extends State<_FloatingHoloChip>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _holoController;
  late final AnimationController _popController;
  late final AnimationController _rippleController;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    final durationMs = widget.spec.duration.inMilliseconds;
    final phase = durationMs == 0
        ? 0.0
        : (widget.spec.delay.inMilliseconds % durationMs) / durationMs;
    _floatController = AnimationController(
      vsync: this,
      duration: widget.spec.duration,
      value: phase,
    )..repeat();
    _holoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
      value: phase,
    )..repeat();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _holoController.dispose();
    _popController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  double _popScale(double t) {
    if (t <= .30) return _lerp(1, 1.20, t / .30);
    if (t <= .55) return _lerp(1.20, .93, (t - .30) / .25);
    if (t <= .78) return _lerp(.93, 1.05, (t - .55) / .23);
    return _lerp(1.05, 1, (t - .78) / .22);
  }

  void _pop() {
    _popController.forward(from: 0);
    _rippleController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatController,
        _holoController,
        _popController,
        _rippleController,
      ]),
      builder: (context, _) {
        final floatY = -14 *
            ((1 - math.cos(_floatController.value * math.pi * 2)) / 2);
        final pop = _popController.isAnimating
            ? _popScale(_popController.value)
            : 1.0;
        final holoWave =
            (1 - math.cos(_holoController.value * math.pi * 2)) / 2;
        final shift = _lerp(-.55, .55, holoWave);
        final ripple = _rippleController.value;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.rotate(
            angle: widget.spec.rotation,
            child: Transform.scale(
              scale: pop * (_hover ? 1.025 : 1),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hover = true),
                onExit: (_) => setState(() => _hover = false),
                child: GestureDetector(
                  onTap: _pop,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(-1.4 + shift, -1),
                            end: Alignment(.8 + shift, 1),
                            colors: p.dark
                                ? const [
                                    Color(0x1AFFFFFF),
                                    Color(0x218CBFFF),
                                    Color(0x1CFF96DC),
                                    Color(0x26FFD778),
                                    Color(0x14FFFFFF),
                                  ]
                                : const [
                                    Color(0xCCFFFFFF),
                                    Color(0x99D2EAFF),
                                    Color(0x8CFFDDF6),
                                    Color(0xB3FFF2CC),
                                    Color(0xCCFFFFFF),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: p.holoBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(
                                alpha: p.dark ? .06 : .45,
                              ),
                              offset: const Offset(0, 1),
                              blurRadius: 1,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .20),
                              offset: const Offset(0, 12),
                              blurRadius: 26,
                              spreadRadius: -14,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.spec.icon,
                              size: 13,
                              color: widget.spec.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.spec.label,
                              style: dpV3Sans(
                                11,
                                p,
                                weight: FontWeight.w700,
                                color: p.inkSoft,
                                letterSpacing: .2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_rippleController.isAnimating)
                        IgnorePointer(
                          child: Transform.scale(
                            scale: _lerp(1, 1.9, ripple),
                            child: Opacity(
                              opacity: (0.9 * (1 - ripple)).clamp(0.0, 1.0).toDouble(),
                              child: Container(
                                height: 32,
                                constraints: const BoxConstraints(minWidth: 58),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: p.goldLight,
                                    width: 2,
                                  ),
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: .45),
                                      Colors.white.withValues(alpha: 0),
                                    ],
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
            ),
          ),
        );
      },
    );
  }
}

class _TraceCard extends StatefulWidget {
  final Widget child;
  final double radius;

  const _TraceCard({required this.child, required this.radius});

  @override
  State<_TraceCard> createState() => _TraceCardState();
}

class _TraceCardState extends State<_TraceCard>
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
    final p = DPV3Palette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: p.softShadow,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          foregroundPainter: _TraceBorderPainter(
            p: p,
            radius: widget.radius,
            progress: _controller.value,
          ),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _TraceBorderPainter extends CustomPainter {
  final DPV3Palette p;
  final double radius;
  final double progress;

  _TraceBorderPainter({
    required this.p,
    required this.radius,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(1.5),
          Radius.circular(math.max(0, radius - 1.5)),
        ),
      );
    final metric = path.computeMetrics().first;
    final length = metric.length;
    final eased = Curves.easeInOutCubic.transform(progress);
    final start = ((eased * 2) - .5) * length;
    final segment = length * .50;
    final opacity = progress < .08
        ? _lerp(.2, 1, progress / .08)
        : progress > .92
            ? _lerp(1, .2, (progress - .92) / .08)
            : 1.0;

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = p.goldFill.withValues(alpha: .18 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFFF0D78C), Color(0xFFC9A227), Color(0xFFD4AF37)],
      ).createShader(rect)
      ..color = Colors.white.withValues(alpha: opacity);

    void drawSegment(Paint paint) {
      var localStart = start % length;
      if (localStart < 0) localStart += length;
      final localEnd = localStart + segment;
      if (localEnd <= length) {
        canvas.drawPath(metric.extractPath(localStart, localEnd), paint);
      } else {
        canvas.drawPath(metric.extractPath(localStart, length), paint);
        canvas.drawPath(metric.extractPath(0, localEnd - length), paint);
      }
    }

    canvas.saveLayer(rect, Paint()..color = Colors.white.withValues(alpha: opacity));
    drawSegment(glow);
    drawSegment(stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TraceBorderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.p.dark != p.dark ||
      oldDelegate.radius != radius;
}

class _HeroBeamLayer extends StatelessWidget {
  final bool dark;
  const _HeroBeamLayer({required this.dark});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: constraints.maxWidth * .40,
              top: -constraints.maxHeight * .60,
              child: _AnimatedBeam(
                width: 90,
                height: constraints.maxHeight * 2.20,
                duration: const Duration(seconds: 9),
                blur: 14,
                dark: dark,
              ),
            ),
            Positioned(
              left: constraints.maxWidth * .62,
              top: -constraints.maxHeight * .60,
              child: _AnimatedBeam(
                width: 46,
                height: constraints.maxHeight * 2.20,
                duration: const Duration(seconds: 12),
                delay: const Duration(milliseconds: 1500),
                blur: 10,
                dark: dark,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedBeam extends StatefulWidget {
  final double width;
  final double height;
  final Duration duration;
  final Duration delay;
  final double blur;
  final bool dark;

  const _AnimatedBeam({
    required this.width,
    required this.height,
    required this.duration,
    this.delay = Duration.zero,
    required this.blur,
    required this.dark,
  });

  @override
  State<_AnimatedBeam> createState() => _AnimatedBeamState();
}

class _AnimatedBeamState extends State<_AnimatedBeam>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final durationMs = widget.duration.inMilliseconds;
    final phase = durationMs == 0
        ? 0.0
        : (widget.delay.inMilliseconds % durationMs) / durationMs;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: phase,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final wave =
            (1 - math.cos(_controller.value * math.pi * 2)) / 2;
        final opacity = _lerp(.35, .85, wave);
        final dx = _lerp(-widget.width * .08, widget.width * .08, wave);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.rotate(angle: 22 * math.pi / 180, child: child),
          ),
        );
      },
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: widget.blur,
          sigmaY: widget.blur,
        ),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                widget.dark
                    ? p.goldFill.withValues(alpha: .22)
                    : Colors.white.withValues(alpha: .75),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleSpec {
  final double x;
  final double size;
  final Duration duration;
  final Duration delay;
  final double? y;
  final double? top;

  const _BubbleSpec({
    required this.x,
    required this.size,
    required this.duration,
    required this.delay,
    this.y,
    this.top,
  }) : assert(y != null || top != null);
}

const _heroBubbleSpecs = [
  _BubbleSpec(x: .34, y: .10, size: 38, duration: Duration(seconds: 9), delay: Duration.zero),
  _BubbleSpec(x: .47, y: .58, size: 18, duration: Duration(seconds: 7), delay: Duration(milliseconds: 1200)),
  _BubbleSpec(x: .90, y: .52, size: 54, duration: Duration(seconds: 11), delay: Duration(milliseconds: 500)),
  _BubbleSpec(x: .64, y: .76, size: 24, duration: Duration(seconds: 8), delay: Duration(seconds: 2)),
  _BubbleSpec(x: .12, y: .70, size: 30, duration: Duration(milliseconds: 9500), delay: Duration(milliseconds: 800)),
  _BubbleSpec(x: .78, y: .34, size: 12, duration: Duration(seconds: 6), delay: Duration(milliseconds: 1600)),
  _BubbleSpec(x: .24, y: .40, size: 10, duration: Duration(milliseconds: 6500), delay: Duration(milliseconds: 2400)),
];

const _cinePlannerBubbleSpecs = [
  _BubbleSpec(x: .44, y: .10, size: 46, duration: Duration(seconds: 9), delay: Duration.zero),
  _BubbleSpec(x: .52, y: .72, size: 22, duration: Duration(seconds: 7), delay: Duration(milliseconds: 1100)),
  _BubbleSpec(x: .93, y: .06, size: 30, duration: Duration(seconds: 8), delay: Duration(milliseconds: 400)),
  _BubbleSpec(x: .04, y: .80, size: 18, duration: Duration(milliseconds: 6500), delay: Duration(milliseconds: 1800)),
  _BubbleSpec(x: .34, y: .48, size: 12, duration: Duration(seconds: 6), delay: Duration(milliseconds: 700)),
  _BubbleSpec(x: .86, y: .74, size: 56, duration: Duration(seconds: 10), delay: Duration(milliseconds: 2200)),
];

const _financeBubbleSpecs = [
  _BubbleSpec(x: .42, top: 12, size: 26, duration: Duration(seconds: 9), delay: Duration.zero),
  _BubbleSpec(x: .56, top: 20, size: 14, duration: Duration(seconds: 7), delay: Duration(milliseconds: 1300)),
  _BubbleSpec(x: .68, top: 8, size: 20, duration: Duration(seconds: 8), delay: Duration(milliseconds: 600)),
  _BubbleSpec(x: .26, y: .48, size: 14, duration: Duration(milliseconds: 6500), delay: Duration(seconds: 2)),
  _BubbleSpec(x: .34, y: .56, size: 10, duration: Duration(seconds: 6), delay: Duration(seconds: 1)),
  _BubbleSpec(x: .96, top: 4, size: 18, duration: Duration(milliseconds: 6800), delay: Duration(milliseconds: 300)),
];

class _FloatingBubbleLayer extends StatelessWidget {
  final List<_BubbleSpec> specs;
  const _FloatingBubbleLayer({required this.specs});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          for (final spec in specs)
            Positioned(
              left: constraints.maxWidth * spec.x,
              top: spec.top ?? constraints.maxHeight * (spec.y ?? 0),
              child: _DriftingBubble(spec: spec),
            ),
        ],
      ),
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

  @override
  void initState() {
    super.initState();
    final durationMs = widget.spec.duration.inMilliseconds;
    final phase = durationMs == 0
        ? 0.0
        : (widget.spec.delay.inMilliseconds % durationMs) / durationMs;
    _controller = AnimationController(
      vsync: this,
      duration: widget.spec.duration,
      value: phase,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _drift(double t) {
    if (t <= .30) {
      final q = Curves.easeInOut.transform(t / .30);
      return Offset(_lerp(0, 12, q), _lerp(0, -20, q));
    }
    if (t <= .65) {
      final q = Curves.easeInOut.transform((t - .30) / .35);
      return Offset(_lerp(12, -10, q), _lerp(-20, -8, q));
    }
    final q = Curves.easeInOut.transform((t - .65) / .35);
    return Offset(_lerp(-10, 0, q), _lerp(-8, 0, q));
  }

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: _drift(_controller.value),
        child: child,
      ),
      child: Container(
        width: widget.spec.size,
        height: widget.spec.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-.36, -.44),
            radius: .82,
            stops: const [0, .18, .44, .62, .74],
            colors: p.dark
                ? const [
                    Color(0xBFFFFFFF),
                    Color(0x4DBEDEFF),
                    Color(0x2ECDC0FF),
                    Color(0x1FFFCDB4),
                    Color(0x08FFFFFF),
                  ]
                : const [
                    Color(0xFAFFFFFF),
                    Color(0x80D6ECFF),
                    Color(0x52E4DCFF),
                    Color(0x33FFE2CE),
                    Color(0x00FFFFFF),
                  ],
          ),
          border: Border.all(
            color: p.dark
                ? const Color(0x57D2E6FF)
                : Colors.white.withValues(alpha: .90),
          ),
          boxShadow: p.dark
              ? const [
                  BoxShadow(
                    color: Color(0x4DBEDEFF),
                    blurRadius: 18,
                    spreadRadius: -6,
                  ),
                  BoxShadow(
                    color: Color(0x40C8E1FF),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: p.goldFill.withValues(alpha: .30),
                    blurRadius: 12,
                    spreadRadius: -6,
                    offset: const Offset(-4, -6),
                  ),
                  const BoxShadow(
                    color: Color(0x38000000),
                    blurRadius: 20,
                    spreadRadius: -12,
                    offset: Offset(0, 8),
                  ),
                ],
        ),
      ),
    );
  }
}

class _DiagonalLinePainter extends CustomPainter {
  final DPV3Palette p;
  _DiagonalLinePainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: p.dark ? .018 : .065)
      ..strokeWidth = 1;
    const spacing = 30.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height * .48, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalLinePainter oldDelegate) => false;
}

class _LiveTicker extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _LiveTicker({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final liveItems = dashboard.activity.isNotEmpty
        ? dashboard.activity.take(6).map((a) {
            return _TickerItem(
              keyLetter: a.itemType.isEmpty ? 'A' : a.itemType[0].toUpperCase(),
              title: a.title,
              meta: a.projectTitle,
              ago: _relative(a.createdAt),
            );
          }).toList()
        : const [
            _TickerItem(
              keyLetter: 'B',
              title: 'Booking under negotiation',
              meta: 'Testing Drama · Laila Noor',
              ago: '60d',
            ),
            _TickerItem(
              keyLetter: 'C',
              title: 'Contract awaiting signature',
              meta: 'River Lights · Ayaan Malik',
              ago: '3d',
            ),
            _TickerItem(
              keyLetter: 'A',
              title: 'New applications',
              meta: 'testing3 · 9 applicants',
              ago: '1d',
            ),
          ];
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.line),
        boxShadow: p.softShadow,
      ),
      child: Row(
        children: [
          _PulsingDot(color: p.negative, size: 7, period: const Duration(milliseconds: 1400)),
          const SizedBox(width: 7),
          Text(
            'LIVE',
            style: dpV3Sans(11, p,
                weight: FontWeight.w800,
                color: p.negative,
                letterSpacing: 1.4),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 20, color: p.line),
          const SizedBox(width: 14),
          Expanded(
            child: ClipRect(
              child: _AutoMarquee(
                duration: const Duration(seconds: 40),
                gap: 38,
                children: liveItems
                    .map((item) => _TickerTile(item: item))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TickerItem {
  final String keyLetter;
  final String title;
  final String meta;
  final String ago;

  const _TickerItem({
    required this.keyLetter,
    required this.title,
    required this.meta,
    required this.ago,
  });
}

class _TickerTile extends StatelessWidget {
  final _TickerItem item;
  const _TickerTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: p.goldSoft, shape: BoxShape.circle),
          child: Text(
            item.keyLetter,
            style: dpV3Sans(10.5, p,
                weight: FontWeight.w800, color: p.gold),
          ),
        ),
        const SizedBox(width: 9),
        Text(item.title, style: dpV3Sans(12.5, p, weight: FontWeight.w700)),
        const SizedBox(width: 9),
        Text(item.meta, style: dpV3Sans(12.5, p, color: p.muted)),
        const SizedBox(width: 9),
        Text(
          item.ago,
          style: dpV3Sans(12, p, weight: FontWeight.w700, color: p.gold),
        ),
      ],
    );
  }
}

class _PlannerWorkspace extends StatelessWidget {
  final DirectorDashboard dashboard;
  final DateTime now;
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<_PlanItem> plans;
  final bool adding;
  final TextEditingController planTitle;
  final TextEditingController planMeta;
  final TimeOfDay planTime;
  final String planType;
  final bool medium;
  final bool mobile;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onStartAdd;
  final VoidCallback onCancelAdd;
  final ValueChanged<String> onType;
  final VoidCallback onTime;
  final ValueChanged<String> onRemove;
  final VoidCallback onSave;

  const _PlannerWorkspace({
    required this.dashboard,
    required this.now,
    required this.visibleMonth,
    required this.selectedDate,
    required this.plans,
    required this.adding,
    required this.planTitle,
    required this.planMeta,
    required this.planTime,
    required this.planType,
    required this.medium,
    required this.mobile,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onSelectDate,
    required this.onStartAdd,
    required this.onCancelAdd,
    required this.onType,
    required this.onTime,
    required this.onRemove,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final calendar = _CalendarCard(
      visibleMonth: visibleMonth,
      selectedDate: selectedDate,
      plans: plans,
      onPrevMonth: onPrevMonth,
      onNextMonth: onNextMonth,
      onToday: onToday,
      onSelectDate: onSelectDate,
    );
    final day = _DayPlannerCard(
      selectedDate: selectedDate,
      plans: plans,
      adding: adding,
      planTitle: planTitle,
      planMeta: planMeta,
      planTime: planTime,
      planType: planType,
      onStartAdd: onStartAdd,
      onCancelAdd: onCancelAdd,
      onType: onType,
      onTime: onTime,
      onRemove: onRemove,
      onSave: onSave,
    );
    final side = _PlannerSideStats(dashboard: dashboard, now: now, mobile: medium);

    if (medium) {
      return Column(
        children: [
          side,
          const SizedBox(height: 16),
          calendar,
          const SizedBox(height: 16),
          day,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 232, child: side),
        const SizedBox(width: 16),
        Expanded(child: calendar),
        const SizedBox(width: 16),
        SizedBox(width: 340, child: day),
      ],
    );
  }
}

class _PlannerSideStats extends StatelessWidget {
  final DirectorDashboard dashboard;
  final DateTime now;
  final bool mobile;

  const _PlannerSideStats({
    required this.dashboard,
    required this.now,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    final summary = dashboard.summary;
    final total = summary.paidMinor + summary.pendingPaymentMinor;
    final progress = total == 0 ? 0.0 : summary.paidMinor / total;
    final clock = _ClockCard(now: now);
    final payment = _PaymentCycleCard(
      progress: progress,
      amount: _moneyMinor(summary.paidMinor, summary.currency),
    );
    if (mobile) {
      return Row(
        children: [
          Expanded(child: clock),
          const SizedBox(width: 12),
          Expanded(child: payment),
        ],
      );
    }
    return Column(
      children: [
        SizedBox(height: 188, child: clock),
        const SizedBox(height: 16),
        SizedBox(height: 188, child: payment),
      ],
    );
  }
}

class _ClockCard extends StatelessWidget {
  final DateTime now;
  const _ClockCard({required this.now});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: CustomPaint(painter: _ClockPainter(now: now, p: p)),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('hh:mm:ss a').format(now),
            style: dpV3Sans(13, p, weight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text('Lahore · PKT', style: dpV3Sans(11.5, p, color: p.muted)),
        ],
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final DateTime now;
  final DPV3Palette p;
  _ClockPainter({required this.now, required this.p});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 2;
    final fill = Paint()..color = p.cardAlt;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = p.line;
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, border);

    for (var i = 0; i < 60; i++) {
      final major = i % 5 == 0;
      final angle = i * math.pi / 30 - math.pi / 2;
      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 7),
        center.dy + math.sin(angle) * (radius - 7),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - (major ? 15 : 11)),
        center.dy + math.sin(angle) * (radius - (major ? 15 : 11)),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = major ? p.gold : p.line
          ..strokeWidth = major ? 1.5 : .8
          ..strokeCap = StrokeCap.round,
      );
    }

    void hand(double angle, double length, double width, Color color) {
      canvas.drawLine(
        center,
        Offset(
          center.dx + math.cos(angle - math.pi / 2) * length,
          center.dy + math.sin(angle - math.pi / 2) * length,
        ),
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    hand((now.hour % 12 + now.minute / 60) * math.pi / 6, radius * .48, 3.5, p.ink);
    hand((now.minute + now.second / 60) * math.pi / 30, radius * .72, 2.2, p.ink);
    hand(now.second * math.pi / 30, radius * .82, 1.1, p.goldFill);
    canvas.drawCircle(center, 3.4, Paint()..color = p.goldFill);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) => oldDelegate.now.second != now.second;
}

class _PaymentCycleCard extends StatelessWidget {
  final double progress;
  final String amount;

  const _PaymentCycleCard({required this.progress, required this.amount});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0).toDouble(),
                    strokeWidth: 8,
                    color: p.goldFill,
                    backgroundColor: p.goldSoft,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: dpV3Sans(11.5, p,
                      weight: FontWeight.w800, color: p.gold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(amount, style: dpV3Sans(17, p, weight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(
            'Payments cleared this cycle',
            textAlign: TextAlign.center,
            style: dpV3Sans(12, p, color: p.muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<_PlanItem> plans;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onSelectDate;

  const _CalendarCard({
    required this.visibleMonth,
    required this.selectedDate,
    required this.plans,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final first = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final days = DateUtils.getDaysInMonth(visibleMonth.year, visibleMonth.month);
    final leading = first.weekday % 7;
    final totalCells = ((leading + days + 6) ~/ 7) * 7;
    const week = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final today = DateTime.now();
    return _SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                DateFormat('MMMM yyyy').format(visibleMonth),
                style: dpV3Serif(19, p, weight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              _PillButton(label: 'Today', onTap: onToday, active: true),
              const Spacer(),
              _CircleButton(icon: Icons.chevron_left_rounded, onTap: onPrevMonth),
              const SizedBox(width: 8),
              _CircleButton(icon: Icons.chevron_right_rounded, onTap: onNextMonth),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.25,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (final d in week)
                Center(
                  child: Text(
                    d,
                    style: dpV3Sans(11, p,
                        weight: FontWeight.w700,
                        color: p.muted,
                        letterSpacing: .6),
                  ),
                ),
              for (var cell = 0; cell < totalCells; cell++)
                Builder(builder: (context) {
                  final day = cell - leading + 1;
                  if (day < 1 || day > days) return const SizedBox.shrink();
                  final date = DateTime(visibleMonth.year, visibleMonth.month, day);
                  final selected = DateUtils.isSameDay(date, selectedDate);
                  final isToday = DateUtils.isSameDay(date, today);
                  final dayPlans = plans.where((e) => DateUtils.isSameDay(e.startsAt, date)).toList();
                  return InkWell(
                    onTap: () => onSelectDate(date),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: selected
                            ? p.goldFill
                            : dayPlans.isNotEmpty
                                ? p.cardAlt
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isToday && !selected
                            ? Border.all(color: p.goldFill, width: 1.5)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: dpV3Sans(
                              13,
                              p,
                              weight: selected || isToday
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: selected ? const Color(0xFF1A1408) : p.inkSoft,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final event in dayPlans.take(3)) ...[
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFF1A1408)
                                          : _planColor(p, event.type),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: p.lineSoft),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (final type in const ['Shoot', 'Recce', 'Casting', 'Meeting', 'Payment'])
                _Legend(type: type, color: _planColor(p, type)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String type;
  final Color color;
  const _Legend({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(type, style: dpV3Sans(11.5, p, color: p.muted)),
      ],
    );
  }
}

class _DayPlannerCard extends StatelessWidget {
  final DateTime selectedDate;
  final List<_PlanItem> plans;
  final bool adding;
  final TextEditingController planTitle;
  final TextEditingController planMeta;
  final TimeOfDay planTime;
  final String planType;
  final VoidCallback onStartAdd;
  final VoidCallback onCancelAdd;
  final ValueChanged<String> onType;
  final VoidCallback onTime;
  final ValueChanged<String> onRemove;
  final VoidCallback onSave;

  const _DayPlannerCard({
    required this.selectedDate,
    required this.plans,
    required this.adding,
    required this.planTitle,
    required this.planMeta,
    required this.planTime,
    required this.planType,
    required this.onStartAdd,
    required this.onCancelAdd,
    required this.onType,
    required this.onTime,
    required this.onRemove,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final today = DateTime.now();
    final selectedPlans = plans.where((e) => DateUtils.isSameDay(e.startsAt, selectedDate)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final label = DateUtils.isSameDay(today, selectedDate)
        ? 'Today'
        : DateFormat('EEE, d MMM').format(selectedDate);
    return _SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLANNER',
                      style: dpV3Sans(11, p,
                          weight: FontWeight.w800,
                          color: p.gold,
                          letterSpacing: 1.6),
                    ),
                    const SizedBox(height: 3),
                    Text(label, style: dpV3Serif(18, p, weight: FontWeight.w600)),
                  ],
                ),
              ),
              Text(
                selectedPlans.isEmpty
                    ? ''
                    : '${selectedPlans.length} plan${selectedPlans.length == 1 ? '' : 's'}',
                style: dpV3Sans(12, p, color: p.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedPlans.isEmpty)
            Container(
              constraints: const BoxConstraints(minHeight: 150),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: p.lineSoft))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_outlined, color: p.goldFill, size: 28),
                  const SizedBox(height: 8),
                  Text('Nothing planned', style: dpV3Sans(13.5, p, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Add a shoot, recce or meeting.', style: dpV3Sans(12, p, color: p.muted)),
                ],
              ),
            )
          else
            for (final event in selectedPlans)
              _PlanRow(item: event, onRemove: () => onRemove(event.id)),
          if (adding) ...[
            const SizedBox(height: 12),
            _AddPlanForm(
              title: planTitle,
              meta: planMeta,
              time: planTime,
              type: planType,
              onTime: onTime,
              onType: onType,
              onCancel: onCancelAdd,
              onSave: onSave,
            ),
          ] else ...[
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              shape: StadiumBorder(side: BorderSide(color: p.glassLine, width: 1.5)),
              child: InkWell(
                onTap: onStartAdd,
                customBorder: const StadiumBorder(),
                child: SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 17, color: p.gold),
                      const SizedBox(width: 8),
                      Text('Add plan', style: dpV3Sans(13.5, p, weight: FontWeight.w700, color: p.gold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final _PlanItem item;
  final VoidCallback onRemove;
  const _PlanRow({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final c = _planColor(p, item.type);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.lineSoft))),
      child: Row(
        children: [
          Container(width: 3, height: 40, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(DateFormat('HH:mm').format(item.startsAt), style: dpV3Sans(12.5, p, weight: FontWeight.w800, color: p.gold)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: dpV3Sans(13.5, p, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(item.type.toUpperCase(), style: dpV3Sans(10, p, weight: FontWeight.w800, color: c, letterSpacing: .6)),
                    const SizedBox(width: 7),
                    Expanded(child: Text(item.meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: dpV3Sans(11.5, p, color: p.muted))),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 16, color: p.muted),
          ),
        ],
      ),
    );
  }
}

class _AddPlanForm extends StatelessWidget {
  final TextEditingController title;
  final TextEditingController meta;
  final TimeOfDay time;
  final String type;
  final VoidCallback onTime;
  final ValueChanged<String> onType;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _AddPlanForm({
    required this.title,
    required this.meta,
    required this.time,
    required this.type,
    required this.onTime,
    required this.onType,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: dpV3Sans(12.5, p, color: p.muted),
          filled: true,
          fillColor: p.card,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.goldFill)),
        );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.cardAlt, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.glassLine)),
      child: Column(
        children: [
          TextField(controller: title, style: dpV3Sans(13.5, p), decoration: deco('Plan title — e.g. Recce, Haveli')),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: onTime,
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.ink,
                  side: BorderSide(color: p.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
                ),
                child: Text(time.format(context), style: dpV3Sans(12.5, p)),
              ),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: meta, style: dpV3Sans(13.5, p), decoration: deco('Where / notes'))),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in const ['Shoot', 'Recce', 'Casting', 'Meeting', 'Payment'])
                _FilterChip(label: t, active: type == t, dot: _planColor(p, t), onTap: () => onType(t)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _PillButton(label: 'Cancel', onTap: onCancel),
              const SizedBox(width: 8),
              _PillButton(label: 'Save plan', onTap: onSave, active: true, filled: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttentionPanel extends StatelessWidget {
  final DirectorDashboard dashboard;
  const _AttentionPanel({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final items = dashboard.priorityActions.take(3).toList();
    return _SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.goldSoft, borderRadius: BorderRadius.circular(10)),
                child: Text('!', style: dpV3Sans(15, p, weight: FontWeight.w900, color: p.warning)),
              ),
              const SizedBox(width: 10),
              Text('Needs your attention', style: dpV3Sans(16, p, weight: FontWeight.w800)),
              const SizedBox(width: 10),
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.goldFill, borderRadius: BorderRadius.circular(999)),
                child: Text('${dashboard.summary.attentionCount}', style: dpV3Sans(12, p, weight: FontWeight.w800, color: const Color(0xFF1A1408))),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, CoreRoutes.notifications),
                child: Text('View all', style: dpV3Sans(13.5, p, weight: FontWeight.w700, color: p.gold)),
              ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: p.positive, size: 18),
                  const SizedBox(width: 8),
                  Text('All caught up — nothing needs your attention right now.', style: dpV3Sans(12.5, p, color: p.muted)),
                ],
              ),
            )
          else
            for (final item in items) _AttentionRow(item: item),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final DirectorPriorityAction item;
  const _AttentionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final c = switch (item.tone) {
      'danger' || 'critical' => p.negative,
      'warning' => p.warning,
      'success' => p.positive,
      'info' => p.info,
      _ => p.gold,
    };
    final route = item.route.contains(':id') ? DirectorProducerRoutes.projectDetail : item.route;
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route, arguments: item.argument),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: p.lineSoft))),
        child: Row(
          children: [
            Container(width: 3, height: 34, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: dpV3Sans(13.5, p, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: dpV3Sans(12.5, p, color: p.muted)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.cardAlt, borderRadius: BorderRadius.circular(999), border: Border.all(color: p.line)),
              child: Text(item.urgency, style: dpV3Sans(11.5, p, weight: FontWeight.w800, color: c)),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: p.muted),
          ],
        ),
      ),
    );
  }
}

class _ProjectDeckV3 extends StatelessWidget {
  final List<DpProject> projects;
  final String selected;
  final ValueChanged<String> onFilter;

  const _ProjectDeckV3({
    required this.projects,
    required this.selected,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    const filters = ['All', 'Film', 'Drama', 'Fashion', 'Commercial'];
    final filtered = projects.where((project) => selected == 'All' || project.type.toLowerCase() == selected.toLowerCase()).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Project Command Deck', style: dpV3Sans(17, p, weight: FontWeight.w800)),
              for (final filter in filters)
                _FilterChip(label: filter, active: selected == filter, onTap: () => onFilter(filter)),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, DirectorProducerRoutes.projects),
                child: Text('View all', style: dpV3Sans(13.5, p, weight: FontWeight.w700, color: p.gold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 374,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 18),
            itemCount: filtered.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == filtered.length) {
                return _NewProjectPoster(
                  onTap: () => Navigator.pushNamed(context, DirectorProducerRoutes.createProject),
                );
              }
              final project = filtered[index];
              return _ProjectPoster(
                project: project,
                index: index,
                onTap: () => Navigator.pushNamed(
                  context,
                  DirectorProducerRoutes.projectDetail,
                  arguments: project.id,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProjectPoster extends StatefulWidget {
  final DpProject project;
  final int index;
  final VoidCallback onTap;

  const _ProjectPoster({required this.project, required this.index, required this.onTap});

  @override
  State<_ProjectPoster> createState() => _ProjectPosterState();
}

class _ProjectPosterState extends State<_ProjectPoster> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final project = widget.project;
    final statusColor = switch (project.status.toLowerCase()) {
      'active' => p.positive,
      'contracting' => p.warning,
      'casting' => p.violet,
      'closed' || 'completed' => p.muted,
      _ => p.info,
    };
    final budget = (project.budgetHealth * 100).clamp(0, 100).round();
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedSlide(
        offset: _hover ? const Offset(0, -.023) : Offset.zero,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: _hover ? 1.015 : 1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: 256,
            decoration: BoxDecoration(
              gradient: _posterGradient(p, widget.index, project.title),
              borderRadius: BorderRadius.circular(26),
              boxShadow: p.posterShadow,
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _DiagonalLinePainter(p))),
                Positioned.fill(
                  child: IgnorePointer(
                    child: _SheenSweep(
                      delay: Duration(milliseconds: widget.index * 110),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, p.cardAlt.withValues(alpha: p.dark ? .35 : .68), p.cardAlt.withValues(alpha: p.dark ? .95 : .96)],
                        stops: const [.35, .67, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatusPill(label: project.status, color: statusColor),
                      Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: p.goldFill, borderRadius: BorderRadius.circular(999)),
                        child: Text(project.type, style: dpV3Sans(11, p, weight: FontWeight.w800, color: const Color(0xFF1A1408))),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(project.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: dpV3Sans(18, p, weight: FontWeight.w800, height: 1.15)),
                      const SizedBox(height: 5),
                      Text('${project.city} · ${project.dateRange}', maxLines: 1, overflow: TextOverflow.ellipsis, style: dpV3Sans(12.5, p, color: p.inkSoft)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('Budget health', style: dpV3Sans(11, p, color: p.inkSoft)),
                          const Spacer(),
                          Text('$budget%', style: dpV3Sans(11, p, weight: FontWeight.w800, color: p.gold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          value: (budget / 100).clamp(.015, 1.0).toDouble(),
                          backgroundColor: p.line,
                          valueColor: AlwaysStoppedAnimation(p.goldFill),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text('${project.pendingActions} actions · ${project.shootDate}', maxLines: 1, overflow: TextOverflow.ellipsis, style: dpV3Sans(11.5, p, color: p.inkSoft)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(color: p.glass, borderRadius: BorderRadius.circular(999), border: Border.all(color: p.line)),
                            child: Row(
                              children: [
                                Text('Open Hub', style: dpV3Sans(12.5, p, weight: FontWeight.w700)),
                                const SizedBox(width: 6),
                                Icon(Icons.open_in_new_rounded, size: 14, color: p.ink),
                              ],
                            ),
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
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: p.glass, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: dpV3Sans(11, p, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NewProjectPoster extends StatelessWidget {
  final VoidCallback onTap;
  const _NewProjectPoster({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 256,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: p.glassLine, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.goldSoft, shape: BoxShape.circle),
              child: Icon(Icons.add_rounded, color: p.gold, size: 24),
            ),
            const SizedBox(height: 10),
            Text('New project', style: dpV3Sans(14, p, weight: FontWeight.w800, color: p.gold)),
          ],
        ),
      ),
    );
  }
}

class _CinePlannerFeature extends StatelessWidget {
  const _CinePlannerFeature();

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: p.cinePlannerGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: p.glassLine),
        boxShadow: p.posterShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _CinePlannerWashPainter(p)),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      Positioned(
                        left: constraints.maxWidth * .30,
                        top: -constraints.maxHeight * .60,
                        child: _AnimatedBeam(
                          width: 70,
                          height: constraints.maxHeight * 2.20,
                          duration: const Duration(seconds: 10),
                          blur: 12,
                          dark: p.dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: _FloatingBubbleLayer(specs: _cinePlannerBubbleSpecs),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 820;
                  final copy = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CINEPLANNER',
                            style: dpV3Sans(
                              10,
                              p,
                              weight: FontWeight.w800,
                              color: p.gold,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: p.goldFill,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'AI',
                              style: dpV3Sans(
                                10,
                                p,
                                weight: FontWeight.w800,
                                color: const Color(0xFF1A1408),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          style: dpV3Serif(
                            25,
                            p,
                            weight: FontWeight.w500,
                            height: 1.05,
                            letterSpacing: -.5,
                          ),
                          children: [
                            const TextSpan(text: 'From screenplay\n'),
                            TextSpan(
                              text: 'to call sheet.',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: p.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Break down scenes, schedule days, issue call sheets.',
                        style: dpV3Sans(12.5, p, color: p.muted),
                      ),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          _CpStat(value: '48', label: 'Scenes'),
                          SizedBox(width: 18),
                          _CpStat(value: '12', label: 'Shoot days'),
                          SizedBox(width: 18),
                          _CpStat(value: '3', label: 'Call sheets'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _GoldAction(
                            label: 'Plan now',
                            icon: Icons.arrow_forward_rounded,
                            onTap: () => Navigator.pushNamed(
                              context,
                              DirectorProducerRoutes.cinePlanner,
                            ),
                          ),
                          _GlassAction(
                            label: 'Upload script',
                            icon: Icons.upload_rounded,
                            onTap: () => Navigator.pushNamed(
                              context,
                              DirectorProducerRoutes.cinePlanner,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                  const scenes = _SceneMarquee();
                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [copy, const SizedBox(height: 22), scenes],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(flex: 10, child: copy),
                      const SizedBox(width: 24),
                      const Expanded(flex: 11, child: scenes),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CinePlannerWashPainter extends CustomPainter {
  final DPV3Palette p;
  _CinePlannerWashPainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..shader = RadialGradient(
        colors: [
          p.goldFill.withValues(alpha: .07),
          p.goldFill.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(0, 0),
        radius: math.max(size.width, size.height) * .75,
      ));
    canvas.drawRect(Offset.zero & size, gold);

    final ice = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x1496BEE1), Color(0x0096BEE1)],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width, size.height),
        radius: math.max(size.width, size.height) * .65,
      ));
    canvas.drawRect(Offset.zero & size, ice);
  }

  @override
  bool shouldRepaint(covariant _CinePlannerWashPainter oldDelegate) =>
      oldDelegate.p.dark != p.dark;
}

class _CpStat extends StatelessWidget {
  final String value;
  final String label;
  const _CpStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: dpV3Sans(15, p, weight: FontWeight.w800)),
        const SizedBox(height: 1),
        Text(label, style: dpV3Sans(10.5, p, color: p.muted)),
      ],
    );
  }
}

class _SceneMarquee extends StatelessWidget {
  const _SceneMarquee();

  static const scenes = [
    ('12', 'INT. HAVELI — NIGHT', '2 pg'),
    ('13', 'EXT. ROOFTOP — DUSK', '1⅜ pg'),
    ('14', 'INT. STUDIO 4 — DAY', '3 pg'),
    ('15', 'EXT. CLIFTON — DAY', '⅞ pg'),
    ('16', 'INT. CAR — NIGHT', '1 pg'),
    ('17', 'EXT. COURTYARD — DAY', '2½ pg'),
    ('18', 'INT. KITCHEN — MORNING', '1¼ pg'),
    ('19', 'EXT. MARKET — DAY', '2 pg'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: Column(
        children: [
          Expanded(
            child: ClipRect(
              child: _AutoMarquee(
                duration: const Duration(seconds: 35),
                gap: 10,
                children: [for (var i = 0; i < scenes.length; i++) _SceneChip(scene: scenes[i], colorIndex: i)],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRect(
              child: _AutoMarquee(
                duration: const Duration(seconds: 42),
                reverse: true,
                gap: 10,
                children: [for (var i = scenes.length - 1; i >= 0; i--) _SceneChip(scene: scenes[i], colorIndex: i + 2)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneChip extends StatelessWidget {
  final (String, String, String) scene;
  final int colorIndex;
  const _SceneChip({required this.scene, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final colors = [p.ice, p.mint, p.lavender, p.peach, p.goldLight];
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(color: p.glass, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('SC ${scene.$1}', style: dpV3Sans(9, p, weight: FontWeight.w800, color: p.gold, letterSpacing: 1)),
              const Spacer(),
              Text(scene.$3, style: dpV3Sans(9, p, weight: FontWeight.w800, color: p.muted)),
            ],
          ),
          const SizedBox(height: 5),
          Text(scene.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: dpV3Sans(10.5, p, weight: FontWeight.w700)),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(width: 48 + (colorIndex % 4) * 14, height: 3, decoration: BoxDecoration(color: colors[colorIndex % colors.length], borderRadius: BorderRadius.circular(3))),
          ),
        ],
      ),
    );
  }
}

class _DiscoverDeck extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onFilter;
  const _DiscoverDeck({required this.selected, required this.onFilter});

  static const entries = [
    _DiscoverEntry('Laila Noor', 'Actor', 'Actor · Lahore', '4.9', true, 20),
    _DiscoverEntry('Haveli Studios', 'Location', 'Heritage property · Lahore', '4.8', true, 150),
    _DiscoverEntry('ARRI Alexa Mini LF', 'Equipment', 'Camera kit · Lahore', '4.9', true, 215),
    _DiscoverEntry('Bilal Raza', 'Crew', 'DOP · Karachi', '4.7', false, 265),
    _DiscoverEntry('Sara Ahmed', 'Model', 'Fashion model · Lahore', '4.8', true, 340),
    _DiscoverEntry('Ayaan Malik', 'Actor', 'Actor · Karachi', '4.6', true, 30),
    _DiscoverEntry('Clifton Rooftop', 'Location', 'Rooftop · Karachi', '4.5', false, 195),
    _DiscoverEntry('Hina Shah', 'Crew', 'Costume designer · Lahore', '4.9', true, 300),
  ];

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    const filters = ['All', 'Actors', 'Models', 'Locations', 'Crew', 'Equipment'];
    final map = {'Actors': 'Actor', 'Models': 'Model', 'Locations': 'Location'};
    final type = map[selected] ?? selected;
    final filtered = entries.where((e) => selected == 'All' || e.category == type).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Discover', style: dpV3Sans(17, p, weight: FontWeight.w800)),
              for (final filter in filters)
                _FilterChip(label: filter, active: selected == filter, onTap: () => onFilter(filter)),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, DirectorProducerRoutes.marketplace),
                child: Text('Review applications', style: dpV3Sans(13.5, p, weight: FontWeight.w700, color: p.gold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 270,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 18),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => _DiscoverCard(entry: filtered[index], index: index),
          ),
        ),
      ],
    );
  }
}

class _DiscoverEntry {
  final String name;
  final String category;
  final String role;
  final String rating;
  final bool verified;
  final int hue;
  const _DiscoverEntry(this.name, this.category, this.role, this.rating, this.verified, this.hue);
}

class _DiscoverCard extends StatefulWidget {
  final _DiscoverEntry entry;
  final int index;
  const _DiscoverCard({required this.entry, required this.index});

  @override
  State<_DiscoverCard> createState() => _DiscoverCardState();
}

class _DiscoverCardState extends State<_DiscoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final e = widget.entry;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedSlide(
        offset: _hover ? const Offset(0, -.032) : Offset.zero,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: _hover ? 1.02 : 1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: InkWell(
          onTap: () => Navigator.pushNamed(context, DirectorProducerRoutes.marketplace),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 180,
            decoration: BoxDecoration(
              gradient: _posterGradient(p, widget.index + 7, e.name),
              borderRadius: BorderRadius.circular(24),
              boxShadow: p.posterShadow,
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _DiagonalLinePainter(p))),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 42),
                    child: Text(_initials(e.name), style: dpV3Serif(52, p, weight: FontWeight.w500, color: p.ink.withValues(alpha: .08))),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, p.cardAlt.withValues(alpha: .24), p.cardAlt.withValues(alpha: .96)],
                        stops: const [.38, .66, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: p.glass, borderRadius: BorderRadius.circular(999)),
                        child: Text(e.category, style: dpV3Sans(10.5, p, weight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        decoration: BoxDecoration(color: p.glass, borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          children: [
                            Icon(Icons.star_rounded, size: 12, color: p.gold),
                            const SizedBox(width: 4),
                            Text(e.rating, style: dpV3Sans(11, p, weight: FontWeight.w800, color: p.gold)),
                          ],
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: dpV3Sans(15, p, weight: FontWeight.w800))),
                          if (e.verified) ...[
                            const SizedBox(width: 6),
                            Container(width: 16, height: 16, decoration: BoxDecoration(color: p.goldFill, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, size: 10, color: Color(0xFF1A1408))),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(e.role, maxLines: 1, overflow: TextOverflow.ellipsis, style: dpV3Sans(12, p, color: p.inkSoft)),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: p.glass, borderRadius: BorderRadius.circular(999), border: Border.all(color: p.line)),
                              child: Text('View', style: dpV3Sans(12, p, weight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: p.glass, shape: BoxShape.circle, border: Border.all(color: p.line)),
                            child: Icon(Icons.bookmark_border_rounded, size: 15, color: p.ink),
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
      ),
    );
  }
}

class _FinancialCommandCentre extends StatelessWidget {
  final DirectorDashboard dashboard;
  const _FinancialCommandCentre({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final summary = dashboard.summary;
    final payments = dashboard.dpPayments;
    final verified = payments.where((e) => e.status == 'Verified').length;
    final review = payments.where((e) => e.status == 'Proof Uploaded').length;
    final due = payments
        .where((e) => e.status == 'Due' || e.status == 'Rejected')
        .toList();
    final total = summary.paidMinor + summary.pendingPaymentMinor;
    final progress = total == 0 ? 0.0 : summary.paidMinor / total;

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: p.line),
        boxShadow: p.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _FinancialWashPainter(p)),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: _FloatingBubbleLayer(specs: _financeBubbleSpecs),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Financial Command Centre',
                        style: dpV3Sans(17, p, weight: FontWeight.w800),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          DirectorProducerRoutes.payments,
                        ),
                        child: Text(
                          'View payments',
                          style: dpV3Sans(
                            13.5,
                            p,
                            weight: FontWeight.w700,
                            color: p.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 760;
                      final ledger = _LedgerSummary(
                        paidMinor: summary.paidMinor,
                        totalMinor: total,
                        currency: summary.currency,
                        progress: progress,
                        verified: verified,
                        review: review,
                        due: due.length,
                      );
                      final dueList = _DueList(payments: due);
                      return stacked
                          ? Column(
                              children: [
                                ledger,
                                const SizedBox(height: 18),
                                dueList,
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 9, child: ledger),
                                const SizedBox(width: 22),
                                Expanded(flex: 11, child: dueList),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: p.lineSoft),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Deals & Contracts Pipeline',
                        style: dpV3Sans(13, p, weight: FontWeight.w800),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          DirectorProducerRoutes.bargaining,
                        ),
                        child: Text(
                          'View all',
                          style: dpV3Sans(
                            13,
                            p,
                            weight: FontWeight.w700,
                            color: p.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _PipelineFlow(items: dashboard.pipeline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialWashPainter extends CustomPainter {
  final DPV3Palette p;
  _FinancialWashPainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    void wash(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawRect(rect, paint);
    }

    wash(
      Offset(size.width, 0),
      size.width * .56,
      p.ice.withValues(alpha: p.dark ? .09 : .30),
    );
    wash(
      Offset(0, size.height),
      size.width * .52,
      p.lavender.withValues(alpha: p.dark ? .09 : .27),
    );
    wash(
      Offset(size.width * .62, size.height),
      size.width * .42,
      p.mint.withValues(alpha: p.dark ? .07 : .22),
    );
    wash(
      Offset(size.width * .30, 0),
      size.width * .36,
      p.goldTint.withValues(alpha: p.dark ? .08 : .36),
    );
  }

  @override
  bool shouldRepaint(covariant _FinancialWashPainter oldDelegate) =>
      oldDelegate.p.dark != p.dark;
}

class _LedgerSummary extends StatelessWidget {
  final int paidMinor;
  final int totalMinor;
  final String currency;
  final double progress;
  final int verified;
  final int review;
  final int due;

  const _LedgerSummary({
    required this.paidMinor,
    required this.totalMinor,
    required this.currency,
    required this.progress,
    required this.verified,
    required this.review,
    required this.due,
  });

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Verified ledger', style: dpV3Sans(11.5, p, color: p.muted)),
            const Spacer(),
            Container(width: 7, height: 7, decoration: BoxDecoration(color: p.mint, shape: BoxShape.circle, boxShadow: [BoxShadow(color: p.mint.withValues(alpha: .45), blurRadius: 8)])),
            const SizedBox(width: 6),
            Text('On track', style: dpV3Sans(11, p, weight: FontWeight.w800, color: p.gold)),
          ],
        ),
        const SizedBox(height: 10),
        Text(_moneyMinor(paidMinor, currency), style: dpV3Serif(30, p, weight: FontWeight.w500, fontStyle: FontStyle.italic, letterSpacing: -1)),
        const SizedBox(height: 6),
        Text('${(progress * 100).round()}% paid · ${_moneyMinor(totalMinor, currency)} total', style: dpV3Sans(11.5, p, color: p.muted)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 5,
            value: progress.clamp(.02, 1.0).toDouble(),
            backgroundColor: p.goldSoft,
            valueColor: AlwaysStoppedAnimation(p.mint),
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            _FinanceLegend(label: '$verified verified', color: p.mint),
            _FinanceLegend(label: '$review review', color: p.ice),
            _FinanceLegend(label: '$due due', color: p.peach),
          ],
        ),
      ],
    );
  }
}

class _FinanceLegend extends StatelessWidget {
  final String label;
  final Color color;
  const _FinanceLegend({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: .35), blurRadius: 8)])),
        const SizedBox(width: 7),
        Text(label, style: dpV3Sans(11, p, weight: FontWeight.w700, color: p.inkSoft)),
      ],
    );
  }
}

class _DueList extends StatelessWidget {
  final List<DpPayment> payments;
  const _DueList({required this.payments});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    if (payments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: p.positive, size: 18),
            const SizedBox(width: 8),
            Text('No payments due right now.', style: dpV3Sans(12.5, p, color: p.muted)),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final payment in payments.take(3))
          InkWell(
            onTap: () => Navigator.pushNamed(context, DirectorProducerRoutes.payments),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: p.lineSoft))),
              child: Row(
                children: [
                  _AnimatedHoloBadge(text: _initials(payment.stakeholder)),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(payment.stakeholder, maxLines: 1, overflow: TextOverflow.ellipsis, style: dpV3Sans(12.5, p, weight: FontWeight.w700))),
                            const SizedBox(width: 8),
                            Text('● ${payment.status} ${payment.dueDate}', style: dpV3Sans(10, p, weight: FontWeight.w800, color: p.gold)),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text('${payment.booking} · PKR ${_compactInt(payment.amount)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: dpV3Sans(11, p, color: p.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _GlassAction(label: 'Upload Proof', icon: Icons.upload_rounded, onTap: () => Navigator.pushNamed(context, DirectorProducerRoutes.payments), compact: true),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PipelineFlow extends StatelessWidget {
  final List<DirectorPipelineItem> items;
  const _PipelineFlow({required this.items});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final bookings = items.where((e) => e.kind == 'booking').toList();
    final contracts = items.where((e) => e.kind == 'contract').toList();
    final stages = [
      _PipelineStage(
        'Negotiating',
        bookings
            .where((e) =>
                ['sent', 'under_negotiation'].contains(e.status.toLowerCase()))
            .toList(),
        p.goldLight,
      ),
      _PipelineStage(
        'Offer accepted',
        bookings
            .where((e) => ['accepted', 'confirmed', 'secured']
                .contains(e.status.toLowerCase()))
            .toList(),
        p.ice,
      ),
      _PipelineStage(
        'Contract sent',
        contracts
            .where((e) => e.status.toLowerCase().contains('pending'))
            .toList(),
        p.lavender,
      ),
      _PipelineStage(
        'Due now',
        items.where((e) => e.status.toLowerCase().contains('due')).toList(),
        p.peach,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          const gap = 12.0;
          final width = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: 14,
            children: [
              for (final stage in stages)
                SizedBox(
                  width: width,
                  child: _PipelineStageCard(stage: stage),
                ),
            ],
          );
        }

        return SizedBox(
          height: 84,
          child: Stack(
            children: [
              Positioned(
                left: constraints.maxWidth * .125,
                right: constraints.maxWidth * .125,
                top: 15,
                child: _PipelineTrack(p: p),
              ),
              Row(
                children: [
                  for (final stage in stages)
                    Expanded(child: _PipelineStageCard(stage: stage)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PipelineTrack extends StatelessWidget {
  final DPV3Palette p;
  const _PipelineTrack({required this.p});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 4,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [p.goldLight, p.ice, p.lavender, p.peach],
                ),
              ),
            ),
          ),
          _FlowDot(color: p.goldFill, glow: p.goldLight),
        ],
      ),
    );
  }
}

class _FlowDot extends StatefulWidget {
  final Color color;
  final Color glow;
  const _FlowDot({required this.color, required this.glow});

  @override
  State<_FlowDot> createState() => _FlowDotState();
}

class _FlowDotState extends State<_FlowDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_controller.value);
            final opacity = _controller.value < .10
                ? _controller.value / .10
                : _controller.value > .90
                    ? (1 - _controller.value) / .10
                    : 1.0;
            return Transform.translate(
              offset: Offset(
                (constraints.maxWidth - 10) * t,
                0,
              ),
              child: Opacity(opacity: opacity.clamp(0.0, 1.0).toDouble(), child: child),
            );
          },
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: widget.glow,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: .8),
                    blurRadius: 12,
                    spreadRadius: 2,
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

class _PipelineStage {
  final String label;
  final List<DirectorPipelineItem> items;
  final Color color;
  const _PipelineStage(this.label, this.items, this.color);
}

class _PipelineStageCard extends StatelessWidget {
  final _PipelineStage stage;
  const _PipelineStageCard({required this.stage});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    final totalMinor = stage.items.fold<int>(
      0,
      (sum, item) => sum + (item.valueMinor ?? 0),
    );
    final currency = stage.items.isEmpty ? 'PKR' : stage.items.first.currency;

    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        DirectorProducerRoutes.bargaining,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.card,
              border: Border.all(color: stage.color, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: p.card,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: stage.color.withValues(alpha: .38),
                  blurRadius: 14,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Text(
              '${stage.items.length}',
              style: dpV3Sans(12.5, p, weight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stage.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: dpV3Sans(11.5, p, weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            _moneyMinor(totalMinor, currency),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: dpV3Sans(10.5, p, color: p.muted),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  final Duration period;

  const _PulsingDot({
    required this.color,
    required this.size,
    required this.period,
  });

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
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
        final wave =
            (1 - math.cos(_controller.value * math.pi * 2)) / 2;
        return Opacity(opacity: _lerp(1, .2, wave), child: child);
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _AnimatedHoloBadge extends StatefulWidget {
  final String text;
  const _AnimatedHoloBadge({required this.text});

  @override
  State<_AnimatedHoloBadge> createState() => _AnimatedHoloBadgeState();
}

class _AnimatedHoloBadgeState extends State<_AnimatedHoloBadge>
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
    final p = DPV3Palette.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final wave =
            (1 - math.cos(_controller.value * math.pi * 2)) / 2;
        final shift = _lerp(-.5, .5, wave);
        return Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.2 + shift, -1),
              end: Alignment(.8 + shift, 1),
              colors: p.dark
                  ? const [
                      Color(0x1AFFFFFF),
                      Color(0x218CBFFF),
                      Color(0x1CFF96DC),
                      Color(0x26FFD778),
                      Color(0x14FFFFFF),
                    ]
                  : const [
                      Color(0xCCFFFFFF),
                      Color(0x99D2EAFF),
                      Color(0x8CFFDDF6),
                      Color(0xB3FFF2CC),
                      Color(0xCCFFFFFF),
                    ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.holoBorder),
          ),
          child: Text(
            widget.text,
            style: dpV3Sans(
              10.5,
              p,
              weight: FontWeight.w800,
              color: p.gold,
            ),
          ),
        );
      },
    );
  }
}

class _SheenSweep extends StatefulWidget {
  final Duration delay;
  const _SheenSweep({this.delay = Duration.zero});

  @override
  State<_SheenSweep> createState() => _SheenSweepState();
}

class _SheenSweepState extends State<_SheenSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    const duration = Duration(seconds: 7);
    final phase =
        (widget.delay.inMilliseconds % duration.inMilliseconds) /
            duration.inMilliseconds;
    _controller = AnimationController(
      vsync: this,
      duration: duration,
      value: phase,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final x = t <= .60
              ? _lerp(-constraints.maxWidth * .46,
                  constraints.maxWidth * 1.02, Curves.easeInOut.transform(t / .60))
              : constraints.maxWidth * 1.02;
          return Transform.translate(offset: Offset(x, 0), child: child);
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: Transform.rotate(
            angle: -18 * math.pi / 180,
            child: Container(
              width: constraints.maxWidth * .38,
              height: constraints.maxHeight * 1.40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: .12),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RiseIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const _RiseIn({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<_RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<_RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _timer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
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
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: Transform.scale(
              scale: .99 + .01 * t,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _SurfaceCard({required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: p.line),
        boxShadow: p.softShadow,
      ),
      child: child,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? dot;

  const _FilterChip({required this.label, required this.active, required this.onTap, this.dot});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? p.goldSoft : p.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? p.goldFill : p.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            Text(label, style: dpV3Sans(12.5, p, weight: FontWeight.w700, color: active ? p.ink : p.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool filled;

  const _PillButton({required this.label, required this.onTap, this.active = false, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? p.goldFill : active ? p.goldSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: active && !filled ? null : Border.all(color: filled ? p.goldFill : p.line),
        ),
        child: Text(label, style: dpV3Sans(12, p, weight: FontWeight.w700, color: filled ? const Color(0xFF1A1408) : active ? p.gold : p.inkSoft)),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.line)),
        child: Icon(icon, size: 18, color: p.inkSoft),
      ),
    );
  }
}

class _GoldAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GoldAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(color: p.goldFill, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: dpV3Sans(12.5, p, weight: FontWeight.w800, color: const Color(0xFF1A1408))),
            const SizedBox(width: 6),
            Icon(icon, size: 15, color: const Color(0xFF1A1408)),
          ],
        ),
      ),
    );
  }
}

class _GlassAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;
  const _GlassAction({required this.label, required this.icon, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: compact ? 28 : 34,
        padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 14),
        decoration: BoxDecoration(color: p.glass, borderRadius: BorderRadius.circular(999), border: Border.all(color: p.glassLine)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 14 : 15, color: p.ink),
            const SizedBox(width: 6),
            Text(label, style: dpV3Sans(compact ? 11.5 : 12.5, p, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _AutoMarquee extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final double gap;
  final bool reverse;

  const _AutoMarquee({required this.children, required this.duration, required this.gap, this.reverse = false});

  @override
  State<_AutoMarquee> createState() => _AutoMarqueeState();
}

class _AutoMarqueeState extends State<_AutoMarquee> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void didUpdateWidget(covariant _AutoMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final direction = widget.reverse ? 1.0 : -1.0;
            final offset = direction * _controller.value * math.max(600.0, constraints.maxWidth);
            return Transform.translate(
              offset: Offset(offset, 0),
              child: OverflowBox(
                alignment: widget.reverse ? Alignment.centerRight : Alignment.centerLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._withGaps(widget.children),
                    SizedBox(width: widget.gap * 2),
                    ..._withGaps(widget.children),
                    SizedBox(width: widget.gap * 2),
                    ..._withGaps(widget.children),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _withGaps(List<Widget> children) {
    return [
      for (var i = 0; i < children.length; i++) ...[
        children[i],
        if (i != children.length - 1) SizedBox(width: widget.gap),
      ],
    ];
  }
}

class _PlanItem {
  final String id;
  final String title;
  final String meta;
  final String type;
  final DateTime startsAt;

  const _PlanItem({required this.id, required this.title, required this.meta, required this.type, required this.startsAt});

  factory _PlanItem.fromTimeline(DirectorTimelineItem item) {
    return _PlanItem(
      id: item.publicId,
      title: item.title,
      meta: [item.projectTitle, item.subtitle].where((e) => e.trim().isNotEmpty).join(' · '),
      type: _inferType(item.title, item.subtitle),
      startsAt: item.startsAt ?? DateTime.now(),
    );
  }
}

String _inferType(String title, String subtitle) {
  final text = '$title $subtitle'.toLowerCase();
  if (text.contains('shoot')) return 'Shoot';
  if (text.contains('recce') || text.contains('location')) return 'Recce';
  if (text.contains('cast') || text.contains('audition')) return 'Casting';
  if (text.contains('payment') || text.contains('advance') || text.contains('due')) return 'Payment';
  return 'Meeting';
}

Color _planColor(DPV3Palette p, String type) {
  return switch (type) {
    'Shoot' => p.goldFill,
    'Recce' => p.info,
    'Casting' => p.violet,
    'Meeting' => p.positive,
    'Payment' => p.negative,
    _ => p.gold,
  };
}

LinearGradient _posterGradient(DPV3Palette p, int index, String seed) {
  const light = [
    [Color(0xFFF6DFC2), Color(0xFFF2E8D8), Color(0xFFE1D5BF)],
    [Color(0xFFCCE6F5), Color(0xFFE6EDF1), Color(0xFFC9D5DC)],
    [Color(0xFFF2D4E5), Color(0xFFEDE6EC), Color(0xFFD6CCD9)],
    [Color(0xFFCDE8DE), Color(0xFFE7EEE9), Color(0xFFCCD9D1)],
    [Color(0xFFE7DDF7), Color(0xFFEDEAF2), Color(0xFFD6D0E0)],
  ];
  const dark = [
    [Color(0xFF5C4424), Color(0xFF211A11), Color(0xFF0D0B09)],
    [Color(0xFF22536D), Color(0xFF17242B), Color(0xFF0A0C0D)],
    [Color(0xFF60304C), Color(0xFF281820), Color(0xFF0B090A)],
    [Color(0xFF23513C), Color(0xFF15231D), Color(0xFF090B0A)],
    [Color(0xFF443B69), Color(0xFF211D2C), Color(0xFF0A090C)],
  ];
  final set = p.dark ? dark : light;
  final h = seed.codeUnits.fold<int>(index, (a, b) => a + b);
  return LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: set[h.abs() % set.length]);
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'P';
  if (parts.length == 1) {
    final end = parts.first.length < 2 ? parts.first.length : 2;
    return parts.first.substring(0, end).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _moneyMinor(int minor, String currency) {
  final value = minor / 100;
  if (value.abs() >= 1000000) return '$currency ${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
  if (value.abs() >= 1000) return '$currency ${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  return '$currency ${NumberFormat('#,##0').format(value)}';
}

String _compactInt(int value) {
  if (value.abs() >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  return NumberFormat('#,##0').format(value);
}

String _relative(DateTime? value) {
  if (value == null) return '';
  final diff = DateTime.now().difference(value);
  if (diff.inDays >= 1) return '${diff.inDays}d';
  if (diff.inHours >= 1) return '${diff.inHours}h';
  return '${math.max(1, diff.inMinutes)}m';
}
