import 'package:flutter/material.dart';

import '../../../shared/marketplace/marketplace_routes.dart';
import '../../director_producer/screens/dp_marketplace_discovery_screen.dart';
import '../routes/casting_agency_routes.dart';
import '../widgets/casting_agency_shell.dart';
import 'ca01_agency_dashboard_screen.dart';
import 'ca02_talent_roster_screen.dart';
import 'ca03_audition_request_inbox_screen.dart';
import 'ca04_candidate_shortlist_screen.dart';
import 'ca05_self_tape_collection_screen.dart';
import 'ca06_selection_notes_screen.dart';
import 'ca07_commission_records_screen.dart';
import 'ca08_agency_booking_records_screen.dart';

class CastingAgencyPortalScreen extends StatelessWidget {
  final String routeName;

  const CastingAgencyPortalScreen({
    super.key,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final marketplace = routeName == MarketplaceRoutes.browse;
    return CastingAgencyShell(
      routeName: routeName,
      title:
          marketplace ? 'Marketplace' : CastingAgencyRoutes.titleFor(routeName),
      screenId: marketplace ? 'MP' : CastingAgencyRoutes.screenIdFor(routeName),
      showPageHeading: !marketplace && routeName != CastingAgencyRoutes.home,
      child: _screenFor(routeName),
    );
  }

  Widget _screenFor(String route) {
    return switch (route) {
      MarketplaceRoutes.browse =>
        const DPMarketplaceDiscoveryScreen(browseOnly: true),
      CastingAgencyRoutes.roster => const CA02TalentRosterScreen(),
      CastingAgencyRoutes.auditions => const CA03AuditionRequestInboxScreen(),
      CastingAgencyRoutes.shortlist => const CA04CandidateShortlistScreen(),
      CastingAgencyRoutes.selfTapes => const CA05SelfTapeCollectionScreen(),
      CastingAgencyRoutes.notes => const CA06SelectionNotesScreen(),
      CastingAgencyRoutes.commission => const CA07CommissionRecordsScreen(),
      CastingAgencyRoutes.records => const CA08AgencyBookingRecordsScreen(),
      _ => const CA01AgencyDashboardScreen(),
    };
  }
}
