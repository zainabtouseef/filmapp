import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';

class DPBookingStatusSpine extends StatelessWidget {
  final int activeIndex;

  const DPBookingStatusSpine({
    super.key,
    required this.activeIndex,
  });

  static const statuses = [
    'Draft',
    'Sent',
    'Viewed',
    'Countered',
    'Accepted',
    'Contract',
    'Pending Sign',
    'Signed',
    'Deposit',
    'Proof',
    'Verified',
    'Scheduled',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < statuses.length; index++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: index <= activeIndex
                    ? colors.goldGlow.withValues(alpha: 0.14)
                    : colors.surface.withValues(alpha: 0.18),
                border: Border.all(
                  color: index <= activeIndex ? colors.goldMid : colors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= activeIndex
                          ? colors.goldMid
                          : colors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statuses[index],
                    style: AppTextStyles.smallMeta.copyWith(
                      color: index <= activeIndex
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (index != statuses.length - 1)
              Container(width: 10, height: 1, color: colors.border),
          ],
        ],
      ),
    );
  }
}
