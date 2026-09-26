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
        speed: 0.6 + rand.nextDouble() * 0.7,
        dx: 8 + rand.nextDouble() * 16,
        dy: 14 + rand.nextDouble() * 22,
      );
    });
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Stack(
              children: [
                for (final spec in _specs)
                  _buildBubble(
                    spec,
                    w,
                    h,
                    colors,
                    reduceMotion ? 0 : _controller.value,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBubble(
    _BubbleSpec spec,
    double w,
    double h,
    CineThemeColors colors,
    double t,
  ) {
    final cycle = (t * spec.speed + spec.phase) % 1.0;
    final wave = math.sin(cycle * 2 * math.pi);
    final offsetX = wave * spec.dx;
    final offsetY = math.cos(cycle * 2 * math.pi) * spec.dy * 0.6 - spec.dy;
    return Positioned(
      left: spec.left * w + offsetX - spec.size / 2,
      top: spec.top * h + offsetY - spec.size / 2,
      child: Container(
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
              color: colors.goldMid
                  .withValues(alpha: colors.isLight ? 0.18 : 0.22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
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
