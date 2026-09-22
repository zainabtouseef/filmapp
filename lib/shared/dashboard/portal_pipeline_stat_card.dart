import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/cine_card_system.dart';

/// Dashboard-kit "pipeline strip" stat card: left color-accent bar, a
/// small label, a big value, and a sub-text line.
class PortalPipelineStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final CineTone tone;
  final VoidCallback? onTap;

  const PortalPipelineStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    this.tone = CineTone.premium,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CardShell(
      radius: AppRadius.panel,
      density: CardDensity.compact,
      tone: tone,
      accentEdge: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardTitle
                .copyWith(fontSize: 19, color: colors.textPrimary),
          ),
          const SizedBox(height: 3),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta
                .copyWith(color: colors.textTertiary, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
