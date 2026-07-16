import 'package:flutter/material.dart';

import '../routes/insurance_partner_routes.dart';
import '../widgets/insurance_partner_shell.dart';
import 'in01_insurance_dashboard_screen.dart';
import 'in02_shoot_insurance_records_screen.dart';
import 'in03_claim_support_screen.dart';
import 'in04_safety_checks_permits_screen.dart';
import 'in05_incident_reports_screen.dart';

class InsurancePartnerPortalScreen extends StatelessWidget {
  final String routeName;

  const InsurancePartnerPortalScreen({
    super.key,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return InsurancePartnerShell(
      routeName: routeName,
      title: InsurancePartnerRoutes.titleFor(routeName),
      screenId: InsurancePartnerRoutes.screenIdFor(routeName),
      child: _screenFor(routeName),
    );
  }

  Widget _screenFor(String route) {
    return switch (route) {
      InsurancePartnerRoutes.records => const IN02ShootInsuranceRecordsScreen(),
      InsurancePartnerRoutes.claims => const IN03ClaimSupportScreen(),
      InsurancePartnerRoutes.safety => const IN04SafetyChecksPermitsScreen(),
      InsurancePartnerRoutes.incidents => const IN05IncidentReportsScreen(),
      _ => const IN01InsuranceDashboardScreen(),
    };
  }
}
