import 'package:flutter/material.dart';

import '../../../shared/opportunities/opportunity_inbox_screen.dart';
import '../routes/location_owner_routes.dart';

/// LO-13 Opportunities — browse open "location" requirements directors
/// post and apply directly with your property.
class LO13OpportunitiesScreen extends StatelessWidget {
  const LO13OpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OpportunityInboxScreen(
      category: 'location',
      sectionTitle: 'Open Location Requests',
      emptyMessage: 'New location requirements from directors will appear here.',
      detailRoute: LocationOwnerRoutes.opportunityApplicationDetail,
    );
  }
}
