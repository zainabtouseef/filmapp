import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/glass_section_card.dart';
import '../layout/admin_section_header.dart';
import '../widgets/status_chip.dart';

class ActionFeedItem {
  final String label;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;
  final IconData? icon;

  const ActionFeedItem({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.onTap,
    this.icon,
  });
}

class AdminActionFeedSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onActionTap;
  final List<ActionFeedItem> items;

  const AdminActionFeedSection({
    super.key,
    required this.title,
    required this.items,
    this.icon = Icons.bolt_rounded,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSectionCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        children: [
          AdminSectionHeader(
            title: title,
            icon: icon,
            actionText: actionText,
            onActionTap: onActionTap,
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < items.length; index++) ...[
            _ActionFeedRow(item: items[index]),
            if (index != items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ActionFeedRow extends StatelessWidget {
  final ActionFeedItem item;

  const _ActionFeedRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: colors.borderMuted),
        ),
        child: Row(
          children: [
            StatusChip(
              label: item.label,
              icon: item.icon,
              color: item.accentColor,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontSize: 13,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.statusText.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.iconMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
