import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../cards/cine_card_system.dart';

/// Dashboard-kit quick-action stat tile: icon circle, a big gold number,
/// a label, a colored delta line, and a thin gold underline glow at the
/// bottom edge.
///
/// Distinct from `cine_card_system.dart`'s `QuickActionCard` (an icon +
/// heading + description "action prompt" card) — this is the design's
/// numeric stat tile (e.g. "12 · Applications · +4 today").
class PortalQuickStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String delta;
  final CineTone tone;
  final VoidCallback? onTap;

  const PortalQuickStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.delta,
    this.tone = CineTone.premium,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = cineToneColor(context, tone);
    return CardShell(
      radius: AppRadius.panel,
      tone: tone,
      onTap: onTap,
      minHeight: 150,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconBadge(icon: icon, tone: tone),
              const SizedBox(height: AppSpacing.md),
              Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colors.goldMid,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMeta
                    .copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                delta,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMeta.copyWith(
                  color: toneColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: 0.6,
                child: Container(
                  height: 3,
                  decoration: AppTheme.goldEdgeAccent(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
