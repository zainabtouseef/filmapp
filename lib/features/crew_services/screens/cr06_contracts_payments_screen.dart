import 'package:flutter/material.dart';

import '../routes/crew_services_routes.dart';
import '../widgets/crew_backend_gap.dart';

class CR06ContractsPaymentsScreen extends StatelessWidget {
  const CR06ContractsPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CrewBackendGap(
      title: 'Contracts & payments',
      icon: Icons.receipt_long_outlined,
      needed: 'Crew contract/payment linkage',
      detail:
          'Crew contracts and payment ledger are no longer local demo rows. Link crew bookings to contracts, payment schedules, proofs, and payout ledger APIs before showing records here.',
      actionRoute: CrewServicesRoutes.ratings,
      actionLabel: 'Open ratings gap',
    );
  }
}
