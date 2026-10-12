import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import 'portal_reference_design.dart';

/// Shared visual canvas for every operational portal body.
///
/// The shell, page hero and navigation stay owned by their existing widgets.
/// This layer supplies a consistent cinematic depth field behind the live
/// screen content and a restrained moving gold trace at the content edge.
class PortalBodyCanvas extends StatefulWidget {
  final String? route;
  final Widget child;

  const PortalBodyCanvas({
    super.key,
    required this.route,
    required this.child,
  });

  @override
  State<PortalBodyCanvas> createState() => _PortalBodyCanvasState();
}

class _PortalBodyCanvasState extends State<PortalBodyCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!PortalReferenceDesign.usesReference(widget.route)) {
      return widget.child;
    }
    final colors = context.appColors;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final layout = PortalReferenceDesign.layoutForRoute(widget.route);
    final secondary = switch (layout) {
      PortalBodyLayout.analytics => colors.infoBlue,
      PortalBodyLayout.timeline => colors.infoPurple,
      PortalBodyLayout.calendar => colors.success,
      PortalBodyLayout.editorial => colors.goldMid,
      PortalBodyLayout.list => colors.infoBlue,
      PortalBodyLayout.kanban => colors.infoPurple,
      PortalBodyLayout.gallery => colors.holographicTeal,
      PortalBodyLayout.splitView => colors.goldMid,
      PortalBodyLayout.horizontalRail => colors.holographicCyan,
    };

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(.78, -.88),
                    radius: 1.2,
                    colors: [
                      secondary.withValues(alpha: colors.isLight ? .045 : .025),
                      colors.goldMid.withValues(
                        alpha: colors.isLight ? .018 : .012,
                      ),
                      Colors.transparent,
                    ],
                    stops: const [0, .35, 1],
                  ),
                ),
              ),
            ),
          ),
          widget.child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 2,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final progress = reduceMotion ? .5 : _controller.value;
                  return CustomPaint(
                    painter: _BodyTracePainter(
                      progress: progress,
                      gold: colors.goldMid,
                      secondary: secondary,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyTracePainter extends CustomPainter {
  final double progress;
  final Color gold;
  final Color secondary;

  const _BodyTracePainter({
    required this.progress,
    required this.gold,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    final center = size.width * progress;
    final span = (size.width * .24).clamp(100.0, 340.0);
    final rect = Rect.fromLTWH(center - span, 0, span * 2, 2);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          secondary.withValues(alpha: .16),
          gold.withValues(alpha: .9),
          secondary.withValues(alpha: .16),
          Colors.transparent,
        ],
        stops: const [0, .28, .5, .72, 1],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _BodyTracePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.gold != gold ||
      oldDelegate.secondary != secondary;
}
