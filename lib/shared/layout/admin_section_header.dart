import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';

class AdminScreenHeading extends StatelessWidget {
  final String title;

  const AdminScreenHeading({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTextStyles.screenTitle.copyWith(
          color: colors.textPrimary,
          shadows: [
            Shadow(
              color: colors.textPrimary.withValues(alpha: 0.12),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final Color? iconColor;
  final Color? actionColor;
  final Color? titleColor;

  const AdminSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.actionText,
    this.onActionTap,
    this.iconColor,
    this.actionColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final resolvedIconColor = iconColor ?? colors.goldDark;
    final resolvedActionColor = actionColor ?? colors.goldDark;
    final resolvedTitleColor = titleColor ?? colors.textPrimary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: resolvedIconColor,
          size: 22,
          shadows: [
            Shadow(
              color: resolvedIconColor.withValues(alpha: 0.2),
              blurRadius: 7,
            ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionHeading.copyWith(
              color: resolvedTitleColor,
              shadows: [
                Shadow(
                  color: resolvedTitleColor.withValues(alpha: 0.14),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
        if (actionText != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onActionTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
              child: Text(
                actionText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionAction.copyWith(
                  color: resolvedActionColor,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
