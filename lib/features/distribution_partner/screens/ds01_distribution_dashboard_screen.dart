import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/cards/metric_action_card.dart';
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

class _LiveDistributionDashboard extends StatelessWidget {
  final _DistributionDashboardData data;
  final VoidCallback onRefresh;

  const _LiveDistributionDashboard({
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final activeProjects = data.projects
        .where((item) => item.status != 'closed' && item.status != 'completed')
        .length;
    final audience =
        data.reports.fold<int>(0, (sum, item) => sum + item.audienceCount);
    final revenue =
        data.reports.fold<int>(0, (sum, item) => sum + item.revenueMinor);
    final primary = data.projects.isEmpty ? null : data.projects.first;
    return Column(
      children: [
        DistributionResponsiveGrid(
          minWidth: 220,
          children: [
            _MetricTile(
              icon: Icons.hub_outlined,
              label: 'Partner',
              value: data.profile?.name ?? 'Profile pending',
              color: colors.goldMid,
            ),
            _MetricTile(
              icon: Icons.movie_filter_outlined,
              label: 'Active projects',
              value: '$activeProjects',
              color: colors.infoBlue,
            ),
            _MetricTile(
              icon: Icons.people_alt_outlined,
              label: 'Audience',
              value: '$audience',
              color: colors.success,
            ),
            _MetricTile(
              icon: Icons.payments_outlined,
              label: 'Revenue',
              value: _money(revenue),
              color: colors.infoPurple,
            ),
          ],
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
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.contacts_outlined,
                  label: 'Contacts',
                  value: '${data.contacts.length}',
                  route: DistributionPartnerRoutes.contacts,
                ),
                _ActionRow(
                  icon: Icons.handshake_outlined,
                  label: 'Coordination',
                  value: '${data.projects.length} projects',
                  route: DistributionPartnerRoutes.release,
                ),
                _ActionRow(
                  icon: Icons.analytics_outlined,
                  label: 'Reports',
                  value: '${data.reports.length}',
                  route: DistributionPartnerRoutes.reports,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return MetricActionCard(
      item: MetricActionItem(
        icon: icon,
        value: value,
        title: label,
        subtitle: 'Live database',
        accentColor: color,
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String route;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CoreSecondaryButton(
        icon: icon,
        label: '$label · $value',
        compact: true,
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}

String _money(int minor) {
  final whole = minor ~/ 100;
  if (whole >= 100000) return 'PKR ${(whole / 1000).round()}k';
  return 'PKR $whole';
}
