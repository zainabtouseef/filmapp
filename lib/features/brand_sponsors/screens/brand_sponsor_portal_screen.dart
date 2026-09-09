import 'package:flutter/material.dart';

import '../routes/brand_sponsor_routes.dart';
import '../widgets/brand_sponsor_shell.dart';
import 'br01_brand_dashboard_screen.dart';
import 'br02_brand_profile_screen.dart';
import 'br03_opportunity_composer_screen.dart';
import 'br04_applications_inbox_screen.dart';
import 'br05_negotiation_terms_screen.dart';
import 'br06_campaign_tracker_screen.dart';
import 'br07_payments_records_screen.dart';
import 'br08_brand_projects_screen.dart';
import 'br09_brand_marketplace_screen.dart';
import 'br10_brand_shortlists_screen.dart';
import 'br11_brand_bookings_screen.dart';

class BrandSponsorPortalScreen extends StatelessWidget {
  final String routeName;

  const BrandSponsorPortalScreen({
    super.key,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return BrandSponsorShell(
      routeName: routeName,
      title: BrandSponsorRoutes.titleFor(routeName),
      screenId: BrandSponsorRoutes.screenIdFor(routeName),
      child: _screenFor(routeName),
    );
  }

  Widget _screenFor(String route) {
    return switch (route) {
      BrandSponsorRoutes.profile => const BR02BrandProfileScreen(),
      BrandSponsorRoutes.projects => const BR08BrandProjectsScreen(),
      BrandSponsorRoutes.marketplace => const BR09BrandMarketplaceScreen(),
      BrandSponsorRoutes.shortlists => const BR10BrandShortlistsScreen(),
      BrandSponsorRoutes.bookings => const BR11BrandBookingsScreen(),
      BrandSponsorRoutes.composer => const BR03OpportunityComposerScreen(),
      BrandSponsorRoutes.applications => const BR04ApplicationsInboxScreen(),
      BrandSponsorRoutes.negotiation => const BR05NegotiationTermsScreen(),
      BrandSponsorRoutes.tracker => const BR06CampaignTrackerScreen(),
      BrandSponsorRoutes.payments => const BR07PaymentsRecordsScreen(),
      _ => const BR01BrandDashboardScreen(),
    };
  }
}
