import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/sections/admin_live_monitoring_section.dart';
import '../../../shared/sections/admin_quick_actions_section.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/cards/mini_trend_card.dart';
import '../data/director_producer_demo_data.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_action_required_strip.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_section_header.dart';
import '../widgets/dp_status_chip.dart';

class DPHomeDashboardScreen extends StatelessWidget {
  const DPHomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final projects = DirectorProducerDemoData.projects;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPSectionHeader(
          title: 'Action Required',
          icon: Icons.priority_high_rounded,
          actionText: 'New Project',
          onActionTap: () => Navigator.pushNamed(
              context, DirectorProducerRoutes.createProject),
        ),
        const SizedBox(height: 8),
        DPActionRequiredStrip(
          items: [
            DPActionRequiredItem(
              icon: Icons.draw_outlined,
              count: '3',
              title: 'Contracts to sign',
              timer: 'Due today',
              tone: DpTone.warning,
              onTap: () => Navigator.pushNamed(
                  context, DirectorProducerRoutes.contracts),
            ),
            DPActionRequiredItem(
              icon: Icons.upload_file_rounded,
              count: '4',
              title: 'Payments to upload',
              timer: 'Oldest 6h',
              tone: DpTone.danger,
              onTap: () =>
                  Navigator.pushNamed(context, DirectorProducerRoutes.payments),
            ),
            DPActionRequiredItem(
              icon: Icons.handshake_outlined,
              count: '6',
              title: 'Offers awaiting response',
              timer: '18h left',
              tone: DpTone.info,
              onTap: () => Navigator.pushNamed(
                  context, DirectorProducerRoutes.bargaining),
            ),
            DPActionRequiredItem(
              icon: Icons.timer_outlined,
              count: '2',
              title: 'Expiring negotiations',
              timer: 'Under 9h',
              tone: DpTone.warning,
              onTap: () => Navigator.pushNamed(
                  context, DirectorProducerRoutes.bargaining),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const PersonalDashboardKpiStrip(),
        const SizedBox(height: 14),
        AdminQuickActionsSection(
          items: [
            MetricActionItem(
              icon: Icons.movie_creation_outlined,
              value: '${projects.length}',
              title: 'Active Projects',
              subtitle: '+2 this week',
              accentColor: colors.infoBlue,
              onTap: () =>
                  Navigator.pushNamed(context, DirectorProducerRoutes.projects),
            ),
            MetricActionItem(
              icon: Icons.handshake_outlined,
              value: '${DirectorProducerDemoData.negotiations.length}',
              title: 'Negotiations',
              subtitle: '2 your move',
              accentColor: colors.infoPurple,
              onTap: () => Navigator.pushNamed(
                  context, DirectorProducerRoutes.bargaining),
            ),
            MetricActionItem(
              icon: Icons.article_outlined,
              value: '3',
              title: 'Pending Contracts',
              subtitle: 'Signature needed',
              accentColor: colors.goldMid,
              onTap: () => Navigator.pushNamed(
                  context, DirectorProducerRoutes.contracts),
            ),
            MetricActionItem(
              icon: Icons.payments_outlined,
              value: '5',
              title: 'Milestones Due',
              subtitle: 'PKR 1.2M',
              accentColor: colors.success,
              onTap: () =>
                  Navigator.pushNamed(context, DirectorProducerRoutes.payments),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DPTwoColumn(
          left: DPSectionCard(
            title: 'Active Projects',
            icon: Icons.movie_filter_outlined,
            actionText: 'View all',
            onActionTap: () =>
                Navigator.pushNamed(context, DirectorProducerRoutes.projects),
            child: Column(
              children: projects
                  .take(3)
                  .map(
                    (project) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onTap: () => Navigator.pushNamed(
                          context, DirectorProducerRoutes.projectDetail),
                      title: dpText(context, project.title, strong: true),
                      subtitle: dpText(
                          context, '${project.city} - ${project.status}'),
                      trailing: DPStatusChip(
                        label: '${project.pendingActions} actions',
                        tone: project.pendingActions > 7
                            ? DpTone.danger
                            : DpTone.success,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          right: DPSectionCard(
            title: 'Upcoming Shoot Days',
            icon: Icons.calendar_month_outlined,
            actionText: 'Schedule',
            onActionTap: () =>
                Navigator.pushNamed(context, DirectorProducerRoutes.schedule),
            child: Column(
              children: DirectorProducerDemoData.schedule
                  .take(5)
                  .map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: dpText(context, item.project, strong: true),
                      subtitle:
                          dpText(context, '${item.date} - ${item.location}'),
                      trailing: DPStatusChip(
                        label: item.status,
                        tone: item.conflict ? DpTone.danger : DpTone.success,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        AdminLiveMonitoringSection(
          title: 'Production Pulse',
          quiet: true,
          actionText: 'Reports',
          onActionTap: () =>
              Navigator.pushNamed(context, DirectorProducerRoutes.reports),
          metrics: [
            MiniTrendMetric(
              label: 'Bookings Locked',
              value: '41',
              trendValues: const [.2, .28, .24, .38, .48, .52, .62, .7],
              accentColor: colors.success,
            ),
            MiniTrendMetric(
              label: 'Budget Usage',
              value: '64%',
              trendValues: const [.15, .32, .35, .4, .48, .54, .6, .64],
              accentColor: colors.goldMid,
            ),
            MiniTrendMetric(
              label: 'Open Offers',
              value: '18',
              trendValues: const [.5, .42, .46, .52, .44, .38, .34, .3],
              accentColor: colors.infoPurple,
            ),
            MiniTrendMetric(
              label: 'Shoot Holds',
              value: '7',
              trendValues: const [.2, .25, .18, .28, .4, .36, .42, .5],
              accentColor: colors.infoBlue,
            ),
          ],
        ),
      ],
    );
  }
}
