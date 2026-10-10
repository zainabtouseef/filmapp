import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';

/// A handful of soft, translucent bubbles that drift slowly behind hero
/// and promo sections — purely decorative, no data. Matches the Portal
/// Dashboard v3 design's floating-bubble treatment.
class PortalFloatingBubbles extends StatefulWidget {
  final int count;

  const PortalFloatingBubbles({super.key, this.count = 6});

  @override
  State<PortalFloatingBubbles> createState() => _PortalFloatingBubblesState();
}

class _PortalFloatingBubblesState extends State<PortalFloatingBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_BubbleSpec> _specs;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 20));
    final reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (!reduceMotion) _controller.repeat();
    final rand = math.Random(widget.count * 17);
    _specs = List.generate(widget.count, (i) {
      return _BubbleSpec(
        left: rand.nextDouble(),
        top: rand.nextDouble(),
        size: 26.0 + rand.nextDouble() * 46,
        phase: rand.nextDouble(),
        // Whole cycles prevent a visible jump when the controller repeats.
        speed: i.isEven ? 1 : 2,
        dx: 8 + rand.nextDouble() * 16,
        dy: 14 + rand.nextDouble() * 22,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ??
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
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
    final colors = context.appColors;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return IgnorePointer(
      child: ExcludeSemantics(child: RepaintBoundary(child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          if (!w.isFinite || !h.isFinite) return const SizedBox.shrink();
          return ClipRect(
              child: Stack(
            children: [
              for (final spec in _specs)
                Positioned(
                  left: spec.left * w - spec.size / 2,
                  top: spec.top * h - spec.size / 2,
                  child: AnimatedBuilder(
                    animation: _controller,
                    child: _buildBubble(spec, colors),
                    builder: (context, child) {
                      final t = reduceMotion ? 0 : _controller.value;
                      final cycle = (t * spec.speed + spec.phase) * 2 * math.pi;
                      return Transform.translate(
                        offset: Offset(math.sin(cycle) * spec.dx,
                            math.cos(cycle) * spec.dy * 0.6 - spec.dy),
                        child: child,
                      );
                    },
                  ),
                ),
            ],
          ));
        },
      ))),
    );
  }

  Widget _buildBubble(
    _BubbleSpec spec,
    CineThemeColors colors,
  ) {
    return Container(
      width: spec.size,
      height: spec.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.isLight
              ? Colors.white.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.14),
        ),
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: colors.isLight
              ? [
                  Colors.white.withValues(alpha: 0.9),
                  colors.infoBlue.withValues(alpha: 0.14),
                  colors.goldLight.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.0),
                ]
              : [
                  Colors.white.withValues(alpha: 0.5),
                  colors.infoBlue.withValues(alpha: 0.18),
                  colors.goldMid.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.0),
                ],
          stops: const [0.0, 0.28, 0.58, 0.85],
        ),
        boxShadow: [
          BoxShadow(
            color:
                colors.goldMid.withValues(alpha: colors.isLight ? 0.18 : 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }
}

class _BubbleSpec {
  final double left;
  final double top;
  final double size;
  final double phase;
  final double speed;
  final double dx;
  final double dy;

  const _BubbleSpec({
    required this.left,
    required this.top,
    required this.size,
    required this.phase,
    required this.speed,
    required this.dx,
    required this.dy,
  });
}
