import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';

/// A frosted-glass "widget" surface — matching macOS's Notification
/// Center widgets (Clock, Calendar, Stocks): a blurred, translucent card
/// at a fixed, compact size rather than a card that stretches to fill
/// whatever space it's given.
class PortalGlassWidgetCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  const PortalGlassWidgetCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final borderColor = colors.isLight
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.10);
    final fillTop = colors.card.withValues(alpha: colors.isLight ? 0.62 : 0.42);
    final fillBottom =
        colors.card.withValues(alpha: colors.isLight ? 0.40 : 0.22);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [fillTop, fillBottom],
            ),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: colors.shadow
                    .withValues(alpha: colors.isLight ? 0.12 : 0.4),
                blurRadius: 30,
                offset: const Offset(0, 16),
                spreadRadius: -12,
              ),
              BoxShadow(
                color:
                    Colors.white.withValues(alpha: colors.isLight ? 0 : 0.05),
                blurRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
