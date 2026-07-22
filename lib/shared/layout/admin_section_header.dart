import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/cine_card_system.dart';

class AdminScreenHeading extends StatelessWidget {
  final String title;

  const AdminScreenHeading({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.left,
        style: AppTextStyles.screenTitle.copyWith(color: colors.textPrimary),
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
    final resolvedActionColor = actionColor ?? colors.goldDark;
    final resolvedTitleColor = titleColor ?? colors.textPrimary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconBadge(
          icon: icon,
          tone: iconColor == colors.infoBlue
              ? CineTone.information
              : CineTone.premium,
          compact: true,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionHeading.copyWith(
              color: resolvedTitleColor,
            ),
          ),
        ),
        if (actionText != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(foregroundColor: resolvedActionColor),
            child: Text(
              actionText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
