import 'dart:math' as math;

import 'package:flutter/material.dart';

class QueueRadarPainter extends CustomPainter {
  final Color green;
  final Color purple;
  final Color gold;
  final Color lineColor;

  const QueueRadarPainter({
    required this.green,
    required this.purple,
    required this.gold,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.96, size.height * 0.52);
    final maxRadius = math.min(size.width * 0.9, size.height * 0.56);
    final rects = [
      Rect.fromCircle(center: center, radius: maxRadius),
      Rect.fromCircle(center: center, radius: maxRadius * 0.72),
      Rect.fromCircle(center: center, radius: maxRadius * 0.45),
    ];
    final start = math.pi * 0.5;
    final sweep = math.pi;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6
      ..color = lineColor;

    for (final rect in rects) {
      canvas.drawArc(rect, start, sweep, false, basePaint);
    }

    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;

    accentPaint
      ..color = green.withValues(alpha: 0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(
      rects[1],
      math.pi * 1.28,
      math.pi * 0.22,
      false,
      accentPaint,
    );

    accentPaint.color = purple.withValues(alpha: 0.38);
    canvas.drawArc(
      rects[1],
      math.pi * 0.68,
      math.pi * 0.36,
      false,
      accentPaint,
    );

    accentPaint.color = gold.withValues(alpha: 0.26);
    canvas.drawArc(
      rects[0],
      math.pi * 0.38,
      math.pi * 0.18,
      false,
      accentPaint,
    );

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.44)
      ..strokeWidth = 1.1;
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx, center.dy),
      linePaint..color = lineColor.withValues(alpha: 0.28),
    );

    void node(Color color, double radius, double angle) {
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final glow = Paint()
        ..color = color.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawCircle(point, 8, glow);
      canvas.drawCircle(
        point,
        4.5,
        Paint()..color = color.withValues(alpha: 0.82),
      );
    }

    node(green, maxRadius * 0.72, math.pi * 1.5);
    node(purple, maxRadius * 0.72, math.pi);
    node(gold, maxRadius, math.pi * 0.5);
    canvas.drawCircle(
      center,
      5,
      Paint()..color = lineColor.withValues(alpha: 0.32),
    );
  }

  @override
  bool shouldRepaint(covariant QueueRadarPainter oldDelegate) {
    return oldDelegate.green != green ||
        oldDelegate.purple != purple ||
        oldDelegate.gold != gold ||
        oldDelegate.lineColor != lineColor;
  }
}
