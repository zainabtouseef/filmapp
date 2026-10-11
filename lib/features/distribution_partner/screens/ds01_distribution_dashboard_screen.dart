import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/dashboard/dashboard_kit.dart';
import '../../../shared/widgets/marketplace_pricing_preference_panel.dart';
import '../routes/distribution_partner_routes.dart';

class DS01DistributionDashboardScreen extends StatefulWidget {
  const DS01DistributionDashboardScreen({super.key});

  @override
  State<DS01DistributionDashboardScreen> createState() =>
      _DS01DistributionDashboardScreenState();
}

class _DS01DistributionDashboardScreenState
    extends State<DS01DistributionDashboardScreen> {
  Future<_DistributionDashboardData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_DistributionDashboardData>? _load() {
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null) return null;
    return _DistributionDashboardData.load(specialist);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return const PortalDashboardPage(
        showLiveStrip: false,
        children: [
          CoreEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in to load distribution data',
            message:
                'Distribution projects, contacts and reports are loaded from the server.',
          ),
        ],
      );
    }

    return FutureBuilder<_DistributionDashboardData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PortalDashboardPage(
            showLiveStrip: false,
            children: [SkeletonCard(height: 420)],
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return PortalDashboardPage(
            showLiveStrip: false,
            children: [
              Column(
                children: [
                  const CoreEmptyState(
                    icon: Icons.sync_problem_outlined,
                    title: 'Could not load distribution workspace',
                    message: 'Check your connection and try again.',
                  ),
                  const SizedBox(height: 10),
                  CoreSecondaryButton(
                    icon: Icons.refresh_rounded,
                    label: 'Try again',
                    compact: true,
                    onTap: _refresh,
                  ),
                ],
              ),
            ],
          );
        }
        return _LiveDistributionDashboard(
          data: snapshot.data!,
          onRefresh: _refresh,
        );
      },
    );
  }
}

class _DistributionDashboardData {
  final DistributionProfileDto? profile;
  final List<DistributionProjectDto> projects;
  final List<DistributorContactDto> contacts;
  final List<DistributionReportDto> reports;

  const _DistributionDashboardData({
    required this.profile,
    required this.projects,
    required this.contacts,
    required this.reports,
  });

  static Future<_DistributionDashboardData> load(
    SpecialistController specialist,
  ) async {
    final profile = await specialist.distributionProfile(force: true);
    final results = await Future.wait<Object>([
      specialist.distributionProjects(force: true),
      specialist.distributorContacts(force: true),
      specialist.distributionReports(force: true),
    ]);
    return _DistributionDashboardData(
      profile: profile,
      projects: results[0] as List<DistributionProjectDto>,
      contacts: results[1] as List<DistributorContactDto>,
      reports: results[2] as List<DistributionReportDto>,
    );
  }
}

/// Live distribution workspace with role metrics in the shared hero and
/// release operations in the shared command-centre surface.
class _LiveDistributionDashboard extends StatelessWidget {
  final _DistributionDashboardData data;
  final VoidCallback onRefresh;

  const _LiveDistributionDashboard({
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final activeProjects = data.projects
        .where((item) => item.status != 'closed' && item.status != 'completed')
        .length;
    final audience =
        data.reports.fold<int>(0, (sum, item) => sum + item.audienceCount);
    final revenue =
        data.reports.fold<int>(0, (sum, item) => sum + item.revenueMinor);
    final primary = data.projects.isEmpty ? null : data.projects.first;

    final displayName = AuthScope.maybeOf(context)?.user?.displayName;
    final name = (displayName == null || displayName.trim().isEmpty)
        ? 'Distribution partner'
        : displayName.trim();

    return PortalDashboardPage(
      children: [
        PortalHeroCard(
          initials: _initialsFor(name),
          name: name,
          badgeLabel: 'Verified partner',
          stats: [
            PortalHeroStat(value: '$activeProjects', label: 'Active projects'),
            PortalHeroStat(value: _money(revenue), label: 'Revenue'),
            PortalHeroStat(value: '$audience', label: 'Audience'),
          ],
          ctaLabel: 'Refresh',
          onCta: onRefresh,
        ),
        const PortalStaggeredReveal(
          children: [PortalLiveClockWidget()],
        ),
        const MarketplacePricingPreferencePanel(
          listingTypes: {'distribution'},
          title: 'Distribution marketplace pricing',
        ),
        PortalCommandCenter(
          eyebrow: 'Distribution operations',
          title: 'Release Command Centre',
          subtitle: 'Territories, handovers and performance in one live view.',
          icon: Icons.public_outlined,
          primaryTitle:
              primary == null ? 'Release overview' : 'Primary release',
          actionLabel: 'Open releases',
          onAction: () => Navigator.pushNamed(
            context,
            DistributionPartnerRoutes.release,
          ),
          primary: primary == null
              ? const CoreEmptyState(
                  icon: Icons.movie_creation_outlined,
                  title: 'No live distribution projects',
                  message: 'Release projects will appear here.',
                )
              : Column(
                  children: [
                    PortalCommandDataRow(
                      icon: Icons.movie_filter_outlined,
                      label: 'Project',
                      value: primary.projectId,
                    ),
                    PortalCommandDataRow(
                      icon: Icons.public_outlined,
                      label: 'Territories',
                      value: primary.territories ?? 'Not set',
                    ),
                    PortalCommandDataRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Handover',
                      value: '${primary.handoverCount} items',
                    ),
                    PortalCommandDataRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Windows',
                      value: '${primary.releaseWindowCount} scheduled',
                    ),
                  ],
                ),
          actions: [
            PortalCommandAction(
              icon: Icons.contacts_outlined,
              title: 'Distributor contacts',
              subtitle: 'Manage outreach and partner records',
              value: '${data.contacts.length}',
              onTap: () => Navigator.pushNamed(
                context,
                DistributionPartnerRoutes.contacts,
              ),
            ),
            PortalCommandAction(
              icon: Icons.handshake_outlined,
              title: 'Release coordination',
              subtitle: 'Review windows and handover checklists',
              value: '${data.projects.length}',
              onTap: () => Navigator.pushNamed(
                context,
                DistributionPartnerRoutes.release,
              ),
            ),
            PortalCommandAction(
              icon: Icons.analytics_outlined,
              title: 'Performance reports',
              subtitle: 'Audience and revenue performance',
              value: '${data.reports.length}',
              onTap: () => Navigator.pushNamed(
                context,
                DistributionPartnerRoutes.reports,
              ),
            ),
          ],
        ),
      ],
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

String _money(int minor) {
  final whole = minor ~/ 100;
  if (whole >= 100000) return 'PKR ${(whole / 1000).round()}k';
  return 'PKR $whole';
}
