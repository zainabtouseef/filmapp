import 'package:flutter/material.dart';

import '../widgets/cine_marketplace_card.dart';

/// A big number + label pair for the hero's prominent metrics row
/// ("42 · Productions", "Now · Available") — matching the Flow Reel's
/// profile metrics, which are large figures, not small pill chips.
class EntityMetricBlock extends StatelessWidget {
  final String value;
  final String label;

  const EntityMetricBlock(
      {super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = CineMarketplaceVisuals.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: palette.archivo(
            size: 26,
            weight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: palette.archivo(
            size: 11,
            color: palette.muted,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
