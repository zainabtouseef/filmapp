import 'package:flutter/material.dart';

import '../../../../shared/cards/cine_card_system.dart';
import '../../../../shared/formatters/cine_format.dart';
import '../../data/director_producer_demo_data.dart';
import '../../routes/director_producer_routes.dart';

/// Compact, business-wide metric strip — the dashboard's "Production
/// Pulse". Every value is computed live from demo-data state.
class DPPulseStrip extends StatelessWidget {
  const DPPulseStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = DirectorProducerDemoData.projects;
    final bookings = DirectorProducerDemoData.bookings;
    final contracts = DirectorProducerDemoData.contracts;
    final payments = DirectorProducerDemoData.payments;
    final negotiations = DirectorProducerDemoData.negotiations;

    final totalCommitted =
        projects.fold<int>(0, (sum, project) => sum + project.confirmedCost);
    final paid = payments
        .where((payment) => payment.status == 'Verified')
        .fold<int>(0, (sum, payment) => sum + payment.amount);
    final pending = payments
        .where((payment) => payment.status != 'Verified')
        .fold<int>(0, (sum, payment) => sum + payment.amount);
    final dealsInProgress = negotiations
        .where((n) => n.status != 'Accepted' && n.status != 'Withdrawn')
        .length;

    final stats = [
      MetricStripItem(
        label: 'Active productions',
        value: '${projects.where((p) => p.status != 'Closed').length}',
        icon: Icons.movie_filter_outlined,
        tone: CineTone.information,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.projects),
      ),
      MetricStripItem(
        label: 'Deals in progress',
        value: '$dealsInProgress',
        icon: Icons.handshake_outlined,
        tone: CineTone.warning,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.bargaining),
      ),
      MetricStripItem(
        label: 'Pending signatures',
        value:
            '${contracts.where((c) => c.status == 'Pending Signature').length}',
        icon: Icons.draw_outlined,
        tone: CineTone.warning,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.contracts),
      ),
      MetricStripItem(
        label: 'Payment proofs',
        value: '${payments.where((p) => p.status == 'Proof Uploaded').length}',
        icon: Icons.upload_file_outlined,
        tone: CineTone.warning,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.payments),
      ),
      MetricStripItem(
        label: 'Committed budget',
        value: CineFormat.currency(totalCommitted, compact: true),
        icon: Icons.account_balance_wallet_outlined,
        tone: CineTone.premium,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.accounts),
      ),
      MetricStripItem(
        label: 'Paid / pending',
        value:
            '${CineFormat.count(paid, compact: true)} / ${CineFormat.count(pending, compact: true)}',
        icon: Icons.receipt_long_outlined,
        tone: CineTone.positive,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.payments),
      ),
      MetricStripItem(
        label: 'Bookings secured',
        value: '${bookings.where((b) => b.statusIndex >= 8).length}',
        icon: Icons.verified_outlined,
        tone: CineTone.positive,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.bargaining),
      ),
    ];

    return MetricStrip(
      title: 'Production pulse',
      items: stats,
    );
  }
}
