import 'package:flutter/material.dart';

import '../cards/metric_action_card.dart';

class AdminQuickActionsSection extends StatelessWidget {
  final List<MetricActionItem> items;

  const AdminQuickActionsSection({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return MetricActionRail(items: items);
  }
}
