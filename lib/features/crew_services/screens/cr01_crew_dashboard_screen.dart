import 'package:flutter/material.dart';

import '../routes/crew_services_routes.dart';
import '../widgets/crew_backend_gap.dart';

class CR01CrewDashboardScreen extends StatelessWidget {
  const CR01CrewDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CrewBackendGap(
      title: 'Crew dashboard',
      icon: Icons.groups_2_outlined,
      needed: 'Crew profile/dashboard API',
      detail:
          'Crew dashboard cannot show demo profile, credits, bookings, or rating data. Add crew-specific profile/dashboard endpoints and seed MySQL rows for a real demo.',
      actionRoute: CrewServicesRoutes.requests,
      actionLabel: 'Open requests gap',
    );
  }
}
