import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../routes/casting_agency_routes.dart';
import '../widgets/casting_agency_components.dart';

class CA01AgencyDashboardScreen extends StatefulWidget {
  const CA01AgencyDashboardScreen({super.key});

  @override
  State<CA01AgencyDashboardScreen> createState() =>
      _CA01AgencyDashboardScreenState();
}

class _CA01AgencyDashboardScreenState extends State<CA01AgencyDashboardScreen> {
  Future<_AgencyDashboardData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_AgencyDashboardData>? _load() {
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null) return null;
    return _AgencyDashboardData.load(specialist);
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
        if (_future == null)
          const AgencySectionCard(
            title: 'Agency Workspace',
            icon: Icons.lock_outline_rounded,
            child: CoreEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to load agency data',
              message:
                  'Agency profile, auditions, roster, and commission records are loaded from the server.',
            ),
          )
        else
          FutureBuilder<_AgencyDashboardData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonCard(height: 420);
              }
              if (snapshot.hasError || snapshot.data == null) {
                return AgencySectionCard(
                  title: 'Agency workspace unavailable',
                  icon: Icons.cloud_off_outlined,
                  child: Column(
                    children: [
                      const CoreEmptyState(
                        icon: Icons.sync_problem_outlined,
                        title: 'Could not load agency workspace',
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
              return _LiveAgencyDashboard(
                  data: snapshot.data!, onRefresh: _refresh);
            },
          ),
      ],
    );
  }
}

class _AgencyDashboardData {
  final AgencyProfileDto? profile;
  final List<AgencyTalentDto> roster;
  final List<AuditionDto> auditions;
  final List<AgencyCommissionDto> commissions;

  const _AgencyDashboardData({
    required this.profile,
    required this.roster,
    required this.auditions,
    required this.commissions,
  });

  static Future<_AgencyDashboardData> load(
      SpecialistController specialist) async {
    final profile = await specialist.agencyProfile(force: true);
    final results = await Future.wait<Object>([
      specialist.agencyRoster(force: true),
      specialist.auditions(force: true),
      specialist.agencyCommissions(force: true),
    ]);
    return _AgencyDashboardData(
      profile: profile,
      roster: results[0] as List<AgencyTalentDto>,
      auditions: results[1] as List<AuditionDto>,
      commissions: results[2] as List<AgencyCommissionDto>,
    );
  }
}

class _LiveAgencyDashboard extends StatelessWidget {
  final _AgencyDashboardData data;
  final VoidCallback onRefresh;

  const _LiveAgencyDashboard({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final profile = data.profile;
    final activeAuditions = data.auditions
        .where((item) => item.status != 'closed' && item.status != 'rejected')
        .length;
    final pendingCommissionMinor = data.commissions
        .where((item) => item.status != 'paid')
        .fold<int>(0, (sum, item) => sum + item.commissionMinor);
    final primary = data.auditions.isEmpty ? null : data.auditions.first;
    return Column(
      children: [
        AgencyResponsiveGrid(
          minWidth: 220,
          children: [
            _MetricTile(
              icon: Icons.business_center_outlined,
              label: 'Agency',
              value: profile?.name ?? 'Profile pending',
              color: colors.goldMid,
            ),
            _MetricTile(
              icon: Icons.people_alt_outlined,
              label: 'Roster',
              value: '${data.roster.length}',
              color: colors.infoBlue,
            ),
            _MetricTile(
              icon: Icons.local_activity_outlined,
              label: 'Active auditions',
              value: '$activeAuditions',
              color: colors.success,
            ),
            _MetricTile(
              icon: Icons.payments_outlined,
              label: 'Pending commission',
              value: _money(pendingCommissionMinor),
              color: colors.infoPurple,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AgencyTwoColumn(
          left: AgencySectionCard(
            title: 'Primary workload',
            icon: Icons.auto_awesome_motion_outlined,
            actionText: 'Refresh',
            onActionTap: onRefresh,
            selected: primary != null,
            child: primary == null
                ? const CoreEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No live audition requests',
                    message: 'Director audition requests will appear here.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AgencyInfoRow(
                        icon: Icons.local_activity_outlined,
                        label: 'Project',
                        value: primary.projectId,
                      ),
                      AgencyInfoRow(
                        icon: Icons.theater_comedy_outlined,
                        label: 'Role',
                        value: primary.roleTitle,
                      ),
                      AgencyInfoRow(
                        icon: Icons.payments_outlined,
                        label: 'Budget',
                        value: primary.budgetMinor == null
                            ? 'Budget TBD'
                            : _money(primary.budgetMinor!),
                      ),
                      AgencyInfoRow(
                        icon: Icons.group_outlined,
                        label: 'Candidates',
                        value: '${primary.candidates.length}',
                      ),
                      const SizedBox(height: 10),
                      CorePrimaryButton(
                        icon: Icons.inbox_outlined,
                        label: 'Open audition inbox',
                        compact: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          CastingAgencyRoutes.auditions,
                        ),
                      ),
                    ],
                  ),
          ),
          right: AgencySectionCard(
            title: 'Action required',
            icon: Icons.notifications_active_outlined,
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.person_add_alt_outlined,
                  label: 'Roster management',
                  value: data.roster.isEmpty
                      ? 'Add represented talent'
                      : 'Live roster ready',
                  route: CastingAgencyRoutes.roster,
                ),
                _ActionRow(
                  icon: Icons.video_collection_outlined,
                  label: 'Self-tapes',
                  value:
                      '${data.auditions.fold<int>(0, (sum, item) => sum + item.candidates.fold<int>(0, (inner, candidate) => inner + candidate.selfTapeCount))} received',
                  route: CastingAgencyRoutes.selfTapes,
                ),
                _ActionRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Commissions',
                  value: '${data.commissions.length} records',
                  route: CastingAgencyRoutes.commission,
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
