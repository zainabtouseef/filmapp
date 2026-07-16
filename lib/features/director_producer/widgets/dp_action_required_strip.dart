import 'package:flutter/material.dart';

import '../../../shared/cards/metric_action_card.dart';
import 'dp_status_chip.dart';

class DPActionRequiredStrip extends StatelessWidget {
  final List<DPActionRequiredItem> items;

  const DPActionRequiredStrip({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return MetricActionRail(
      items: [
        for (final item in items)
          MetricActionItem(
            icon: item.icon,
            value: item.count,
            title: item.title,
            subtitle: item.timer,
            accentColor: dpToneColor(context, item.tone),
            onTap: item.onTap,
          ),
      ],
    );
  }
}

class DPActionRequiredItem {
  final IconData icon;
  final String count;
  final String title;
  final String timer;
  final DpTone tone;
  final VoidCallback? onTap;

  const DPActionRequiredItem({
    required this.icon,
    required this.count,
    required this.title,
    required this.timer,
    required this.tone,
    this.onTap,
  });
}
