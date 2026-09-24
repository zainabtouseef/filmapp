import 'package:flutter/material.dart';

import '../widgets/cine_marketplace_card.dart';

/// Gold, all-caps, letter-spaced section label — "KNOWN FOR", "CREDITS",
/// "PHOTOS" — exactly matching the CineConnect Flow Reel's `SectionLabel`.
class EntitySectionLabel extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const EntitySectionLabel({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final palette = CineMarketplaceVisuals.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette.archivo(
              size: 12,
              weight: FontWeight.w700,
              color: palette.gold,
              letterSpacing: 3,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
