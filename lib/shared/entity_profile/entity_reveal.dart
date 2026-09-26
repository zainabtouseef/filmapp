import 'package:flutter/material.dart';

/// Cascading entrance reveal for entity-profile content — a direct port of
/// the Flow Reel's `st(delay, length)` stagger helper: every section below
/// the hero (tabs, metrics, work tiles, the sticky CTA bar…) fades up on
/// its own clock, each starting a fixed step after the last, all sharing
/// one smooth ease so the profile settles in as a single continuous
/// cascade rather than popping in all at once.
class EntityReveal extends StatelessWidget {
  final Widget child;

  /// How many stagger steps after the hero this section starts (0 = right
  /// after the hero settles).
  final int step;
  final double offsetY;

  static const Duration _stepGap = Duration(milliseconds: 90);
  static const Duration _duration = Duration(milliseconds: 520);

  const EntityReveal({
    super.key,
    required this.child,
    required this.step,
    this.offsetY = 22,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return child;
    final delayMs = _stepGap.inMilliseconds * step;
    final totalMs = delayMs + _duration.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(delayMs / totalMs, 1.0, curve: Curves.easeOutCubic),
      builder: (context, value, animatedChild) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * offsetY),
          child: animatedChild,
        ),
      ),
      child: child,
    );
  }
}
