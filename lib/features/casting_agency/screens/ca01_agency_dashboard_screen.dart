import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/casting_agency_demo_data.dart';
import '../routes/casting_agency_routes.dart';
import '../widgets/casting_agency_components.dart';

class CA01AgencyDashboardScreen extends StatefulWidget {
  const CA01AgencyDashboardScreen({super.key});

  @override
  State<CA01AgencyDashboardScreen> createState() =>
      _CA01AgencyDashboardScreenState();
}

class _CA01AgencyDashboardScreenState extends State<CA01AgencyDashboardScreen> {
  Future<List<AuditionDto>>? _auditionsFuture;
  Future<AgencyProfileDto?>? _profileFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    _profileFuture ??= specialist?.agencyProfile(force: true);
    _auditionsFuture ??= specialist?.auditions(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final store = CastingAgencyDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final selected = store.selectedAudition;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PersonalDashboardKpiStrip(),
            const SizedBox(height: 12),
            if (_profileFuture != null || _auditionsFuture != null)
              FutureBuilder<List<Object?>>(
                future: Future.wait<Object?>([
                  if (_profileFuture != null) _profileFuture!,
                  if (_auditionsFuture != null) _auditionsFuture!,
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: InlineNotice(
                        message: 'Loading live agency workspace...',
                        icon: Icons.hourglass_top_rounded,
                      ),
                    );
                  }
                  final values = snapshot.data ?? const [];
                  AgencyProfileDto? profile;
                  List<AuditionDto> auditions = const [];
                  for (final value in values) {
                    if (value is AgencyProfileDto) profile = value;
                    if (value is List<AuditionDto>) auditions = value;
                  }
                  if (profile == null && auditions.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InlineNotice(
                      message:
                          'Live agency connected: ${profile?.name ?? 'profile pending'}, ${auditions.length} audition request(s).',
                      icon: Icons.cloud_done_outlined,
                      tone: CoreStatusTone.success,
                    ),
                  );
                },
              ),
            AgencyKpiRail(metrics: CastingAgencyDemoData.metrics),
            const SizedBox(height: 12),
            AgencyTwoColumn(
              left: AgencySectionCard(
                title: 'Primary workload',
                icon: Icons.auto_awesome_motion_outlined,
                selected: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AgencyMediaFrame(
                      imageUrl: selected.imageUrl,
                      title: selected.project,
                      badge: selected.city,
                      fallbackIcon: Icons.local_activity_outlined,
                      aspectRatio: 16 / 8.5,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected.project,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.metricNumberCompact.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        AgencyStatusChip(
                            status: store.auditionStatus(selected)),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${selected.director} - ${selected.role}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    MetricActionRail(
                      items: [
                        MetricActionItem(
                          icon: Icons.schedule_outlined,
                          value: selected.dueDate,
                          title: 'Deadline',
                          subtitle: 'Current',
                          accentColor: colors.goldDark,
                        ),
                        MetricActionItem(
                          icon: Icons.payments_outlined,
                          value: selected.budget,
                          title: 'Budget',
                          subtitle: 'Current',
                          accentColor: colors.goldDark,
                        ),
                        MetricActionItem(
                          icon: Icons.group_add_outlined,
                          value: '${store.submittedShortlists} sent',
                          title: 'Shortlists',
                          subtitle: 'Current',
                          accentColor: colors.goldDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CoreSecondaryButton(
                            icon: Icons.inbox_outlined,
                            label: 'Open request',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              CastingAgencyRoutes.auditions,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CorePrimaryButton(
                            icon: Icons.view_kanban_outlined,
                            label: 'Build shortlist',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              CastingAgencyRoutes.shortlist,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              right: Column(
                children: [
                  AgencySectionCard(
                    title: 'Action required',
                    icon: Icons.notifications_active_outlined,
                    child: store.activeTasks.isEmpty
                        ? CoreEmptyState(
                            icon: Icons.check_circle_outline,
                            title: 'All caught up',
                            message: 'No agency action is waiting right now.',
                            actionLabel: 'View roster',
                            onAction: () => Navigator.pushNamed(
                              context,
                              CastingAgencyRoutes.roster,
                            ),
                          )
                        : AgencyTaskRail(tasks: store.activeTasks),
                  ),
                  const SizedBox(height: 12),
                  AgencySectionCard(
                    title: 'Audition trend',
                    icon: Icons.bar_chart_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AgencyMiniBarChart(
                          values: const [8, 11, 9, 14, 12, 16, 18],
                          colors: [
                            colors.goldMid,
                            colors.infoBlue,
                            colors.success,
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Requests, submissions and agency-closed bookings share one demo state across the portal.',
                          style: AppTextStyles.smallMeta.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
