import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/cine_card_system.dart';

/// Dashboard-kit metric card built around the existing [ProgressRing] —
/// a small donut ring on the left, value + delta + label on the right.
class PortalRingMetricCard extends StatelessWidget {
  final double progress;
  final String value;
  final String? delta;
  final String label;
  final CineTone tone;

  const PortalRingMetricCard({
    super.key,
    required this.progress,
    required this.value,
    required this.label,
    this.delta,
    this.tone = CineTone.premium,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CardShell(
      radius: AppRadius.panel,
      density: CardDensity.compact,
      child: Row(
        children: [
          ProgressRing(value: progress, tone: tone, size: 64),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: AppTextStyles.metricNumberCompact
                          .copyWith(color: colors.textPrimary, fontSize: 22),
                    ),
                    if (delta != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        delta!,
                        style: AppTextStyles.smallMeta.copyWith(
                          color: colors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
