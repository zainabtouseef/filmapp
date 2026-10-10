import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

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
  late final AnimationController _motion;
  late final AnimationController _fade;
  Offset _from = Offset.zero;
  Offset _target = Offset.zero;
  PointerDeviceKind _kind = PointerDeviceKind.mouse;
  bool _visible = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: AppDurations.pointerFollow,
    );
    _fade = AnimationController(
      vsync: this,
      duration: AppDurations.pointerFade,
      value: 1,
    )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed && mounted) {
          setState(() => _visible = false);
        }
      });
  }

  Offset get _position => Offset.lerp(
      _from, _target, Curves.easeOutCubic.transform(_motion.value))!;

  @override
  void dispose() {
    _motion.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _moveTo(Offset position, PointerDeviceKind kind) {
    _kind = kind;
    _from = _visible ? _position : position;
    _target = position;
    _fade.value = 1;
    if (!_visible) setState(() => _visible = true);
    _motion.forward(from: 0);
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
      _motion.stop();
      _fade.stop();
      return widget.child;
    }
    final colors = context.appColors;
    return MouseRegion(
      cursor: SystemMouseCursors.none,
      onHover: (event) {
        if (event.kind == PointerDeviceKind.mouse) {
          _moveTo(event.localPosition, event.kind);
        }
      },
      onExit: (_) {
        _motion.stop();
        if (_visible && _kind == PointerDeviceKind.mouse) {
          setState(() => _visible = false);
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
                      animation: Listenable.merge([_motion, _fade]),
                      builder: (context, _) {
                        final position = _position;
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
                                  position: Offset.lerp(
                                    position,
                                    _from,
                                    i * 0.16,
                                  )!,
                                  color: colors.goldMid,
                                ),
                              _LightningPointer(
                                position: position,
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
