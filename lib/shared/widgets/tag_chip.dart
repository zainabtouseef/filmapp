import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import 'glass_card.dart';

/// Small outlined tag chip (Drama Serial / TVC / Theatre).
class TagChip extends StatelessWidget {
  final String label;

  const TagChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GlassContainer(
      radius: 22,
      blur: 10,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      gradient: colors.inactiveChipGradient,
      borderColor: colors.border,
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
