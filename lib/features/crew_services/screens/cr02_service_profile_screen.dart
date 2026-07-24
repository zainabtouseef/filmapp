import 'package:flutter/material.dart';

import '../routes/crew_services_routes.dart';
import '../widgets/crew_backend_gap.dart';

class CR02ServiceProfileScreen extends StatelessWidget {
  const CR02ServiceProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CrewBackendGap(
      title: 'Service profile',
      icon: Icons.badge_outlined,
      needed: 'Crew provider profile CRUD',
      detail:
          'Crew service profile is not shown from static defaults anymore. Add crew provider profile read/update APIs before enabling profile editing.',
      actionRoute: CrewServicesRoutes.home,
      actionLabel: 'Back to crew',
    );
  }
}
