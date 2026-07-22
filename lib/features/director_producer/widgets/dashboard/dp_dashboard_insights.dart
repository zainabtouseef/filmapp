import 'package:flutter/material.dart';

import '../../data/director_producer_demo_data.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_status_chip.dart';

/// A single real, actionable item surfaced on the dashboard's priority
/// list — derived from live demo-data state rather than hardcoded, so the
/// count shown in the command header and the list in the Priority Action
/// Centre can never drift apart.
class DpPriorityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final DpTone tone;
  final String urgency;
  final String route;
  final Object? argument;

  const DpPriorityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.urgency,
    required this.route,
    this.argument,
  });
}

List<DpPriorityItem> dpPriorityItems() {
  final items = <DpPriorityItem>[];

  for (final payment in DirectorProducerDemoData.payments) {
    if (payment.status != 'Rejected') continue;
    items.add(DpPriorityItem(
      icon: Icons.error_outline_rounded,
      title: 'Payment rejected: ${payment.stakeholder}',
      subtitle:
          '${payment.booking} • ${payment.rejectedReason ?? 'Re-upload proof'}',
      tone: DpTone.danger,
      urgency: 'Critical',
      route: DirectorProducerRoutes.payments,
    ));
  }

  for (final contract in DirectorProducerDemoData.contracts) {
    if (contract.status != 'Pending Signature') continue;
    items.add(DpPriorityItem(
      icon: Icons.draw_outlined,
      title: 'Signature needed: ${contract.title}',
      subtitle: '${contract.project} • ${contract.candidate}',
      tone: DpTone.warning,
      urgency: 'Due today',
      route: DirectorProducerRoutes.contracts,
    ));
  }

  for (final negotiation in DirectorProducerDemoData.negotiations) {
    if (negotiation.status != 'Your move') continue;
    items.add(DpPriorityItem(
      icon: Icons.question_answer_outlined,
      title: '${negotiation.candidate} is waiting on your move',
      subtitle: '${negotiation.project} • ${negotiation.move}',
      tone: DpTone.info,
      urgency: 'Waiting on you',
      route: DirectorProducerRoutes.negotiationThread,
      argument: negotiation.id,
    ));
  }

  for (final negotiation in DirectorProducerDemoData.negotiations) {
    final active =
        negotiation.status != 'Accepted' && negotiation.status != 'Withdrawn';
    if (!active || !negotiation.expiry.contains('h')) continue;
    items.add(DpPriorityItem(
      icon: Icons.timer_outlined,
      title: 'Offer expires in ${negotiation.expiry}',
      subtitle: '${negotiation.project} • ${negotiation.requirement}',
      tone: DpTone.warning,
      urgency: 'Expiring soon',
      route: DirectorProducerRoutes.negotiationThread,
      argument: negotiation.id,
    ));
  }

  return items;
}
