import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';

/// Legacy-compatible surface container backed by the current theme tokens.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 18,
    this.width,
    this.height,
    this.padding = EdgeInsets.zero,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1,
    this.shadows,
    this.blur = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? colors.elevatedSurface : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? colors.border,
          width: borderWidth,
        ),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}
