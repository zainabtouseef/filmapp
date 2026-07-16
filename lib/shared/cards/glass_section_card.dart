import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../widgets/glass_card.dart';

class GlassSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final double radius;

  const GlassSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.selected = false,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassContainer(
      radius: radius,
      padding: padding,
      borderColor: selected ? colors.goldMid : colors.border,
      shadows: [
        BoxShadow(
          color: colors.shadow.withValues(alpha: colors.isLight ? 0.12 : 0.38),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ],
      child: child,
    );
  }
}
