import 'package:flutter/material.dart';

import '../../../shared/opportunities/opportunity_application_detail_screen.dart';
import '../routes/media_equipment_routes.dart';
import '../widgets/media_equipment_shell.dart';
import 'me01_provider_dashboard_screen.dart';
import 'me02_provider_profile_screen.dart';
import 'me03_inventory_manager_screen.dart';
import 'me04_package_builder_screen.dart';
import 'me05_availability_calendar_screen.dart';
import 'me06_rate_terms_screen.dart';
import 'me07_booking_requests_screen.dart';
import 'me08_handover_checklist_screen.dart';
import 'me09_return_checklist_screen.dart';
import 'me10_earnings_ratings_screen.dart';
import 'me11_provider_portfolio_screen.dart';
import 'me12_opportunities_screen.dart';

class MediaEquipmentPortalScreen extends StatelessWidget {
  final String routeName;
  final Object? arguments;

  const MediaEquipmentPortalScreen({
    super.key,
    required this.routeName,
    this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    return MediaEquipmentShell(
      routeName: routeName,
      title: MediaEquipmentRoutes.titleFor(routeName),
      screenId: MediaEquipmentRoutes.screenIdFor(routeName),
      child: _screenFor(routeName),
    );
  }

  Widget _screenFor(String route) {
    return switch (route) {
      MediaEquipmentRoutes.profile => const ME02ProviderProfileScreen(),
      MediaEquipmentRoutes.inventory => const ME03InventoryManagerScreen(),
      MediaEquipmentRoutes.packages => const ME04PackageBuilderScreen(),
      MediaEquipmentRoutes.availability =>
        const ME05AvailabilityCalendarScreen(),
      MediaEquipmentRoutes.terms => const ME06RateTermsScreen(),
      MediaEquipmentRoutes.requests => ME07BookingRequestsScreen(
          initialRequestId: arguments is String ? arguments as String : null,
        ),
      MediaEquipmentRoutes.handover => const ME08HandoverChecklistScreen(),
      MediaEquipmentRoutes.returns => const ME09ReturnChecklistScreen(),
      MediaEquipmentRoutes.earnings => const ME10EarningsRatingsScreen(),
      MediaEquipmentRoutes.portfolio => const ME11ProviderPortfolioScreen(),
      MediaEquipmentRoutes.opportunities => const ME12OpportunitiesScreen(),
      MediaEquipmentRoutes.opportunityApplicationDetail =>
        OpportunityApplicationDetailScreen(
          applicationId: arguments is String ? arguments as String : null,
        ),
      _ => const ME01ProviderDashboardScreen(),
    };
  }
}
