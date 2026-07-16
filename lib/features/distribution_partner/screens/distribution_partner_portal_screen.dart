import 'package:flutter/material.dart';

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
    return DistributionPartnerShell(
      routeName: routeName,
      title: DistributionPartnerRoutes.titleFor(routeName),
      screenId: DistributionPartnerRoutes.screenIdFor(routeName),
      child: _screenFor(routeName),
    );
  }

  Widget _screenFor(String route) {
    return switch (route) {
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
