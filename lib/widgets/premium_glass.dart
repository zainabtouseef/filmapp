import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PremiumGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final double borderWidth;
  final Gradient? borderGradient;
  final Gradient? fillGradient;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? shadows;
  final double blur;

  const PremiumGlass({
    super.key,
    required this.child,
    this.radius = 22,
    this.borderWidth = 1,
    this.borderGradient,
    this.fillGradient,
    this.padding,
    this.shadows,
    this.blur = 18,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = BorderRadius.circular(radius);
    final innerRadius = BorderRadius.circular(
      (radius - borderWidth).clamp(0, radius).toDouble(),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: borderGradient ??
                      const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.border, AppColors.borderMuted],
                      ),
                  borderRadius: effectiveRadius,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(borderWidth),
              child: ClipRRect(
                borderRadius: innerRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: innerRadius,
                      gradient: fillGradient ??
                          const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0x33162028),
                              Color(0x24101620),
                              Color(0x18101418),
                            ],
                          ),
                    ),
                    child: Padding(
                      padding: padding ?? EdgeInsets.zero,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: effectiveRadius,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x18FFFFFF), Colors.transparent],
                      stops: [0.0, 0.42],
                    ),
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

class GoldGlowShadow {
  GoldGlowShadow._();

  static const card = [
    BoxShadow(
      color: Color(0x33C88A1E),
      blurRadius: 30,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x99000000),
      blurRadius: 24,
      spreadRadius: -12,
      offset: Offset(0, 18),
    ),
  ];

  static const control = [
    BoxShadow(
      color: Color(0x22C88A1E),
      blurRadius: 18,
      spreadRadius: -8,
      offset: Offset(0, 8),
    ),
  ];
}
