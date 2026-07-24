import 'package:flutter/material.dart';

import '../routes/crew_services_routes.dart';
import '../widgets/crew_backend_gap.dart';

class CR03PortfolioCreditsScreen extends StatelessWidget {
  const CR03PortfolioCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CrewBackendGap(
      title: 'Portfolio & credits',
      icon: Icons.video_library_outlined,
      needed: 'Crew portfolio/credits API',
      detail:
          'Portfolio credits now require database-backed media/credit rows. Add list/create/update endpoints and seed Pakistani demo credits through the backend.',
      actionRoute: CrewServicesRoutes.profile,
      actionLabel: 'Open profile gap',
    );
  }
}
