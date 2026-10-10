import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';

/// Decorative mouse-only trail; native click/text cursors retain their meaning.
/// Touch, keyboard, reduced motion and pointer exits use the native fallback.
class CinematicCursor extends StatefulWidget {
  final Widget child;

  const CinematicCursor({super.key, required this.child});

  @override
  State<CinematicCursor> createState() => _CinematicCursorState();
}

class _CinematicCursorState extends State<CinematicCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  Offset _from = Offset.zero;
  Offset _target = Offset.zero;
  bool _visible = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
  }

  Offset get _position =>
      Offset.lerp(_from, _target, Curves.easeOut.transform(_motion.value))!;

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _motion.stop();
      return widget.child;
    }
    final gold = context.appColors.goldMid;
    return MouseRegion(
      // Defer preserves native text selection, resize and clickable cursors.
      cursor: MouseCursor.defer,
      onHover: (event) {
        if (event.kind != PointerDeviceKind.mouse) return;
        _from = _visible ? _position : event.localPosition;
        _target = event.localPosition;
        if (!_visible) setState(() => _visible = true);
        _motion.forward(from: 0);
      },
      onExit: (_) {
        _motion.stop();
        setState(() => _visible = false);
      },
      child: Listener(
        onPointerDown: (event) {
          if (event.kind == PointerDeviceKind.mouse) {
            setState(() => _pressed = true);
          }
        },
        onPointerUp: (_) {
          if (_pressed) setState(() => _pressed = false);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (_visible)
              IgnorePointer(
                child: ExcludeSemantics(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _motion,
                      builder: (context, _) {
                        final position = _position;
                        final diameter = _pressed ? 20.0 : 30.0;
                        return Stack(children: [
                          Positioned(
                            left: position.dx - diameter / 2,
                            top: position.dy - diameter / 2,
                            child: Container(
                              key: const ValueKey('cinematic-cursor-ring'),
                              width: diameter,
                              height: diameter,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: gold.withValues(alpha: 0.7)),
                                boxShadow: [
                                  BoxShadow(
                                      color: gold.withValues(alpha: 0.14),
                                      blurRadius: 12)
                                ],
                              ),
                            ),
                          ),
                        ]);
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
