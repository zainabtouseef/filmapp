import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_durations.dart';

/// A thin gold light that continuously traces a rounded surface.
///
/// Hero surfaces use this single implementation so dashboards, marketplaces,
/// and operational pages share the same motion and theme colors. The light
/// becomes a static gold accent when the device requests reduced motion.
class CineAnimatedGoldBorder extends StatefulWidget {
  final Widget child;
  final double radius;
  final double strokeWidth;

  const CineAnimatedGoldBorder({
    super.key,
    required this.child,
    required this.radius,
    this.strokeWidth = 1.5,
  });

  @override
  State<CineAnimatedGoldBorder> createState() => _CineAnimatedGoldBorderState();
}

class _CineAnimatedGoldBorderState extends State<CineAnimatedGoldBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.heroRingRotation,
  );
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ??
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0;
    } else {
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _CineGoldRingPainter(
                    angle: _controller.value * 2 * math.pi,
                    goldDark: colors.goldDark,
                    goldMid: colors.goldMid,
                    goldLight: colors.goldLight,
                    isLight: colors.isLight,
                    radius: widget.radius,
                    strokeWidth: widget.strokeWidth,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CineGoldRingPainter extends CustomPainter {
  final double angle;
  final Color goldDark;
  final Color goldMid;
  final Color goldLight;
  final bool isLight;
  final double radius;
  final double strokeWidth;

  const _CineGoldRingPainter({
    required this.angle,
    required this.goldDark,
    required this.goldMid,
    required this.goldLight,
    required this.isLight,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = strokeWidth / 2 + .25;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(inset),
      Radius.circular((radius - inset).clamp(0, radius)),
    );
    final peak = isLight ? 1.0 : .56;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          goldDark.withValues(alpha: .05),
          goldMid.withValues(alpha: .10),
          goldMid.withValues(alpha: .20),
          goldMid.withValues(alpha: .72 * peak),
          goldLight.withValues(alpha: .82 * peak),
          const Color(0xFFFFF4BA).withValues(alpha: peak),
          goldLight.withValues(alpha: .82 * peak),
          goldMid.withValues(alpha: .72 * peak),
          goldMid.withValues(alpha: .20),
          goldDark.withValues(alpha: .05),
        ],
        stops: const [0, .43, .57, .67, .72, .76, .80, .85, .93, 1],
        transform: GradientRotation(angle),
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _CineGoldRingPainter oldDelegate) =>
      oldDelegate.angle != angle ||
      oldDelegate.goldDark != goldDark ||
      oldDelegate.goldMid != goldMid ||
      oldDelegate.goldLight != goldLight ||
      oldDelegate.isLight != isLight ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}
