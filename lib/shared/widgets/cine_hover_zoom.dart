import 'package:flutter/material.dart';

import '../../core/theme/app_durations.dart';

/// Shared restrained zoom for premium portal heroes and feature surfaces.
///
/// It changes only paint scale, so responsive geometry stays stable. Motion
/// is disabled when the platform's reduced-motion setting is active.
class CineHoverZoom extends StatefulWidget {
  final Widget child;
  final double scale;
  final double pressedScale;

  const CineHoverZoom({
    super.key,
    required this.child,
    this.scale = 1.008,
    this.pressedScale = 1.018,
  });

  @override
  State<CineHoverZoom> createState() => _CineHoverZoomState();
}

class _CineHoverZoomState extends State<CineHoverZoom> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final scale = reduceMotion
        ? 1.0
        : _pressed
            ? widget.pressedScale
            : _hovered
                ? widget.scale
                : 1.0;
    return Listener(
      onPointerDown: (_) {
        if (!_pressed) setState(() => _pressed = true);
      },
      onPointerUp: (_) {
        if (_pressed) setState(() => _pressed = false);
      },
      onPointerCancel: (_) {
        if (_pressed) setState(() => _pressed = false);
      },
      child: MouseRegion(
        onEnter: (_) {
          if (!_hovered) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (_hovered || _pressed) {
            setState(() {
              _hovered = false;
              _pressed = false;
            });
          }
        },
        child: AnimatedScale(
          scale: scale,
          duration: reduceMotion ? Duration.zero : AppDurations.cardLift,
          curve: AppDurations.standardCurve,
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
