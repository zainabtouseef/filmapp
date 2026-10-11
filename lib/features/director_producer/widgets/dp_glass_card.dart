import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/layout/portal_reference_design.dart';
import '../../../shared/widgets/cine_hover_zoom.dart';

class DPGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final Color? accentColor;
  final bool showAccent;
  final VoidCallback? onTap;

  const DPGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.selected = false,
    this.accentColor,
    this.showAccent = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final resolvedAccent = accentColor ?? colors.goldDark;
    final card = CardShell(
      variant: CardVariant.standard,
      density: CardDensity.standard,
      radius: 26,
      padding: EdgeInsets.zero,
      selected: selected,
      tone: cineToneFromColor(context, resolvedAccent),
      onTap: onTap,
      child: Stack(
        children: [
          if (showAccent)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: resolvedAccent),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
    return PortalReferenceDesign.usesReference(
      ModalRoute.of(context)?.settings.name,
    )
        ? card
        : CineHoverZoom(child: card);
  }
}
