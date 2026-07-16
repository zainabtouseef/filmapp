import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dp_negotiation.dart';
import 'dp_status_chip.dart';

class DPNegotiationRoundCard extends StatelessWidget {
  final DpNegotiationRound round;
  final bool showDivider;

  const DPNegotiationRoundCard({
    super.key,
    required this.round,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DPStatusChip(label: 'Round ${round.round}', tone: DpTone.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  round.sentBy,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                round.timestamp,
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${round.rate} - ${round.dates}',
            style: AppTextStyles.cardLabel.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${round.schedule}\n${round.conditions}\n${round.message}',
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
