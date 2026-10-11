import 'package:flutter/material.dart';

import '../../../shared/marketplace/marketplace_routes.dart';
import '../../../shared/opportunities/opportunity_application_detail_screen.dart';
import '../../director_producer/screens/dp_marketplace_discovery_screen.dart';
import '../routes/location_owner_routes.dart';
import '../widgets/location_owner_shell.dart';
import 'lo01_owner_dashboard_screen.dart';
import 'lo02_location_listing_wizard_screen.dart';
import 'lo03_availability_calendar_screen.dart';
import 'lo04_pricing_deposit_screen.dart';
import 'lo05_rules_restrictions_screen.dart';
import 'lo06_booking_requests_screen.dart';
import 'lo07_check_in_inspection_screen.dart';
import 'lo08_check_out_damage_claim_screen.dart';
import 'lo09_earnings_deposits_screen.dart';
import 'lo10_property_performance_screen.dart';
import 'lo11_owner_profile_screen.dart';
import 'lo12_owner_portfolio_screen.dart';
import 'lo13_opportunities_screen.dart';

class LocationOwnerPortalScreen extends StatelessWidget {
  final String routeName;
  final Object? arguments;

  const LocationOwnerPortalScreen({
    super.key,
    required this.routeName,
    this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    final marketplace = routeName == MarketplaceRoutes.browse;
    return LocationOwnerShell(
      routeName: routeName,
      title:
          marketplace ? 'Marketplace' : LocationOwnerRoutes.titleFor(routeName),
      screenId: marketplace ? 'MP' : LocationOwnerRoutes.screenIdFor(routeName),
      showPageHeading: !marketplace,
      child: _screenFor(routeName),
    );
  }

  Widget _screenFor(String route) {
    return switch (route) {
      MarketplaceRoutes.browse =>
        const DPMarketplaceDiscoveryScreen(browseOnly: true),
      LocationOwnerRoutes.listing => const LO02LocationListingWizardScreen(),
      LocationOwnerRoutes.calendar => const LO03AvailabilityCalendarScreen(),
      LocationOwnerRoutes.pricing => const LO04PricingDepositScreen(),
      LocationOwnerRoutes.rules => const LO05RulesRestrictionsScreen(),
      LocationOwnerRoutes.requests => LO06BookingRequestsScreen(
          initialRequestId: arguments is String ? arguments as String : null,
        ),
      LocationOwnerRoutes.checkIn => const LO07CheckInInspectionScreen(),
      LocationOwnerRoutes.checkOut => const LO08CheckOutDamageClaimScreen(),
      LocationOwnerRoutes.earnings => const LO09EarningsDepositsScreen(),
      LocationOwnerRoutes.performance => const LO10PropertyPerformanceScreen(),
      LocationOwnerRoutes.profile => const LO11OwnerProfileScreen(),
      LocationOwnerRoutes.portfolio => const LO12OwnerPortfolioScreen(),
      LocationOwnerRoutes.opportunities => const LO13OpportunitiesScreen(),
      LocationOwnerRoutes.opportunityApplicationDetail =>
        OpportunityApplicationDetailScreen(
          applicationId: arguments is String ? arguments as String : null,
        ),
      _ => const LO01OwnerDashboardScreen(),
    };
  }
}
