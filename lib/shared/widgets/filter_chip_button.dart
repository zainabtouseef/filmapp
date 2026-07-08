import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import 'glass_card.dart';

/// Secondary rounded-rectangle filter control (Lahore / Budget / ...).
class FilterChipBox extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool showChevron;
  final Widget? trailing;
  final VoidCallback? onTap;

  const FilterChipBox({
    super.key,
    this.icon,
    required this.label,
    this.showChevron = true,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tablet = MediaQuery.sizeOf(context).width >= 700;
    final height = tablet ? 56.0 : 50.0;

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        height: height,
        radius: tablet ? 16 : 15,
        blur: 14,
        padding: EdgeInsets.symmetric(horizontal: tablet ? 22 : 16),
        gradient: colors.filterGradient,
        borderColor: colors.border,
        borderWidth: 1.05,
        shadows: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: colors.isLight ? 0.2 : 0.44),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: tablet ? 22 : 19, color: colors.icon),
              SizedBox(width: tablet ? 12 : 9),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  color: colors.textPrimary,
                  fontSize: tablet ? 17 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: tablet ? 14 : 10),
              trailing!,
            ] else if (showChevron) ...[
              SizedBox(width: tablet ? 14 : 10),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: tablet ? 23 : 20,
                color: colors.iconMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class VerifiedToggleChip extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const VerifiedToggleChip({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChipBox(
      label: 'Verified only',
      showChevron: false,
      trailing: GoldSwitch(value: value, onChanged: onChanged),
      onTap: () => onChanged?.call(!value),
    );
  }
}

/// Backwards-compatible name for older dashboard code.
class FilterControl extends FilterChipBox {
  const FilterControl({
    super.key,
    super.icon,
    required super.label,
    super.showChevron,
    super.trailing,
    super.onTap,
  });
}

/// A small gold toggle switch used in "Verified only".
class GoldSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const GoldSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tablet = MediaQuery.sizeOf(context).width >= 700;

    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: tablet ? 52 : 46,
        height: tablet ? 28 : 25,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: value ? colors.goldGradient : null,
          color: value ? null : colors.softSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                value ? colors.goldMid.withValues(alpha: 0.72) : colors.border,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: colors.goldGlow,
                    blurRadius: 15,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: tablet ? 22 : 19,
          height: tablet ? 22 : 19,
          decoration: BoxDecoration(
            color: colors.isLight ? Colors.white : const Color(0xFFFFF1C5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.shadow
                    .withValues(alpha: colors.isLight ? 0.2 : 0.45),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
