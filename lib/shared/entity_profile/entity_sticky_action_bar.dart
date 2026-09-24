import 'package:flutter/material.dart';

import '../widgets/cine_marketplace_card.dart';

/// The Flow Reel's sticky bottom action bar: a gradient fade-in
/// background, an outlined secondary action, and a gold-gradient
/// primary action — e.g. "Shortlist" + "Start Talking". Drop this
/// straight into a `Scaffold.bottomNavigationBar` (or `persistentFooterButtons`
/// container) so it stays pinned while the rest of the profile scrolls.
class EntityStickyActionBar extends StatelessWidget {
  final String secondaryLabel;
  final IconData secondaryIcon;
  final VoidCallback? onSecondary;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? onPrimary;

  const EntityStickyActionBar({
    super.key,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.primaryLabel,
    required this.primaryIcon,
    this.onSecondary,
    this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CineMarketplaceVisuals.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.background.withValues(alpha: 0),
            palette.background.withValues(alpha: 0.92),
            palette.background,
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSecondary,
                  icon: Icon(secondaryIcon, size: 18, color: palette.gold),
                  label: Text(secondaryLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.gold,
                    side: BorderSide(color: palette.gold),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle:
                        palette.archivo(size: 14, weight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: palette.goldGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: FilledButton.icon(
                    onPressed: onPrimary,
                    icon: Icon(primaryIcon, size: 18, color: palette.onGold),
                    label: Text(primaryLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      foregroundColor: palette.onGold,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle:
                          palette.archivo(size: 14, weight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
