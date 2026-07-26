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
          'Crew dashboard is still waiting for a dedicated summary API, but open production opportunities and applications are live now.',
      actionRoute: CrewServicesRoutes.opportunities,
      actionLabel: 'Browse opportunities',
    );
  }
}
