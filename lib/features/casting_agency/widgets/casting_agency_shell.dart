import 'package:flutter/material.dart';

import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../actor_talent/widgets/actor_talent_shell.dart';
import '../routes/casting_agency_routes.dart';

const _agencyBottomDestinations = [
  CineBottomNavDestination(label: 'Dashboard', icon: Icons.dashboard_outlined),
  CineBottomNavDestination(label: 'Roster', icon: Icons.people_alt_outlined),
  CineBottomNavDestination(label: 'Auditions', icon: Icons.inbox_outlined),
  CineBottomNavDestination(
    label: 'Submissions',
    icon: Icons.video_collection_outlined,
  ),
  CineBottomNavDestination(label: 'Records', icon: Icons.receipt_long_outlined),
];

const agencyMenuEntries = <ActorShellMenuEntry>[
  (
    route: CastingAgencyRoutes.home,
    screenId: 'CA-01',
    label: 'Agency Dashboard',
    icon: Icons.dashboard_outlined,
  ),
  (
    route: CastingAgencyRoutes.roster,
    screenId: 'CA-02',
    label: 'Talent Roster Manager',
    icon: Icons.people_alt_outlined,
  ),
  (
    route: CastingAgencyRoutes.auditions,
    screenId: 'CA-03',
    label: 'Audition Request Inbox',
    icon: Icons.inbox_outlined,
  ),
  (
    route: CastingAgencyRoutes.shortlist,
    screenId: 'CA-04',
    label: 'Candidate Shortlist Builder',
    icon: Icons.view_kanban_outlined,
  ),
  (
    route: CastingAgencyRoutes.selfTapes,
    screenId: 'CA-05',
    label: 'Self-Tape Collection',
    icon: Icons.video_collection_outlined,
  ),
  (
    route: CastingAgencyRoutes.notes,
    screenId: 'CA-06',
    label: 'Interview & Selection Notes',
    icon: Icons.edit_note_outlined,
  ),
  (
    route: CastingAgencyRoutes.commission,
    screenId: 'CA-07',
    label: 'Commission Settings & Records',
    icon: Icons.percent_outlined,
  ),
  (
    route: CastingAgencyRoutes.records,
    screenId: 'CA-08',
    label: 'Agency Booking Records',
    icon: Icons.receipt_long_outlined,
  ),
];

const _agencyBottomIndexOverrides = {
  CastingAgencyRoutes.shortlist: 2,
  CastingAgencyRoutes.notes: 3,
  CastingAgencyRoutes.commission: 4,
};

class CastingAgencyShell extends StatelessWidget {
  final String routeName;
  final String title;
  final String screenId;
  final Widget child;

  const CastingAgencyShell({
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
      portalLabel: 'Casting Director / Agency Portal',
      menuTitle: 'Agency portal screens',
      navRoutes: CastingAgencyRoutes.primaryNav,
      navDestinations: _agencyBottomDestinations,
      menuEntries: agencyMenuEntries,
      bottomIndexOverrides: _agencyBottomIndexOverrides,
      child: child,
    );
  }
}
