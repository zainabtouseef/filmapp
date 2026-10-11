import 'package:flutter/material.dart';

import 'cine_card_system.dart';
import '../layout/portal_reference_design.dart';
import '../widgets/cine_hover_zoom.dart';

class GlassSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final double radius;
  final CineTone tone;
  final bool accentEdge;

  const GlassSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.selected = false,
    this.radius = 26,
    this.tone = CineTone.premium,
    this.accentEdge = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = CardShell(
      // Portal section wrappers pass `accentEdge: false`. Treat those as one
      // calm workspace section while nested records keep the compact card
      // treatment. This removes the old card-inside-card appearance without
      // changing any screen data or interactions.
      variant: accentEdge ? CardVariant.standard : CardVariant.section,
      density: CardDensity.standard,
      radius: radius,
      padding: padding,
      selected: selected,
      tone: tone,
      accentEdge: accentEdge,
      child: child,
    );
    return PortalReferenceDesign.usesReference(
      ModalRoute.of(context)?.settings.name,
    )
        ? card
        : CineHoverZoom(child: card);
  }
}
