import 'package:flutter/material.dart';

import '../../../shared/opportunities/opportunity_inbox_screen.dart';
import '../routes/media_equipment_routes.dart';

/// ME-12 Opportunities — browse open "equipment" requirements directors
/// post and apply directly.
class ME12OpportunitiesScreen extends StatelessWidget {
  const ME12OpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OpportunityInboxScreen(
      category: 'equipment',
      sectionTitle: 'Open Equipment Requests',
      emptyMessage: 'New equipment requirements from directors will appear here.',
      detailRoute: MediaEquipmentRoutes.opportunityApplicationDetail,
    );
  }
}
