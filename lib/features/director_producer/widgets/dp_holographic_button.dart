import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';

class DPHolographicButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool secondary;

  const DPHolographicButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: secondary ? colors.glassGradient : colors.goldGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: secondary ? colors.border : colors.goldMid),
          boxShadow: [
            BoxShadow(
              color: colors.goldGlow.withValues(alpha: secondary ? 0.04 : 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: secondary ? colors.textPrimary : colors.onGold,
              size: 17,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.statusText.copyWith(
                  color: secondary ? colors.textPrimary : colors.onGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
