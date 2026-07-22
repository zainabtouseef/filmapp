import 'package:flutter/material.dart';

import '../cards/cine_card_system.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CineStatusBadge(
      label: label,
      icon: icon,
      showDot: icon == null,
      colorOverride: color,
    );
  }
}
