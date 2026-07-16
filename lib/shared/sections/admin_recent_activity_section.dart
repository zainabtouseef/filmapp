import 'package:flutter/material.dart';

import 'admin_action_feed_section.dart';

class AdminRecentActivitySection extends StatelessWidget {
  final List<ActionFeedItem> items;
  final String? actionText;
  final VoidCallback? onActionTap;

  const AdminRecentActivitySection({
    super.key,
    required this.items,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return AdminActionFeedSection(
      title: 'RECENT ACTIVITY',
      icon: Icons.history_rounded,
      actionText: actionText,
      onActionTap: onActionTap,
      items: items,
    );
  }
}
