import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'portal_glass_widget_card.dart';

/// A purely decorative, continuously-animating flame/ember glow — fills
/// dead space in a widget grid with warm motion rather than an empty
/// gap. No data is implied by this widget; it's motion, not a metric.
class PortalGlassFireWidget extends StatefulWidget {
  final double? width;
  final double? height;

  const PortalGlassFireWidget({super.key, this.width, this.height});

  @override
  State<PortalGlassFireWidget> createState() => _PortalGlassFireWidgetState();
}

class _PortalGlassFireWidgetState extends State<PortalGlassFireWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
    final reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (!reduceMotion) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PortalGlassWidgetCard(
      width: widget.width,
      height: widget.height,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _FlamePainter(t: _controller.value),
          ),
        ),
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  final double t;

  const _FlamePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseline = h * 0.94;
    final cx = w / 2;

    void flame({
      required double widthFactor,
      required double heightFactor,
      required List<Color> colors,
      required double phase,
      required double speed,
      required double blur,
    }) {
      final wobble = math.sin(t * 2 * math.pi * speed + phase) * w * 0.05;
      final lift = (math.sin(t * 2 * math.pi * speed * 1.3 + phase) + 1) / 2;
      final flameHeight = h * heightFactor * (0.85 + lift * 0.15);
      final flameWidth = w * widthFactor;
      final tipX = cx + wobble;
      final tipY = baseline - flameHeight;

      final path = Path()
        ..moveTo(cx - flameWidth / 2, baseline)
        ..quadraticBezierTo(
          cx - flameWidth * 0.6,
          baseline - flameHeight * 0.45,
          tipX,
          tipY,
        )
        ..quadraticBezierTo(
          cx + flameWidth * 0.6,
          baseline - flameHeight * 0.45,
          cx + flameWidth / 2,
          baseline,
        )
        ..close();

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: colors,
        ).createShader(
            Rect.fromLTWH(cx - flameWidth / 2, tipY, flameWidth, flameHeight))
        ..maskFilter =
            blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null;
      canvas.drawPath(path, paint);
    }

    // Outer soft glow, deepest red-orange, widest wobble.
    flame(
      widthFactor: 0.62,
      heightFactor: 0.62,
      colors: const [
        Color(0xFFB4451A),
        Color(0xFFE07A2E),
        Color(0x00E07A2E),
      ],
      phase: 0,
      speed: 0.32,
      blur: 10,
    );
    // Middle flame, gold.
    flame(
      widthFactor: 0.42,
      heightFactor: 0.48,
      colors: const [
        Color(0xFFD98A1E),
        Color(0xFFF0BD59),
        Color(0x00F0BD59),
      ],
      phase: 1.4,
      speed: 0.4,
      blur: 5,
    );
    // Inner core, bright and tight.
    flame(
      widthFactor: 0.2,
      heightFactor: 0.3,
      colors: const [
        Color(0xFFF4C76A),
        Color(0xFFFFF3D0),
        Color(0x00FFF3D0),
      ],
      phase: 2.6,
      speed: 0.55,
      blur: 2,
    );

    // Embers.
    final emberPaint = Paint()..color = const Color(0xFFF0BD59);
    for (var i = 0; i < 5; i++) {
      final seed = i * 1.7;
      final ex =
          cx + math.sin(t * 2 * math.pi * (0.25 + i * 0.07) + seed) * w * 0.28;
      final riseT = (t * (0.6 + i * 0.1) + i * 0.2) % 1.0;
      final ey = baseline - riseT * h * 0.75;
      final opacity = (1 - riseT).clamp(0.0, 1.0) * 0.8;
      canvas.drawCircle(
        Offset(ex, ey),
        1.6 - riseT,
        emberPaint..color = const Color(0xFFF0BD59).withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) => oldDelegate.t != t;
}
