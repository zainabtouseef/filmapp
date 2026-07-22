import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';

enum DpTone { neutral, info, success, warning, danger, purple }

Color dpToneColor(BuildContext context, DpTone tone) {
  final colors = context.appColors;
  return switch (tone) {
    DpTone.neutral => colors.textSecondary,
    DpTone.info => colors.infoBlue,
    DpTone.success => colors.success,
    DpTone.warning => colors.warning,
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

/// A quiet dot + label with no pill background — for places that want a
/// status signal without adding another loud chip (e.g. inline metadata
/// rows, dossier cards).
class DpDotLabel extends StatelessWidget {
  final String label;
  final DpTone tone;

  const DpDotLabel(
      {super.key, required this.label, this.tone = DpTone.neutral});

  @override
  Widget build(BuildContext context) {
    final color = dpToneColor(context, tone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// A tap-to-select pill (filter/tab) — gold-filled with a dot when
/// active, quiet glass otherwise.
class DpDotChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const DpDotChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: active ? colors.goldGradient : null,
          color: active
              ? null
              : colors.surface.withValues(alpha: colors.isLight ? 0.7 : 0.2),
          border: Border.all(color: active ? colors.goldMid : colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? colors.onGold : colors.textTertiary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: active ? colors.onGold : colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
