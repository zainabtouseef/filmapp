import 'package:flutter/material.dart';

import '../../../shared/cards/glass_section_card.dart';

class DPGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;

  const DPGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSectionCard(
      padding: padding,
      selected: selected,
      child: child,
    );
  }
}
