import 'package:flutter/material.dart';

import '../cards/cine_card_system.dart';

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
    return SectionContainer(
      title: '$title · ${items.length}',
      leading: IconBadge(icon: icon, tone: CineTone.warning, compact: true),
      action: actionText == null
          ? null
          : TextButton(onPressed: onActionTap, child: Text(actionText!)),
      child: Column(
        children: [
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
    return PriorityActionCard(
      title: item.title,
      metadata: item.subtitle,
      priority: item.label,
      icon: item.icon ?? Icons.bolt_rounded,
      tone: cineToneFromColor(context, item.accentColor),
      onTap: item.onTap,
    );
  }
}
