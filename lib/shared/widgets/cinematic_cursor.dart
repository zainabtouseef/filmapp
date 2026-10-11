import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_durations.dart';

/// Shared lightning pointer for web plus a touch ripple on mobile.
///
/// The overlay is paint-only and ignores hit testing, so it cannot change page
/// geometry or block controls. Reduced-motion users keep the platform default.
class CinematicCursor extends StatefulWidget {
  final Widget child;

  const CinematicCursor({super.key, required this.child});

  @override
  State<CinematicCursor> createState() => _CinematicCursorState();
}

class _CinematicCursorState extends State<CinematicCursor>
    with TickerProviderStateMixin {
  static const _trailCount = 4;

  late final Ticker _ticker;
  late final AnimationController _fade;
  final List<Offset> _trail = List.filled(_trailCount, Offset.zero);
  Duration? _lastTick;
  Offset _position = Offset.zero;
  Offset _target = Offset.zero;
  PointerDeviceKind _kind = PointerDeviceKind.mouse;
  bool _visible = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _fade = AnimationController(
      vsync: this,
      duration: AppDurations.pointerFade,
      value: 1,
    )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed && mounted) {
          _stopTicker();
          setState(() => _visible = false);
        }
      });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _startTicker() {
    if (_ticker.isActive) return;
    _lastTick = null;
    _ticker.start();
  }

  void _stopTicker() {
    if (_ticker.isActive) _ticker.stop();
    _lastTick = null;
  }

  void _tick(Duration elapsed) {
    if (!_visible) {
      _stopTicker();
      return;
    }
    final previous = _lastTick;
    _lastTick = elapsed;
    final seconds = previous == null
        ? 1 / 60
        : ((elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond)
            .clamp(1 / 240, 1 / 20)
            .toDouble();

    // The lightning head tracks the latest browser position once per frame.
    // Pointer events only update [_target], so event bursts never restart an
    // animation or trigger more rebuilds than the display refresh rate.
    _position = _target;
    var leader = _position;
    var settled = true;
    for (var i = 0; i < _trail.length; i++) {
      final response = 30.0 - i * 3.5;
      final amount = 1 - math.exp(-response * seconds);
      final next = Offset.lerp(_trail[i], leader, amount)!;
      if ((next - leader).distance > 0.18) settled = false;
      _trail[i] = next;
      leader = next;
    }

    if (mounted) setState(() {});
    if (settled && (_position - _target).distance <= 0.01) _stopTicker();
  }

  void _moveTo(Offset position, PointerDeviceKind kind) {
    final kindChanged = _kind != kind;
    _kind = kind;
    _target = position;
    _fade.value = 1;
    if (!_visible) {
      _position = position;
      for (var i = 0; i < _trail.length; i++) {
        _trail[i] = position;
      }
      setState(() => _visible = true);
    } else if (kindChanged) {
      setState(() {});
    }
    _startTicker();
  }

  void _press(PointerEvent event) {
    if (event.kind != PointerDeviceKind.mouse &&
        event.kind != PointerDeviceKind.touch &&
        event.kind != PointerDeviceKind.stylus) {
      return;
    }
    _moveTo(event.localPosition, event.kind);
    if (!_pressed) setState(() => _pressed = true);
  }

  void _release(PointerEvent event) {
    if (_pressed) setState(() => _pressed = false);
    if (event.kind == PointerDeviceKind.mouse) return;
    _fade.reverse(from: 1);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _stopTicker();
      _fade.stop();
      return widget.child;
    }
    final colors = context.appColors;
    return MouseRegion(
      cursor: SystemMouseCursors.none,
      onEnter: (event) {
        if (event.kind == PointerDeviceKind.mouse) {
          _moveTo(event.localPosition, event.kind);
        }
      },
      onHover: (event) {
        if (event.kind == PointerDeviceKind.mouse) {
          _moveTo(event.localPosition, event.kind);
        }
      },
      onExit: (_) {
        _stopTicker();
        if (_visible && _kind == PointerDeviceKind.mouse) {
          setState(() {
            _visible = false;
            _pressed = false;
          });
        }
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _press,
        onPointerMove: (event) {
          if (event.kind != PointerDeviceKind.mouse) {
            _moveTo(event.localPosition, event.kind);
          }
        },
        onPointerUp: _release,
        onPointerCancel: _release,
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (_visible)
              IgnorePointer(
                child: ExcludeSemantics(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _fade,
                      builder: (context, _) {
                        final opacity = _kind == PointerDeviceKind.mouse
                            ? 1.0
                            : _fade.value;
                        return Opacity(
                          opacity: opacity,
                          child: Stack(
                            children: [
                              for (var i = 1; i <= 4; i++)
                                _TrailBubble(
                                  index: i,
                                  position: _trail[i - 1],
                                  color: colors.goldMid,
                                ),
                              _LightningPointer(
                                position: _position,
                                color: colors.goldMid,
                                pressed: _pressed,
                                touch: _kind != PointerDeviceKind.mouse,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LightningPointer extends StatelessWidget {
  final Offset position;
  final Color color;
  final bool pressed;
  final bool touch;

  const _LightningPointer({
    required this.position,
    required this.color,
    required this.pressed,
    required this.touch,
  });

  @override
  Widget build(BuildContext context) {
    final diameter = touch ? (pressed ? 44.0 : 34.0) : (pressed ? 22.0 : 30.0);
    return Positioned(
      left: position.dx - diameter / 2,
      top: position.dy - diameter / 2,
      child: AnimatedContainer(
        key: const ValueKey('cinematic-cursor-ring'),
        duration: AppDurations.press,
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: touch ? 0.26 : 0.18),
              color.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.74)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: touch ? 20 : 14,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.bolt_rounded,
            key: const ValueKey('cinematic-cursor-lightning'),
            size: touch ? 20 : 16,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _TrailBubble extends StatelessWidget {
  final int index;
  final Offset position;
  final Color color;

  const _TrailBubble({
    required this.index,
    required this.position,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final size = 10.0 - index * 1.45;
    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      child: Container(
        key: ValueKey('cinematic-cursor-trail-$index'),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.34 / index),
          border: Border.all(color: color.withValues(alpha: 0.5 / index)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22 / index),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}
