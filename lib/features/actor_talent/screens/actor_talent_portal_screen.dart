import 'package:flutter/material.dart';

import '../routes/actor_talent_routes.dart';
import '../widgets/actor_talent_shell.dart';
import 'at01_talent_dashboard_screen.dart';
import 'at02_profile_builder_screen.dart';
import 'at03_portfolio_showreel_screen.dart';
import 'at04_availability_calendar_screen.dart';
import 'at05_rate_card_screen.dart';
import 'at06_opportunity_inbox_screen.dart';
import 'at07_offer_detail_screen.dart';
import 'at08_counteroffer_composer_screen.dart';
import 'at09_contract_signing_screen.dart';
import 'at10_earnings_security_screen.dart';
import 'at11_reputation_reviews_screen.dart';
import 'at12_safety_controls_screen.dart';
import 'at13_role_detail_apply_screen.dart';
import 'at14_applications_screen.dart';
import 'at15_application_detail_screen.dart';
import 'at17_bookings_messages_screen.dart';

class ActorTalentPortalScreen extends StatelessWidget {
  final String routeName;
  final Object? arguments;

  const ActorTalentPortalScreen({
    super.key,
    required this.routeName,
    this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    final title = ActorTalentRoutes.titleFor(routeName);
    final screenId = ActorTalentRoutes.screenIdFor(routeName);
    return ActorTalentShell(
      routeName: routeName,
      title: title,
      screenId: screenId,
      workspaceLayout: true,
      child: _screenFor(routeName),
    );
  }

  Widget _screenFor(String route) {
    final id = arguments is String
        ? arguments as String
        : arguments is Map
            ? ((arguments! as Map)['id'] ??
                (arguments! as Map)['roleId'] ??
                (arguments! as Map)['applicationId']) as String?
            : null;
    return switch (route) {
      ActorTalentRoutes.dashboard => const AT01TalentDashboardScreen(),
      ActorTalentRoutes.profile => const AT02ProfileBuilderScreen(),
      ActorTalentRoutes.portfolio => const AT03PortfolioShowreelScreen(),
      ActorTalentRoutes.calendar => const AT04AvailabilityCalendarScreen(),
      ActorTalentRoutes.rates => const AT05RateCardScreen(),
      ActorTalentRoutes.opportunities => const AT06OpportunityInboxScreen(),
      ActorTalentRoutes.roleDetail => AT13RoleDetailApplyScreen(roleId: id),
      ActorTalentRoutes.applications => const AT14ApplicationsScreen(),
      ActorTalentRoutes.applicationDetail =>
        AT15ApplicationDetailScreen(applicationId: id),
      ActorTalentRoutes.auditions =>
        const AT14ApplicationsScreen(auditionsOnly: true),
      ActorTalentRoutes.bookings => const AT17BookingsMessagesScreen(),
      ActorTalentRoutes.offerDetail => AT07OfferDetailScreen(offerId: id),
      ActorTalentRoutes.counteroffer =>
        AT08CounterofferComposerScreen(offerId: id),
      ActorTalentRoutes.contracts => const AT09ContractSigningScreen(),
      ActorTalentRoutes.earnings => const AT10EarningsSecurityScreen(),
      ActorTalentRoutes.reputation => const AT11ReputationReviewsScreen(),
      ActorTalentRoutes.safety => const AT12SafetyControlsScreen(),
      _ => const AT01TalentDashboardScreen(),
    };
  }
}
