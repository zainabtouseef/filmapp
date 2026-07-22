import 'package:flutter/material.dart';

import '../cards/cine_card_system.dart';

class QueueSnapshotItem {
  final IconData icon;
  final String title;
  final String count;
  final String status;
  final Color accentColor;
  final VoidCallback? onTap;

  const QueueSnapshotItem({
    required this.icon,
    required this.title,
    required this.count,
    required this.status,
    required this.accentColor,
    this.onTap,
  });
}

class AdminQueueSnapshotSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<QueueSnapshotItem> items;
  final String? actionText;
  final VoidCallback? onActionTap;

  const AdminQueueSnapshotSection({
    super.key,
    required this.title,
    required this.items,
    this.icon = Icons.layers_rounded,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return MetricStrip(
      title: title,
      compact: true,
      actionLabel: actionText,
      onAction: onActionTap,
      items: [
        for (final item in items)
          MetricStripItem(
            icon: item.icon,
            label: item.title,
            value: item.count,
            contextLabel: item.status,
            tone: cineToneFromColor(context, item.accentColor),
            onTap: item.onTap,
          ),
      ],
    );
  }
}
