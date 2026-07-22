import 'package:flutter/material.dart';

import 'cine_card_system.dart';

export 'cine_card_system.dart';

class MetricActionItem {
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;

  const MetricActionItem({
    required this.icon,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.onTap,
  });
}

/// Compatibility wrapper for existing portal metrics.
///
/// New code should use [CompactMetricCard] or [MetricStrip] directly.
class MetricActionCard extends StatelessWidget {
  final MetricActionItem item;

  const MetricActionCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return CompactMetricCard(
      icon: item.icon,
      value: item.value,
      label: item.title,
      contextLabel: item.subtitle,
      tone: cineToneFromColor(context, item.accentColor),
      onTap: item.onTap,
    );
  }
}

/// Related metrics share one connected surface on every portal.
class MetricActionRail extends StatelessWidget {
  final List<MetricActionItem> items;

  const MetricActionRail({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return MetricStrip(
      items: [
        for (final item in items)
          MetricStripItem(
            icon: item.icon,
            label: item.title,
            value: item.value,
            contextLabel: item.subtitle,
            tone: cineToneFromColor(context, item.accentColor),
            onTap: item.onTap,
          ),
      ],
    );
  }
}
