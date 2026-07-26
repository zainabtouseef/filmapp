import 'package:flutter/material.dart';

import '../../../shared/opportunities/opportunity_inbox_screen.dart';
import '../routes/crew_services_routes.dart';

/// CR-08 Opportunities — browse open "crew" requirements directors post
/// and apply directly.
class CR08OpportunitiesScreen extends StatelessWidget {
  const CR08OpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OpportunityInboxScreen(
      category: 'crew',
      sectionTitle: 'Open Crew Requests',
      emptyMessage: 'New crew requirements from directors will appear here.',
      detailRoute: CrewServicesRoutes.opportunityApplicationDetail,
    );
  }
}
