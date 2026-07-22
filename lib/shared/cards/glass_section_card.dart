import 'package:flutter/material.dart';

import 'cine_card_system.dart';

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
    return CardShell(
      variant: CardVariant.standard,
      density: CardDensity.standard,
      radius: radius,
      padding: padding,
      selected: selected,
      tone: CineTone.premium,
      child: child,
    );
  }
}
