import 'package:flutter/material.dart';

import '../../../shared/cards/cine_card_system.dart';

class DPEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const DPEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      title: title,
      message: message,
      icon: icon,
    );
  }
}
