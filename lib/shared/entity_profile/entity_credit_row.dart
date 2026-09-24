import 'package:flutter/material.dart';

import '../widgets/cine_marketplace_card.dart';

/// A "Credits" / "Projects shot here" list row: title/subtitle on the
/// left, a trailing value (year, amount) on the right, divider below —
/// matching the Flow Reel's credits list exactly.
class EntityCreditRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const EntityCreditRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CineMarketplaceVisuals.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: palette.border))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: palette.archivo(
                      size: 14,
                      weight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: palette.archivo(size: 11.5, color: palette.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              trailing,
              style: palette.archivo(
                size: 12.5,
                color: palette.muted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
