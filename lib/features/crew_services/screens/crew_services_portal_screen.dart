import 'package:flutter/material.dart';

import '../routes/crew_services_routes.dart';
import '../widgets/crew_services_shell.dart';
import 'cr01_crew_dashboard_screen.dart';
import 'cr02_service_profile_screen.dart';
import 'cr03_portfolio_credits_screen.dart';
import 'cr04_availability_calendar_screen.dart';
import 'cr05_requests_negotiation_screen.dart';
import 'cr06_contracts_payments_screen.dart';
import 'cr07_ratings_work_history_screen.dart';

class CrewServicesPortalScreen extends StatelessWidget {
  final String routeName;
  final Object? arguments;

  const CrewServicesPortalScreen({
    super.key,
    required this.routeName,
    this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    return CrewServicesShell(
      routeName: routeName,
      title: CrewServicesRoutes.titleFor(routeName),
      screenId: CrewServicesRoutes.screenIdFor(routeName),
      child: _screenFor(routeName),
    );
  }

  Widget _screenFor(String route) {
    return switch (route) {
      CrewServicesRoutes.profile => const CR02ServiceProfileScreen(),
      CrewServicesRoutes.portfolio => const CR03PortfolioCreditsScreen(),
      CrewServicesRoutes.availability => const CR04AvailabilityCalendarScreen(),
      CrewServicesRoutes.requests => CR05RequestsNegotiationScreen(
          initialRequestId: arguments is String ? arguments as String : null,
        ),
      CrewServicesRoutes.contracts => const CR06ContractsPaymentsScreen(),
      CrewServicesRoutes.ratings => const CR07RatingsWorkHistoryScreen(),
      _ => const CR01CrewDashboardScreen(),
    };
  }
}
