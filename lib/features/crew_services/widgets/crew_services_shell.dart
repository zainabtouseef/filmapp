import 'package:flutter/material.dart';

import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../actor_talent/widgets/actor_talent_shell.dart';
import '../routes/crew_services_routes.dart';

const _crewBottomDestinations = [
  CineBottomNavDestination(label: 'Home', icon: Icons.home_outlined),
  CineBottomNavDestination(label: 'Requests', icon: Icons.inbox_outlined),
  CineBottomNavDestination(
      label: 'Calendar', icon: Icons.calendar_month_outlined),
  CineBottomNavDestination(
      label: 'Payments', icon: Icons.account_balance_wallet_outlined),
  CineBottomNavDestination(label: 'Profile', icon: Icons.badge_outlined),
];

const crewMenuEntries = <ActorShellMenuEntry>[
  (
    route: CrewServicesRoutes.home,
    screenId: 'CR-01',
    label: 'Crew Dashboard',
    icon: Icons.dashboard_outlined,
  ),
  (
    route: CrewServicesRoutes.profile,
    screenId: 'CR-02',
    label: 'Service Profile',
    icon: Icons.badge_outlined,
  ),
  (
    route: CrewServicesRoutes.portfolio,
    screenId: 'CR-03',
    label: 'Portfolio & Credits',
    icon: Icons.video_library_outlined,
  ),
  (
    route: CrewServicesRoutes.availability,
    screenId: 'CR-04',
    label: 'Availability Calendar',
    icon: Icons.calendar_month_outlined,
  ),
  (
    route: CrewServicesRoutes.requests,
    screenId: 'CR-05',
    label: 'Requests & Negotiation',
    icon: Icons.move_to_inbox_outlined,
  ),
  (
    route: CrewServicesRoutes.contracts,
    screenId: 'CR-06',
    label: 'Contracts & Payments',
    icon: Icons.payments_outlined,
  ),
  (
    route: CrewServicesRoutes.ratings,
    screenId: 'CR-07',
    label: 'Ratings & Work History',
    icon: Icons.stars_outlined,
  ),
  (
    route: CrewServicesRoutes.opportunities,
    screenId: 'CR-08',
    label: 'Opportunities',
    icon: Icons.travel_explore_outlined,
  ),
];

const _crewBottomIndexOverrides = {
  CrewServicesRoutes.portfolio: 4,
  CrewServicesRoutes.ratings: 4,
  CrewServicesRoutes.opportunities: 4,
};

class CrewServicesShell extends StatelessWidget {
  final String routeName;
  final String title;
  final String screenId;
  final Widget child;

  const CrewServicesShell({
    super.key,
    required this.routeName,
    required this.title,
    required this.screenId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ActorTalentShell(
      routeName: routeName,
      title: title,
      screenId: screenId,
      portalLabel: 'Crew & Production Services',
      menuTitle: 'Crew service screens',
      navRoutes: CrewServicesRoutes.primaryNav,
      navDestinations: _crewBottomDestinations,
      menuEntries: crewMenuEntries,
      bottomIndexOverrides: _crewBottomIndexOverrides,
      workspaceLayout: true,
      workspaceTitle: 'Crew Workspace',
      workspaceSectionLabel: 'CREW / PRODUCTION SERVICES',
      workspaceBadgeLabel: 'Crew Pro',
      workspaceStatusSubtitle:
          'Profile, credits, availability, requests and payments',
      workspaceSearchHint: 'Search requests, projects and opportunities...',
      workspaceSearchRoute: CrewServicesRoutes.opportunities,
      workspaceProfileRoute: CrewServicesRoutes.profile,
      workspaceIcon: Icons.groups_2_outlined,
      workspaceEyebrow: _crewEyebrow,
      child: child,
    );
  }
}

String _crewEyebrow(String route) {
  return switch (route) {
    CrewServicesRoutes.home => 'Crew workspace · live operations',
    CrewServicesRoutes.profile => 'Public identity · services · coverage',
    CrewServicesRoutes.portfolio => 'Credits · reels · production work',
    CrewServicesRoutes.availability => 'Schedule · holds · confirmed work',
    CrewServicesRoutes.requests => 'Requests · offers · negotiation',
    CrewServicesRoutes.contracts => 'Contracts · earnings · payout ledger',
    CrewServicesRoutes.ratings => 'Reputation · reviews · work history',
    CrewServicesRoutes.opportunities => 'Open projects · applications',
    _ => 'Crew production workspace',
  };
}
