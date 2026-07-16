import 'package:flutter/material.dart';

import '../../../shared/cards/metric_action_card.dart';

class DPMetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;

  const DPMetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MetricActionCard(
      item: MetricActionItem(
        icon: icon,
        value: value,
        title: title,
        subtitle: subtitle,
        accentColor: accentColor,
        onTap: onTap,
      ),
    );
  }
}
