import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/cine_card_system.dart';

/// Dashboard-kit "modules" grid card: left color-accent bar, icon chip,
/// name + optional numeric count badge, a 2-line clamped description, and
/// a trailing action link.
class PortalModuleCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final int? count;
  final String description;
  final String actionLabel;
  final CineTone tone;
  final VoidCallback? onTap;

  const PortalModuleCard({
    super.key,
    required this.icon,
    required this.name,
    required this.description,
    required this.actionLabel,
    this.count,
    this.tone = CineTone.premium,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = cineToneColor(context, tone);
    return CardShell(
      radius: AppRadius.panel,
      density: CardDensity.compact,
      tone: tone,
      accentEdge: true,
      onTap: onTap,
      minHeight: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, tone: tone, compact: true),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle
                      .copyWith(fontSize: 13.5, color: colors.textPrimary),
                ),
              ),
              if (count != null) CountBadge(count: count!, tone: tone),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionLabel,
                style: AppTextStyles.smallMeta.copyWith(
                  color: toneColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 14, color: toneColor),
            ],
          ),
        ],
      ),
    );
  }
}
