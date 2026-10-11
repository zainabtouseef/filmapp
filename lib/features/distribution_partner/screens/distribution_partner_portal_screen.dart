import 'package:flutter/material.dart';

import '../../../shared/marketplace/marketplace_routes.dart';
import '../../director_producer/screens/dp_marketplace_discovery_screen.dart';
import '../routes/distribution_partner_routes.dart';
import '../widgets/distribution_partner_shell.dart';
import 'ds01_distribution_dashboard_screen.dart';
import 'ds02_distributor_contacts_screen.dart';
import 'ds03_release_coordination_screen.dart';
import 'ds04_performance_reporting_screen.dart';

class DistributionPartnerPortalScreen extends StatelessWidget {
  final String routeName;

  const DistributionPartnerPortalScreen({
    super.key,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final marketplace = routeName == MarketplaceRoutes.browse;
    return DistributionPartnerShell(
      routeName: routeName,
      title: marketplace
          ? 'Marketplace'
          : DistributionPartnerRoutes.titleFor(routeName),
      screenId:
          marketplace ? 'MP' : DistributionPartnerRoutes.screenIdFor(routeName),
      showPageHeading: !marketplace,
      child: _screenFor(routeName),
    );
  }

  Widget _screenFor(String route) {
    return switch (route) {
      MarketplaceRoutes.browse =>
        const DPMarketplaceDiscoveryScreen(browseOnly: true),
      DistributionPartnerRoutes.contacts =>
        const DS02DistributorContactsScreen(),
      DistributionPartnerRoutes.release =>
        const DS03ReleaseCoordinationScreen(),
      DistributionPartnerRoutes.reports =>
        const DS04PerformanceReportingScreen(),
      _ => const DS01DistributionDashboardScreen(),
    };
  }
}
