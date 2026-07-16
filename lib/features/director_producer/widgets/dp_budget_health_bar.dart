import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';

class DPBudgetHealthBar extends StatelessWidget {
  final double value;
  final String label;

  const DPBudgetHealthBar({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = value >= .75
        ? colors.success
        : value >= .45
            ? colors.goldMid
            : colors.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: AppTextStyles.smallMeta.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 5,
            color: color,
            backgroundColor: colors.borderMuted,
          ),
        ),
      ],
    );
  }
}
