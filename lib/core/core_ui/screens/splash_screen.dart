import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../core_routes.dart';

const _ivory = Color(0xFFFAF6EE);
const _ivoryDeep = Color(0xFFF3ECDD);
const _inkBlack = Color(0xFF17140F);
const _metallicGold = Color(0xFFB8862E);
const _goldBright = Color(0xFFE9C77B);
const _goldSoft = Color(0xFFD9B36B);
const _subtitleGrey = Color(0xFF6B655A);

const _totalDuration = Duration(milliseconds: 3400);

// Phase boundaries as fractions of the compact splash timeline.
const double _p1End = 0.26; // light sweep + icons emerge
const double _p2End = 0.55; // network formation + glimpses
const double _p3End = 0.78; // convergence into the lens
// Final phase: wordmark reveal + hold

class _IconSpec {
  final IconData icon;
  final double angle; // radial position around the ring
  final double stagger; // 0-1 emergence stagger within phase 1
  final _Glimpse glimpse;

  const _IconSpec({
    required this.icon,
    required this.angle,
    required this.stagger,
    required this.glimpse,
  });
}

enum _Glimpse {
  focusPulse,
  clapClose,
  pageTurn,
  micPulse,
  beamBright,
  framePop,
  groupFade
}

final _iconSpecs = <_IconSpec>[
  _IconSpec(
      icon: Icons.videocam_outlined,
      angle: -math.pi / 2,
      stagger: 0.00,
      glimpse: _Glimpse.focusPulse),
  _IconSpec(
      icon: Icons.movie_creation_outlined,
      angle: -math.pi / 2 + 2 * math.pi / 7,
      stagger: 0.12,
      glimpse: _Glimpse.clapClose),
  _IconSpec(
      icon: Icons.description_outlined,
      angle: -math.pi / 2 + 4 * math.pi / 7,
      stagger: 0.24,
      glimpse: _Glimpse.pageTurn),
  _IconSpec(
      icon: Icons.mic_none_outlined,
      angle: -math.pi / 2 + 6 * math.pi / 7,
      stagger: 0.36,
      glimpse: _Glimpse.micPulse),
  _IconSpec(
      icon: Icons.wb_incandescent_outlined,
      angle: -math.pi / 2 + 8 * math.pi / 7,
      stagger: 0.48,
      glimpse: _Glimpse.beamBright),
  _IconSpec(
      icon: Icons.location_on_outlined,
      angle: -math.pi / 2 + 10 * math.pi / 7,
      stagger: 0.60,
      glimpse: _Glimpse.framePop),
  _IconSpec(
      icon: Icons.groups_outlined,
      angle: -math.pi / 2 + 12 * math.pi / 7,
      stagger: 0.72,
      glimpse: _Glimpse.groupFade),
];

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _exitController;
  late final List<Offset> _dust;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration)
      ..forward();
    // A short fade the splash plays itself out with right before the route
    // change, so the handoff to the next screen reads as one continuous
    // motion instead of the animation finishing and then a separate,
    // unrelated page transition cutting in.
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _dust = List.generate(26, (i) {
      final r = math.Random(i * 97 + 11);
      return Offset(r.nextDouble(), r.nextDouble());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareAndRoute());
  }

  Future<void> _prepareAndRoute() async {
    final animationDone = _controller.forward().orCancel.catchError((_) {});
    final auth = AuthScope.maybeOf(context);
    if (auth == null) {
      if (!_skipped) await animationDone;
      await _exitAndRoute(
          forceUpdateRequired: false, maintenanceEnabled: false);
      return;
    }
    var forceUpdateRequired = false;
    var maintenanceEnabled = false;
    try {
      final bootstrap = await auth.bootstrap().timeout(
            const Duration(milliseconds: 1600),
          );
      final data = bootstrap['data'] as Map<String, dynamic>;
      final forceUpdate = data['force_update'] as Map<String, dynamic>;
      final maintenance = data['maintenance'] as Map<String, dynamic>;
      forceUpdateRequired = forceUpdate['required'] as bool? ?? false;
      maintenanceEnabled = maintenance['enabled'] as bool? ?? false;
    } catch (_) {
      // Offline routing still lets a stored session continue to its portal.
    }
    if (!_skipped) await animationDone;
    await _exitAndRoute(
      forceUpdateRequired: forceUpdateRequired,
      maintenanceEnabled: maintenanceEnabled,
    );
  }

  Future<void> _exitAndRoute({
    required bool forceUpdateRequired,
    required bool maintenanceEnabled,
  }) async {
    if (!mounted) return;
    await _exitController.forward().orCancel.catchError((_) {});
    _routeNext(
      forceUpdateRequired: forceUpdateRequired,
      maintenanceEnabled: maintenanceEnabled,
    );
  }

  void _routeNext({
    required bool forceUpdateRequired,
    required bool maintenanceEnabled,
  }) {
    if (!mounted) return;
    final auth = AuthScope.maybeOf(context);
    final route = forceUpdateRequired
        ? CoreRoutes.forceUpdate
        : maintenanceEnabled
            ? CoreRoutes.maintenance
            : auth?.isAuthenticated == true
                ? auth!.initialAuthenticatedRoute
                : CoreRoutes.login;
    Navigator.pushReplacementNamed(context, route);
  }

  void _skip() {
    if (_skipped) return;
    _skipped = true;
    _controller.animateTo(1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    _exitController.dispose();
    super.dispose();
  }

  double _phase(double start, double end, double t,
      {Curve curve = Curves.easeInOut}) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return curve.transform((t - start) / (end - start));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ivory,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(
            CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return SizedBox.expand(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _background(t),
                    _shaderWarmup(),
                    _lightSweep(t),
                    RepaintBoundary(child: _dustField(t)),
                    RepaintBoundary(child: _iconNetwork(t)),
                    _lensEmblem(t),
                    _wordmark(t),
                    if (t < 0.94) _skipHint(t),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Warm ivory base with a very soft champagne vignette.
  Widget _background(double t) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.1),
          radius: 1.2,
          colors: [_ivory, _ivoryDeep],
        ),
      ),
    );
  }

  // Pre-compiles the SweepGradient/RadialGradient/ShaderMask shaders the
  // lens ring and wordmark shimmer need, on the very first frame — at a
  // barely-visible but non-zero opacity so Flutter doesn't skip the paint
  // altogether (it elides painting for exactly `Opacity(opacity: 0)`).
  // Without this, the GPU compiles those shaders the first time they're
  // actually needed mid-timeline, which reads as the animation stalling
  // for a beat right as the ring/wordmark are about to appear.
  Widget _shaderWarmup() {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.003,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      _metallicGold,
                      _goldBright,
                      _metallicGold,
                      _goldSoft,
                      _metallicGold,
                    ],
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      RadialGradient(colors: [_goldBright, Colors.transparent]),
                ),
              ),
              ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white,
                    Colors.transparent,
                  ],
                ).createShader(bounds),
                child: const Text('W', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 0-3s: a thin gold beam sweeps left to right, carrying dust with it.
  Widget _lightSweep(double t) {
    final p = _phase(0, _p1End, t, curve: Curves.easeInOutCubic);
    if (p <= 0 || p >= 1) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, c) {
        final dx = -c.maxWidth * 0.3 + c.maxWidth * 1.6 * p;
        final edgeFade = (1 - (p - 0.5).abs() * 2).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Opacity(
            opacity: 0.55 * edgeFade + 0.15,
            child: Transform.rotate(
              angle: -0.12,
              child: Container(
                width: c.maxWidth * 0.22,
                height: c.maxHeight * 1.6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      _goldBright.withValues(alpha: 0.55),
                      Colors.transparent,
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

  // Fine cinematic dust, visible mainly through phase 1-2.
  Widget _dustField(double t) {
    final visibility = 1 - _phase(_p2End, _p3End, t);
    if (visibility <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _DustPainter(dust: _dust, t: t, opacity: visibility),
      ),
    );
  }

  // 3-7s (and fading through 7-11s): icons + connecting network lines.
  Widget _iconNetwork(double t) {
    final overallFade =
        1 - _phase(_p3End - 0.03, _p3End, t, curve: Curves.easeIn);
    if (overallFade <= 0) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, c) {
        final size = math.min(c.maxWidth, c.maxHeight);
        final scatterR = size * 0.46;
        final networkR = size * 0.27;
        final convergeR = size * 0.09;

        final positions = <Offset>[];
        final opacities = <double>[];
        final scales = <double>[];

        for (final spec in _iconSpecs) {
          final emerge = _phase(_p1End * spec.stagger,
              math.min(_p1End, _p1End * spec.stagger + 0.09), t);
          final toNetwork =
              _phase(_p1End, _p2End, t, curve: Curves.easeInOutCubic);
          final toCenter = _phase(_p2End, _p3End, t, curve: Curves.easeInCubic);

          final r = uiLerp(
              uiLerp(scatterR, networkR, toNetwork), convergeR, toCenter);
          final angle = spec.angle;
          final pos = Offset(math.cos(angle) * r, math.sin(angle) * r);
          positions.add(pos);

          final fadeOutNearCenter = 1 -
              _phase(_p2End + (_p3End - _p2End) * 0.55, _p3End, t,
                  curve: Curves.easeIn);
          opacities.add(emerge * fadeOutNearCenter);

          var scale = 0.8 + emerge * 0.2;
          final glimpseWindow = _phase(
            _p2End - (7 / 15 - 3 / 15) * 0.42 + spec.stagger * 0.05,
            _p2End - (7 / 15 - 3 / 15) * 0.12 + spec.stagger * 0.05,
            t,
          );
          final glimpsePulse = math.sin(glimpseWindow * math.pi);
          switch (spec.glimpse) {
            case _Glimpse.focusPulse:
              scale += glimpsePulse * 0.22;
            case _Glimpse.micPulse:
              scale += glimpsePulse * 0.16;
            case _Glimpse.framePop:
              scale += glimpsePulse * 0.2;
            default:
              scale += glimpsePulse * 0.1;
          }
          scales.add(scale * (1 - toCenter * 0.35));
        }

        final linesOpacity =
            _phase(_p1End, _p1End + (_p2End - _p1End) * 0.5, t) *
                (1 - _phase(_p2End, _p3End, t, curve: Curves.easeIn));

        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(c.maxWidth, c.maxHeight),
              painter: _NetworkLinesPainter(
                center: Offset(c.maxWidth / 2, c.maxHeight / 2),
                positions: positions,
                opacity: linesOpacity * overallFade,
              ),
            ),
            for (var i = 0; i < _iconSpecs.length; i++)
              if (opacities[i] > 0)
                Builder(builder: (context) {
                  // Alpha is baked directly into each layer's own color
                  // rather than wrapped in an `Opacity` widget — the icon,
                  // fill, and border don't overlap each other, so this
                  // produces an identical fade without the extra
                  // compositing layer `Opacity` would force per icon
                  // (×7 icons × every frame otherwise).
                  final iconFade = (opacities[i] * overallFade).clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: positions[i],
                    child: Transform.scale(
                      scale: scales[i],
                      child: Transform.rotate(
                        angle: _iconSpecs[i].glimpse == _Glimpse.clapClose
                            ? -0.18 *
                                math
                                    .sin(_glimpseFor(t, _iconSpecs[i].stagger) *
                                        math.pi)
                                    .clamp(0.0, 1.0)
                            : 0,
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _ivory.withValues(alpha: 0.6 * iconFade),
                            border: Border.all(
                                color:
                                    _goldSoft.withValues(alpha: 0.7 * iconFade),
                                width: 1),
                          ),
                          child: Icon(_iconSpecs[i].icon,
                              color: _metallicGold.withValues(alpha: iconFade),
                              size: 22),
                        ),
                      ),
                    ),
                  );
                }),
          ],
        );
      },
    );
  }

  double _glimpseFor(double t, double stagger) {
    return _phase(
      _p2End - (_p2End - _p1End) * 0.42 + stagger * 0.05,
      _p2End - (_p2End - _p1End) * 0.12 + stagger * 0.05,
      t,
    );
  }

  // 7-11s: icons converge into a rotating lens ring, flares, then opens.
  Widget _lensEmblem(double t) {
    final ringIn = _phase(
        _p2End + (_p3End - _p2End) * 0.15, _p2End + (_p3End - _p2End) * 0.55, t,
        curve: Curves.easeOutBack);
    final ringVisible = _phase(_p2End, _p3End - (_p3End - _p2End) * 0.12, t) *
        (1 -
            _phase(_p3End - (_p3End - _p2End) * 0.1, _p3End, t,
                curve: Curves.easeIn));
    if (ringIn <= 0 && ringVisible <= 0) return const SizedBox.shrink();

    final rotate =
        _phase(_p2End + (_p3End - _p2End) * 0.4, _p3End, t) * math.pi * 0.9;
    final flare = math.sin(_phase(_p3End - (_p3End - _p2End) * 0.32,
            _p3End - (_p3End - _p2End) * 0.08, t) *
        math.pi);
    final aperture = _phase(_p3End - (_p3End - _p2End) * 0.16, _p3End, t,
        curve: Curves.easeInCubic);

    return LayoutBuilder(
      builder: (context, c) {
        final base = math.min(c.maxWidth, c.maxHeight) * 0.16;
        final diameter = base * ringIn * (1 + aperture * 2.4);
        return Center(
          child: Opacity(
            opacity: (ringVisible + aperture).clamp(0.0, 1.0) * (1 - aperture),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (flare > 0.05)
                  Opacity(
                    opacity: flare * 0.6,
                    child: Container(
                      width: diameter * 2.2,
                      height: diameter * 2.2,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [_goldBright, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                Transform.rotate(
                  angle: rotate,
                  child: Container(
                    width: diameter,
                    height: diameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          _metallicGold,
                          _goldBright,
                          _metallicGold,
                          _goldSoft,
                          _metallicGold
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: const DecoratedBox(
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: _ivory),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 11-15s: the wordmark, subtitle, one shimmer sweep, then a static hold.
  Widget _wordmark(double t) {
    final reveal = _phase(_p3End, _p3End + (1 - _p3End) * 0.28, t,
        curve: Curves.easeOutCubic);
    if (reveal <= 0) return const SizedBox.shrink();

    final shimmer = _phase(
      _p3End + (1 - _p3End) * 0.4,
      _p3End + (1 - _p3End) * 0.7,
      t,
      curve: Curves.easeInOut,
    );

    return Center(
      child: Opacity(
        opacity: reveal,
        child: Transform.scale(
          scale: 0.92 + reveal * 0.08,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (bounds) {
                  final band = 0.22;
                  final pos = -band + (1 + band * 2) * shimmer;
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [
                      Colors.transparent,
                      Colors.white,
                      Colors.transparent
                    ],
                    stops: [
                      (pos - band).clamp(0.0, 1.0),
                      pos.clamp(0.0, 1.0),
                      (pos + band).clamp(0.0, 1.0),
                    ],
                  ).createShader(bounds);
                },
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6),
                    children: [
                      TextSpan(
                          text: 'CINE', style: TextStyle(color: _inkBlack)),
                      TextSpan(
                          text: 'CONNECT',
                          style: TextStyle(color: _metallicGold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'CAST.  CONNECT.  CREATE.',
                style: TextStyle(
                  color: _subtitleGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skipHint(double t) {
    final show = _phase(0.35, 0.45, t);
    if (show <= 0) return const SizedBox.shrink();
    return Positioned(
      bottom: 28,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: show * 0.55,
        child: const Text(
          'Tap to skip',
          textAlign: TextAlign.center,
          style:
              TextStyle(color: _subtitleGrey, fontSize: 12, letterSpacing: 2),
        ),
      ),
    );
  }
}

double uiLerp(double a, double b, double t) => a + (b - a) * t;

class _DustPainter extends CustomPainter {
  final List<Offset> dust;
  final double t;
  final double opacity;

  _DustPainter({required this.dust, required this.t, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final paint = Paint()..color = _goldSoft.withValues(alpha: 0.5 * opacity);
    for (var i = 0; i < dust.length; i++) {
      final seed = dust[i];
      final drift = (t * (0.15 + seed.dy * 0.2)) % 1.0;
      final dx = (seed.dx * size.width + math.sin((t + seed.dy) * 6) * 10) %
          size.width;
      final dy = ((seed.dy + drift) * size.height) % size.height;
      final r = 1.2 + seed.dx * 1.6;
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) => true;
}

class _NetworkLinesPainter extends CustomPainter {
  final Offset center;
  final List<Offset> positions;
  final double opacity;

  _NetworkLinesPainter(
      {required this.center, required this.positions, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    // Always draws — even at alpha 0 — rather than early-returning while
    // invisible. Early-returning meant this surface only got rasterized
    // for the first time right as the lines actually needed to become
    // visible, which measured as a real ~200ms stall at that exact
    // moment; drawing (invisibly) from frame one keeps the surface warm.
    if (positions.length < 2) return;
    final paint = Paint()
      ..color = _metallicGold.withValues(alpha: 0.35 * opacity.clamp(0.0, 1.0))
      ..strokeWidth = 1;
    for (var i = 0; i < positions.length; i++) {
      final a = center + positions[i];
      final b = center + positions[(i + 1) % positions.length];
      canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkLinesPainter oldDelegate) => true;
}
