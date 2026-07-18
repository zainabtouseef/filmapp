import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/brand_sponsor_demo_data.dart';
import '../routes/brand_sponsor_routes.dart';
import '../widgets/brand_sponsor_components.dart';

class BR01BrandDashboardScreen extends StatefulWidget {
  const BR01BrandDashboardScreen({super.key});

  @override
  State<BR01BrandDashboardScreen> createState() =>
      _BR01BrandDashboardScreenState();
}

class _BR01BrandDashboardScreenState extends State<BR01BrandDashboardScreen> {
  Future<List<BrandOpportunityDto>>? _opportunitiesFuture;
  Future<BrandProfileDto?>? _profileFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    _profileFuture ??= specialist?.brandProfile(force: true);
    _opportunitiesFuture ??= specialist?.brandOpportunities(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final store = BrandSponsorDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final opportunity = store.primaryOpportunity;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PersonalDashboardKpiStrip(),
            const SizedBox(height: 12),
            if (_profileFuture != null || _opportunitiesFuture != null)
              FutureBuilder<List<Object?>>(
                future: Future.wait<Object?>([
                  if (_profileFuture != null) _profileFuture!,
                  if (_opportunitiesFuture != null) _opportunitiesFuture!,
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: InlineNotice(
                        message: 'Loading live brand workspace...',
                        icon: Icons.hourglass_top_rounded,
                      ),
                    );
                  }
                  final values = snapshot.data ?? const [];
                  BrandProfileDto? profile;
                  List<BrandOpportunityDto> opportunities = const [];
                  for (final value in values) {
                    if (value is BrandProfileDto) profile = value;
                    if (value is List<BrandOpportunityDto>) {
                      opportunities = value;
                    }
                  }
                  if (profile == null && opportunities.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InlineNotice(
                      message:
                          'Live brand connected: ${profile?.name ?? 'profile pending'}, ${opportunities.length} opportunity/opportunities.',
                      icon: Icons.cloud_done_outlined,
                      tone: CoreStatusTone.success,
                    ),
                  );
                },
              ),
            BrandKpiRail(metrics: BrandSponsorDemoData.metrics),
            const SizedBox(height: 12),
            BrandTwoColumn(
              left: BrandSectionCard(
                title: 'Primary workload',
                icon: Icons.auto_awesome_motion_outlined,
                selected: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BrandMediaFrame(
                      imageUrl: opportunity.imageUrl,
                      title: opportunity.title,
                      badge: opportunity.category,
                      fallbackIcon: Icons.campaign_outlined,
                      aspectRatio: 16 / 8.5,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            opportunity.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.metricNumberCompact.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        BrandStatusChip(status: opportunity.status),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${opportunity.budget} - ${opportunity.usage} - ${opportunity.eligibility}',
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
                          value: opportunity.dueDate,
                          title: 'Close',
                          subtitle: 'Current',
                          accentColor: colors.goldDark,
                        ),
                        MetricActionItem(
                          icon: Icons.inbox_outlined,
                          value: '34 proposals',
                          title: 'Applications',
                          subtitle: 'Current',
                          accentColor: colors.goldDark,
                        ),
                        MetricActionItem(
                          icon: Icons.fact_check_outlined,
                          value: '1 risk',
                          title: 'Approval',
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
                            label: 'Applications',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              BrandSponsorRoutes.applications,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CorePrimaryButton(
                            icon: Icons.track_changes_outlined,
                            label: 'Track campaign',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              BrandSponsorRoutes.tracker,
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
                  BrandSectionCard(
                    title: 'Action required',
                    icon: Icons.notifications_active_outlined,
                    child: store.activeTasks.isEmpty
                        ? CoreEmptyState(
                            icon: Icons.check_circle_outline,
                            title: 'All caught up',
                            message: 'No sponsorship action is waiting.',
                            actionLabel: 'Create opportunity',
                            onAction: () => Navigator.pushNamed(
                              context,
                              BrandSponsorRoutes.composer,
                            ),
                          )
                        : BrandTaskRail(tasks: store.activeTasks),
                  ),
                  const SizedBox(height: 12),
                  BrandSectionCard(
                    title: 'Spend trend',
                    icon: Icons.bar_chart_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BrandMiniBarChart(
                          values: const [8, 12, 9, 16, 13, 19, 21],
                          colors: [
                            colors.goldMid,
                            colors.infoBlue,
                            colors.success,
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Applications, terms, proof approvals and payments refresh the same seeded sponsorship objects.',
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
