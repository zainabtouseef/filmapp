import 'package:flutter/material.dart';

import '../../core/theme/app_durations.dart';

/// Shared restrained zoom for premium portal heroes and feature surfaces.
///
/// It changes only paint scale, so responsive geometry stays stable. Motion
/// is disabled when the platform's reduced-motion setting is active.
class CineHoverZoom extends StatefulWidget {
  final Widget child;
  final double scale;

  const CineHoverZoom({
    super.key,
    required this.child,
    this.scale = 1.004,
  });

  @override
  State<CineHoverZoom> createState() => _CineHoverZoomState();
}

class _CineHoverZoomState extends State<CineHoverZoom> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return MouseRegion(
      onEnter: (_) {
        if (!_hovered) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: AnimatedScale(
        scale: _hovered && !reduceMotion ? widget.scale : 1,
        duration: reduceMotion ? Duration.zero : AppDurations.cardLift,
        curve: AppDurations.standardCurve,
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}
