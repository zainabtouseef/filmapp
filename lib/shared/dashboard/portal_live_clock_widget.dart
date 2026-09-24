import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import 'portal_glass_widget_card.dart';

/// A live analog clock widget — matching macOS's Clock widget: a glass
/// face with smoothly sweeping hands, always showing the real current
/// time. The lone genuinely continuous-motion piece in the dashboard
/// widget grid.
class PortalLiveClockWidget extends StatefulWidget {
  final double size;

  const PortalLiveClockWidget({super.key, this.size = 168});

  @override
  State<PortalLiveClockWidget> createState() => _PortalLiveClockWidgetState();
}

class _PortalLiveClockWidgetState extends State<PortalLiveClockWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    _ticker =
        AnimationController(vsync: this, duration: const Duration(seconds: 60));
    final reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      // Still show the correct static time, just no continuous sweep.
      _ticker.value = 0;
    } else {
      _ticker.repeat();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PortalGlassWidgetCard(
      width: widget.size,
      height: widget.size,
      padding: EdgeInsets.zero,
      child: AnimatedBuilder(
        animation: _ticker,
        builder: (context, _) {
          final now = DateTime.now();
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _ClockFacePainter(
                  now: now,
                  ink: colors.textPrimary,
                  muted: colors.textTertiary,
                  gold: colors.goldMid,
                ),
              ),
              Positioned(
                bottom: widget.size * 0.16,
                child: Text(
                  _weekdayLabel(now.weekday),
                  style: AppTextStyles.micro.copyWith(
                    color: colors.textSecondary,
                    fontSize: 9,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _weekdayLabel(int weekday) => const [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ][weekday - 1];

class _ClockFacePainter extends CustomPainter {
  final DateTime now;
  final Color ink;
  final Color muted;
  final Color gold;

  const _ClockFacePainter({
    required this.now,
    required this.ink,
    required this.muted,
    required this.gold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 14;

    // Tick marks.
    for (var i = 0; i < 60; i++) {
      final angle = i * 6 * math.pi / 180;
      final isHour = i % 5 == 0;
      final outer = center + Offset(math.sin(angle), -math.cos(angle)) * radius;
      final inner = center +
          Offset(math.sin(angle), -math.cos(angle)) *
              (radius - (isHour ? 10 : 5));
      final tickPaint = Paint()
        ..color =
            isHour ? ink.withValues(alpha: 0.7) : muted.withValues(alpha: 0.35)
        ..strokeWidth = isHour ? 2.2 : 1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(inner, outer, tickPaint);
    }

    final hours = now.hour % 12 + now.minute / 60;
    final minutes = now.minute + now.second / 60;
    final seconds = now.second + now.millisecond / 1000;

    void drawHand(double turns, double length, double width, Color color) {
      final angle = turns * 2 * math.pi;
      final end = center + Offset(math.sin(angle), -math.cos(angle)) * length;
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    drawHand(hours / 12, radius * 0.5, 4.2, ink);
    drawHand(minutes / 60, radius * 0.74, 3, ink);
    drawHand(seconds / 60, radius * 0.82, 1.4, gold);

    canvas.drawCircle(center, 4.2, Paint()..color = gold);
    canvas.drawCircle(
      center,
      4.2,
      Paint()
        ..color = ink.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _ClockFacePainter oldDelegate) =>
      oldDelegate.now != now;
}
