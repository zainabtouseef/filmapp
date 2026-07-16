import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/widgets/status_chip.dart';

enum DpTone { neutral, info, success, warning, danger, purple }

Color dpToneColor(BuildContext context, DpTone tone) {
  final colors = context.appColors;
  return switch (tone) {
    DpTone.neutral => colors.textSecondary,
    DpTone.info => colors.infoBlue,
    DpTone.success => colors.success,
    DpTone.warning => colors.goldMid,
    DpTone.danger => colors.danger,
    DpTone.purple => colors.infoPurple,
  };
}

class DPStatusChip extends StatelessWidget {
  final String label;
  final DpTone tone;
  final IconData? icon;

  const DPStatusChip({
    super.key,
    required this.label,
    this.tone = DpTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: label,
      icon: icon,
      color: dpToneColor(context, tone),
    );
  }
}
