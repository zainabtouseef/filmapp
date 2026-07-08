import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';

/// Pill-shaped category chip (Actors / Models / Directors ...).
class CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tablet = MediaQuery.sizeOf(context).width >= 700;
    final height = tablet ? 56.0 : 48.0;
    final foreground = active ? colors.goldDark : colors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: tablet ? 22 : 18),
        decoration: BoxDecoration(
          gradient:
              active ? colors.activeChipGradient : colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: active ? colors.goldMid : colors.border,
            width: active ? 1.25 : 1.05,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  colors.shadow.withValues(alpha: colors.isLight ? 0.18 : 0.55),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            if (active)
              BoxShadow(
                color: colors.goldGlow,
                blurRadius: 20,
                spreadRadius: -4,
              ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: tablet ? 22 : 19, color: foreground),
              SizedBox(width: tablet ? 10 : 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: foreground,
                    fontSize: tablet ? 17 : 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
