import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/dashboard/dashboard_kit.dart';
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

/// Live agency workspace body — dashboard-kit composition: hero → widget
/// grid (clock + commission ring) → audition pipeline + action-required
/// rail.
class _LiveAgencyDashboard extends StatelessWidget {
  final _AgencyDashboardData data;
  final VoidCallback onRefresh;

  const _LiveAgencyDashboard({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final activeAuditions = data.auditions
        .where((item) => item.status != 'closed' && item.status != 'rejected')
        .length;
    final paidCommissionMinor = data.commissions
        .where((item) => item.status == 'paid')
        .fold<int>(0, (sum, item) => sum + item.commissionMinor);
    final totalCommissionMinor = data.commissions
        .fold<int>(0, (sum, item) => sum + item.commissionMinor);
    final pendingCommissionMinor = totalCommissionMinor - paidCommissionMinor;
    final commissionProgress = totalCommissionMinor == 0
        ? 0.0
        : paidCommissionMinor / totalCommissionMinor;
    final selfTapeCount = data.auditions.fold<int>(
        0,
        (sum, item) =>
            sum +
            item.candidates
                .fold<int>(0, (inner, c) => inner + c.selfTapeCount));
    final pipelineAuditions = data.auditions.take(4).toList();

    return Column(
      children: [
        _AgencyHero(
          profile: data.profile,
          roster: data.roster,
          activeAuditions: activeAuditions,
          pendingCommissionMinor: pendingCommissionMinor,
          onRefresh: onRefresh,
        ),
        const SizedBox(height: 12),
        // Live clock + commission ring, cascading in as frosted-glass
        // widgets — replaces the old standalone ring card. No calendar
        // widget here: this dashboard has no real event/date data to back
        // one without fabricating it.
        PortalStaggeredReveal(
          children: [
            const PortalLiveClockWidget(),
            PortalGlassRingWidget(
              progress: commissionProgress,
              value: _money(paidCommissionMinor),
              label: 'Commission\ncollected',
              tone: CineTone.premium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AgencyTwoColumn(
          left: AgencySectionCard(
            title: 'Audition Pipeline',
            icon: Icons.auto_awesome_motion_outlined,
            actionText: 'View all',
            onActionTap: () =>
                Navigator.pushNamed(context, CastingAgencyRoutes.auditions),
            selected: pipelineAuditions.isNotEmpty,
            child: pipelineAuditions.isEmpty
                ? const CoreEmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No live audition requests',
                    message: 'Director audition requests will appear here.',
                  )
                : Column(
                    children: [
                      for (var i = 0; i < pipelineAuditions.length; i++)
                        _AuditionPipelineRow(
                          audition: pipelineAuditions[i],
                          showDivider: i != 0,
                        ),
                    ],
                  ),
          ),
          right: AgencySectionCard(
            title: 'Action required',
            icon: Icons.notifications_active_outlined,
            child: Column(
              children: [
                PortalAttentionRow(
                  kindLabel: 'Roster',
                  title: data.roster.isEmpty
                      ? 'Add represented talent'
                      : 'Roster ready · ${data.roster.length} talent',
                  meta: 'Manage represented talent profiles',
                  icon: Icons.person_add_alt_outlined,
                  tone: data.roster.isEmpty
                      ? CineTone.warning
                      : CineTone.positive,
                  onTap: () =>
                      Navigator.pushNamed(context, CastingAgencyRoutes.roster),
                ),
                const SizedBox(height: 10),
                PortalAttentionRow(
                  kindLabel: 'Self-tapes',
                  title: '$selfTapeCount received',
                  meta: 'Review submitted takes',
                  icon: Icons.video_collection_outlined,
                  tone: CineTone.information,
                  onTap: () => Navigator.pushNamed(
                      context, CastingAgencyRoutes.selfTapes),
                ),
                const SizedBox(height: 10),
                PortalAttentionRow(
                  kindLabel: 'Commissions',
                  title: '${data.commissions.length} records',
                  meta: pendingCommissionMinor > 0
                      ? '${_money(pendingCommissionMinor)} pending'
                      : 'All settled',
                  icon: Icons.receipt_long_outlined,
                  tone: pendingCommissionMinor > 0
                      ? CineTone.warning
                      : CineTone.positive,
                  onTap: () => Navigator.pushNamed(
                      context, CastingAgencyRoutes.commission),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Dashboard-kit hero: agency identity, roster/audition stats, and the
/// primary "open audition inbox" action. Refresh (previously only reachable
/// from the error state) is wired to the hero's secondary icon button.
class _AgencyHero extends StatelessWidget {
  final AgencyProfileDto? profile;
  final List<AgencyTalentDto> roster;
  final int activeAuditions;
  final int pendingCommissionMinor;
  final VoidCallback onRefresh;

  const _AgencyHero({
    required this.profile,
    required this.roster,
    required this.activeAuditions,
    required this.pendingCommissionMinor,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final name = (profile == null || profile!.name.trim().isEmpty)
        ? 'Agency'
        : profile!.name.trim();
    final badgeLabel = profile == null
        ? 'Profile pending'
        : _titleCase(profile!.verificationStatus);
    return PortalHeroCard(
      initials: _initialsFor(name),
      name: name,
      badgeLabel: badgeLabel,
      stats: [
        PortalHeroStat(value: '${roster.length}', label: 'Roster'),
        PortalHeroStat(value: '$activeAuditions', label: 'Active auditions'),
        PortalHeroStat(
          value: _money(pendingCommissionMinor),
          label: 'Pending commission',
        ),
      ],
      ctaLabel: 'Open audition inbox',
      onCta: () => Navigator.pushNamed(context, CastingAgencyRoutes.auditions),
      secondaryIcon: Icons.refresh_rounded,
      onSecondary: onRefresh,
    );
  }
}

/// One audition mapped onto the shared pipeline row — replaces the previous
/// single-item "primary workload" spotlight with a real multi-item list.
class _AuditionPipelineRow extends StatelessWidget {
  final AuditionDto audition;
  final bool showDivider;

  const _AuditionPipelineRow({
    required this.audition,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return PortalPipelineRow(
      initials: _initialsFor(audition.roleTitle),
      title: audition.roleTitle,
      subtitle: 'Project ${audition.projectId}',
      metaLabel: '${audition.candidates.length} candidate(s)',
      status: _titleCase(audition.status),
      tone: _auditionStatusTone(audition.status),
      ctaLabel: 'Review',
      onCta: () => Navigator.pushNamed(context, CastingAgencyRoutes.auditions),
      onTap: () => Navigator.pushNamed(context, CastingAgencyRoutes.auditions),
      showDivider: showDivider,
    );
  }
}

CineTone _auditionStatusTone(String status) {
  switch (status.toLowerCase()) {
    case 'closed':
      return CineTone.neutral;
    case 'rejected':
      return CineTone.critical;
    default:
      return CineTone.positive;
  }
}

String _initialsFor(String value) {
  final parts =
      value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  final cleaned = value.replaceAll('_', ' ');
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}

String _money(int minor) {
  final whole = minor ~/ 100;
  if (whole >= 100000) return 'PKR ${(whole / 1000).round()}k';
  return 'PKR $whole';
}
