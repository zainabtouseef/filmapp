import 'package:flutter/material.dart';

import '../../../shared/opportunities/opportunity_inbox_screen.dart';
import '../routes/model_extension_routes.dart';

/// MD-07 Opportunities — browse open "model" requirements directors post
/// and apply directly, backed by the shared casting flow (a model is
/// backed by the same TalentProfile row an actor uses).
class MD07OpportunitiesScreen extends StatelessWidget {
  const MD07OpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OpportunityInboxScreen(
      category: 'model',
      sectionTitle: 'Casting Calls',
      emptyMessage: 'New model campaign opportunities will appear here.',
      detailRoute: ModelExtensionRoutes.opportunityApplicationDetail,
    );
  }
}
