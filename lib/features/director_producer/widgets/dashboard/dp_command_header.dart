import 'package:flutter/material.dart';

import '../../../../core/director/director_dashboard_models.dart';
import '../../../../core/tour/tour_target.dart';
import '../../../../shared/dashboard/dashboard_kit.dart';
import '../../../../shared/formatters/cine_format.dart';
import '../../routes/director_producer_routes.dart';

/// The dashboard's command header: the shared dashboard-kit hero card
/// carrying the producer's identity, production/budget stats, and the
/// primary "new project" action. Search and logout already live in the
/// shell's own top bar, so this doesn't repeat them.
class DPCommandHeader extends StatelessWidget {
  final DirectorDashboardSummary summary;
  final String? displayName;

  const DPCommandHeader({
    super.key,
    required this.summary,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final name = (displayName == null || displayName!.trim().isEmpty)
        ? 'Producer'
        : displayName!.trim();
    // TourTarget wraps the whole card rather than just the CTA button —
    // PortalHeroCard doesn't expose its internal button as a separately
    // wrappable slot, and this still spotlights/advances the tour
    // correctly (TourTarget just needs render bounds + a pointer-up
    // inside them).
    return TourTarget(
      id: 'dp.newProject',
      child: PortalHeroCard(
        initials: _initialsFor(name),
        name: name,
        badgeLabel: 'Verified producer',
        stats: [
          PortalHeroStat(
            value: '${summary.activeProjects}',
            label: 'Productions',
          ),
          PortalHeroStat(
            value: CineFormat.currency(
              summary.committedBudgetMinor ~/ 100,
              compact: true,
            ),
            label: 'Committed',
          ),
          PortalHeroStat(
            value: '${summary.securedBookings}',
            label: 'Bookings secured',
          ),
        ],
        ctaLabel: 'New Project',
        onCta: () => Navigator.pushNamed(
          context,
          DirectorProducerRoutes.createProject,
        ),
        secondaryIcon: Icons.chat_bubble_outline_rounded,
      ),
    );
  }
}

String _initialsFor(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
