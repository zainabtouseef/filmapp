import 'package:flutter/material.dart';

import '../routes/crew_services_routes.dart';
import '../widgets/crew_backend_gap.dart';

class CR07RatingsWorkHistoryScreen extends StatelessWidget {
  const CR07RatingsWorkHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CrewBackendGap(
      title: 'Ratings & work history',
      icon: Icons.star_rate_outlined,
      needed: 'Crew reviews/work history API',
      detail:
          'Crew ratings and credits no longer render from static reviews. Add crew-specific review/work-history endpoints or map Trust & Safety reviews to crew booking IDs.',
      actionRoute: CrewServicesRoutes.home,
      actionLabel: 'Back to crew',
    );
  }
}
