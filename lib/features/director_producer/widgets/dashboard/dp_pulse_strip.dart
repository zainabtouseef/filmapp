import 'package:flutter/material.dart';

import '../../../../core/director/director_dashboard_models.dart';
import '../../../../shared/cards/cine_card_system.dart';
import '../../../../shared/dashboard/dashboard_kit.dart';
import '../../../../shared/formatters/cine_format.dart';
import '../../routes/director_producer_routes.dart';

/// The dashboard's "Production Pulse" — three quick-action stat tiles
/// (Active productions / Paid-pending / Bookings secured), values
/// computed live from demo-data state.
class DPPulseStrip extends StatelessWidget {
  final DirectorDashboardSummary summary;

  const DPPulseStrip({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final paid = summary.paidMinor ~/ 100;
    final pending = summary.pendingPaymentMinor ~/ 100;

    final tiles = [
      PortalQuickStatTile(
        icon: Icons.movie_creation_outlined,
        value: '${summary.activeProjects}',
        label: 'Active productions',
        delta: 'Live now',
        tone: CineTone.information,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.projects),
      ),
      PortalQuickStatTile(
        icon: Icons.account_balance_wallet_outlined,
        value:
            '${CineFormat.count(paid, compact: true)} / ${CineFormat.count(pending, compact: true)}',
        label: 'Paid / pending',
        delta: 'This cycle',
        tone: CineTone.warning,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.payments),
      ),
      PortalQuickStatTile(
        icon: Icons.handshake_outlined,
        value: '${summary.securedBookings}',
        label: 'Bookings secured',
        delta: 'This cycle',
        tone: CineTone.positive,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.bargaining),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 9.0;
        final columns = constraints.maxWidth < 360
            ? 1
            : constraints.maxWidth < 700
                ? 2
                : 3;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}
