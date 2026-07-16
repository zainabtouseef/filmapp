import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/distribution_partner_demo_data.dart';
import '../routes/distribution_partner_routes.dart';
import '../widgets/distribution_partner_components.dart';

class DS01DistributionDashboardScreen extends StatelessWidget {
  const DS01DistributionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = DistributionPartnerDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final project = store.primaryProject;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DistributionKpiRail(metrics: DistributionPartnerDemoData.metrics),
            const SizedBox(height: 12),
            DistributionTwoColumn(
              left: DistributionSectionCard(
                title: 'Release workload',
                icon: Icons.rocket_launch_outlined,
                selected: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DistributionMediaFrame(
                      imageUrl: project.imageUrl,
                      title: project.title,
                      badge: project.releaseWindow,
                      fallbackIcon: Icons.movie_filter_outlined,
                      aspectRatio: 16 / 8.5,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.metricNumberCompact.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        DistributionStatusChip(
                          status: store.projectStatus(project),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${project.producer} - ${project.territories} - ${project.statusNote}',
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
                          icon: Icons.event_available_outlined,
                          value: project.releaseWindow,
                          title: 'Window',
                          subtitle: 'Current',
                          accentColor: colors.goldDark,
                        ),
                        MetricActionItem(
                          icon: Icons.inventory_2_outlined,
                          value: '3 items',
                          title: 'Missing',
                          subtitle: 'Current',
                          accentColor: colors.goldDark,
                        ),
                        MetricActionItem(
                          icon: Icons.history_outlined,
                          value: '${store.auditEvents}',
                          title: 'Audit',
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
                            icon: Icons.contacts_outlined,
                            label: 'Contacts',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              DistributionPartnerRoutes.contacts,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CorePrimaryButton(
                            icon: Icons.rocket_launch_outlined,
                            label: 'Coordinate',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              DistributionPartnerRoutes.release,
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
                  DistributionSectionCard(
                    title: 'Action required',
                    icon: Icons.notifications_active_outlined,
                    child: store.activeTasks.isEmpty
                        ? CoreEmptyState(
                            icon: Icons.check_circle_outline,
                            title: 'Release queue clear',
                            message: 'No active distribution task is pending.',
                            actionLabel: 'Open reports',
                            onAction: () => Navigator.pushNamed(
                              context,
                              DistributionPartnerRoutes.reports,
                            ),
                          )
                        : DistributionTaskRail(tasks: store.activeTasks),
                  ),
                  const SizedBox(height: 12),
                  DistributionSectionCard(
                    title: 'Release health',
                    icon: Icons.analytics_outlined,
                    child: Column(
                      children: [
                        DistributionInfoRow(
                          icon: Icons.rocket_launch_outlined,
                          label: 'Near completion',
                          value: '7 projects',
                        ),
                        DistributionInfoRow(
                          icon: Icons.inventory_2_outlined,
                          label: 'Missing handover',
                          value: '3 projects',
                        ),
                        DistributionInfoRow(
                          icon: Icons.contacts_outlined,
                          label: 'Active partners',
                          value: '12 contacts',
                        ),
                        DistributionInfoRow(
                          icon: Icons.analytics_outlined,
                          label: 'Pending reports',
                          value: '4 records',
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
