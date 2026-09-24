import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/dashboard/dashboard_kit.dart';
import '../../../shared/widgets/marketplace_pricing_preference_panel.dart';
import '../routes/distribution_partner_routes.dart';
import '../widgets/distribution_partner_components.dart';

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
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PersonalDashboardKpiStrip(),
        const SizedBox(height: 12),
        const MarketplacePricingPreferencePanel(
          listingTypes: {'distribution'},
          title: 'Distribution marketplace pricing',
        ),
        const SizedBox(height: 12),
        if (_future == null)
          const DistributionSectionCard(
            title: 'Distribution Workspace',
            icon: Icons.lock_outline_rounded,
            child: CoreEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to load distribution data',
              message:
                  'Distribution profile, release projects, contacts, and reports are loaded from the server.',
            ),
          )
        else
          FutureBuilder<_DistributionDashboardData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonCard(height: 420);
              }
              if (snapshot.hasError || snapshot.data == null) {
                return DistributionSectionCard(
                  title: 'Distribution workspace unavailable',
                  icon: Icons.cloud_off_outlined,
                  child: Column(
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
                );
              }
              return _LiveDistributionDashboard(
                data: snapshot.data!,
                onRefresh: _refresh,
              );
            },
          ),
      ],
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

/// Live distribution workspace: dashboard-kit hero (partner identity +
/// active projects/revenue), a quick-stat tile row for the same live
/// figures, then the primary-release detail alongside a "Next actions"
/// module-card grid replacing the old plain button list.
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

    return Column(
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
        const SizedBox(height: 12),
        const PortalStaggeredReveal(
          children: [PortalLiveClockWidget()],
        ),
        const SizedBox(height: 12),
        DistributionTwoColumn(
          left: DistributionSectionCard(
            title: 'Primary release',
            icon: Icons.rocket_launch_outlined,
            selected: primary != null,
            actionText: 'Refresh',
            onActionTap: onRefresh,
            child: primary == null
                ? const CoreEmptyState(
                    icon: Icons.movie_creation_outlined,
                    title: 'No live distribution projects',
                    message: 'Release projects will appear here.',
                  )
                : Column(
                    children: [
                      DistributionInfoRow(
                        icon: Icons.movie_filter_outlined,
                        label: 'Project',
                        value: primary.projectId,
                      ),
                      DistributionInfoRow(
                        icon: Icons.public_outlined,
                        label: 'Territories',
                        value: primary.territories ?? 'Not set',
                      ),
                      DistributionInfoRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Handover items',
                        value: '${primary.handoverCount}',
                      ),
                      DistributionInfoRow(
                        icon: Icons.calendar_month_outlined,
                        label: 'Release windows',
                        value: '${primary.releaseWindowCount}',
                      ),
                    ],
                  ),
          ),
          right: DistributionSectionCard(
            title: 'Next actions',
            icon: Icons.route_outlined,
            child: DistributionResponsiveGrid(
              minWidth: 200,
              children: [
                PortalModuleCard(
                  icon: Icons.contacts_outlined,
                  name: 'Contacts',
                  count: data.contacts.isEmpty ? null : data.contacts.length,
                  description: 'Distributor contacts and outreach records.',
                  actionLabel: 'Open contacts',
                  tone: CineTone.information,
                  onTap: () => Navigator.pushNamed(
                      context, DistributionPartnerRoutes.contacts),
                ),
                PortalModuleCard(
                  icon: Icons.handshake_outlined,
                  name: 'Coordination',
                  count: data.projects.isEmpty ? null : data.projects.length,
                  description: 'Release windows and handover checklists.',
                  actionLabel: 'Open coordination',
                  tone: CineTone.premium,
                  onTap: () => Navigator.pushNamed(
                      context, DistributionPartnerRoutes.release),
                ),
                PortalModuleCard(
                  icon: Icons.analytics_outlined,
                  name: 'Reports',
                  count: data.reports.isEmpty ? null : data.reports.length,
                  description: 'Audience and revenue performance.',
                  actionLabel: 'Open reports',
                  tone: CineTone.warning,
                  onTap: () => Navigator.pushNamed(
                      context, DistributionPartnerRoutes.reports),
                ),
              ],
            ),
          ),
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
