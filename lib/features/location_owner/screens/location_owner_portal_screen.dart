import 'package:flutter/material.dart';

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
    return LocationOwnerShell(
      routeName: routeName,
      title: LocationOwnerRoutes.titleFor(routeName),
      screenId: LocationOwnerRoutes.screenIdFor(routeName),
      child: _screenFor(routeName),
    );
  }

  Widget _screenFor(String route) {
    return switch (route) {
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
      _ => const LO01OwnerDashboardScreen(),
    };
  }
}
