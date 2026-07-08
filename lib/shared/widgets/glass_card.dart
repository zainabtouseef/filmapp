import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';

/// The approved CineConnect glassmorphism container: backdrop blur +
/// theme-aware gradient fill + border + optional shadow.
///
/// Use this (not a hand-rolled `Container` + `BackdropFilter`) for any
/// new glass surface so the effect stays identical everywhere.
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
    this.borderWidth = 1.15,
    this.shadows,
    this.blur = 18,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient ?? colors.glassGradient,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? colors.border,
              width: borderWidth,
            ),
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );
  }
}
