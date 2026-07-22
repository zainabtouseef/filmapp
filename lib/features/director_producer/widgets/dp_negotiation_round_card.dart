import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dp_negotiation.dart';
import 'dp_glass_card.dart';

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
    final terms = [
      round.schedule,
      round.conditions,
      round.message,
    ].where((term) => term.trim().isNotEmpty).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: showDivider ? 10 : 0),
      child: Column(
        children: [
          DPGlassCard(
            accentColor: colors.goldDark,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.goldDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Round ${round.round} — ${round.sentBy}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: colors.goldDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      round.timestamp,
                      style: AppTextStyles.caption
                          .copyWith(color: colors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${round.rate} · ${round.dates}',
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                for (final term in terms) ...[
                  const SizedBox(height: 4),
                  Text(
                    term,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
