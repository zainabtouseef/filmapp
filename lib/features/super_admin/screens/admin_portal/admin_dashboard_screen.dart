part of '../super_admin_screens.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(
          title: 'Quick Actions',
          icon: Icons.flash_on_rounded,
        ),
        const SizedBox(height: 8),
        DashboardMetricCards(
          onRouteTap: (route) => Navigator.pushNamed(context, route),
        ),
        const SizedBox(height: 12),
        _DashboardTwoColumn(
          left: _ActionFeedCard(
            onTap: (route) => Navigator.pushNamed(context, route),
          ),
          right: shared_queue.AdminQueueSnapshotSection(
            title: 'Queue Snapshot',
            items: [
              shared_queue.QueueSnapshotItem(
                icon: Icons.manage_accounts_outlined,
                title: 'KYC Queue',
                count: '12',
                status: 'On track',
                accentColor: colors.success,
              ),
              shared_queue.QueueSnapshotItem(
                icon: Icons.credit_card_rounded,
                title: 'Payments Queue',
                count: '18',
                status: 'Attention',
                accentColor: colors.infoPurple,
              ),
              shared_queue.QueueSnapshotItem(
                icon: Icons.gpp_maybe_outlined,
                title: 'Disputes Queue',
                count: '7',
                status: '1 High Value',
                accentColor: colors.goldMid,
              ),
            ],
            actionText: 'View all',
            onActionTap: () =>
                Navigator.pushNamed(context, SuperAdminRoutes.reviewHub),
          ),
        ),
        const SizedBox(height: 12),
        _LiveMonitoringCard(
          onTap: () => Navigator.pushNamed(context, SuperAdminRoutes.analytics),
        ),
        const SizedBox(height: 12),
        const _RecentActivityCard(),
      ],
    );
  }
}

class _DashboardTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _DashboardTwoColumn({
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _ActionFeedCard extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _ActionFeedCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return shared_action.AdminActionFeedSection(
      title: 'Action Feed',
      actionText: 'View all',
      onActionTap: () => onTap(SuperAdminRoutes.auditLogs),
      items: [
        shared_action.ActionFeedItem(
          label: 'High',
          title: 'Payment proof waiting',
          subtitle: '5h 20m - Assigned to Raamiz',
          accentColor: _dashboardToneColor(context, AdminDecisionTone.danger),
          onTap: () => onTap(SuperAdminRoutes.paymentReview),
        ),
        shared_action.ActionFeedItem(
          label: 'SLA',
          title: 'KYC request older than 24h',
          subtitle: '28m - Assigned to Ayesha',
          accentColor: _dashboardToneColor(context, AdminDecisionTone.warning),
          onTap: () => onTap(SuperAdminRoutes.verificationDetail),
        ),
        shared_action.ActionFeedItem(
          label: 'Critical',
          title: 'High-value dispute needs decision',
          subtitle: '2d - Assigned to Basit',
          accentColor: _dashboardToneColor(context, AdminDecisionTone.danger),
          onTap: () => onTap(SuperAdminRoutes.disputeCase),
        ),
      ],
    );
  }
}

class _LiveMonitoringCard extends StatelessWidget {
  final VoidCallback onTap;

  const _LiveMonitoringCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final metrics = [
      MiniTrendMetric(
        label: 'Active Users',
        value: '128',
        accentColor: colors.success,
        trendValues: const [
          0.18,
          0.22,
          0.2,
          0.27,
          0.36,
          0.35,
          0.56,
          0.42,
          0.47,
          0.44,
          0.51,
          0.47,
          0.45,
          0.62,
          0.5,
          0.56,
          0.72
        ],
      ),
      MiniTrendMetric(
        label: 'New Signups',
        value: '24',
        accentColor: colors.infoPurple,
        trendValues: const [
          0.14,
          0.18,
          0.13,
          0.21,
          0.32,
          0.23,
          0.24,
          0.29,
          0.45,
          0.28,
          0.42,
          0.5,
          0.55,
          0.67,
          0.58,
          0.72,
          0.82,
          0.61,
          0.55
        ],
      ),
      MiniTrendMetric(
        label: 'Transactions',
        value: '156',
        accentColor: colors.infoBlue,
        trendValues: const [
          0.16,
          0.2,
          0.17,
          0.22,
          0.3,
          0.25,
          0.28,
          0.26,
          0.44,
          0.31,
          0.4,
          0.47,
          0.49,
          0.56,
          0.72,
          0.63,
          0.69,
          0.9,
          0.68,
          0.58,
          0.72
        ],
      ),
      MiniTrendMetric(
        label: 'Success Rate',
        value: '97.2%',
        accentColor: colors.success,
        trendValues: const [
          0.18,
          0.22,
          0.18,
          0.24,
          0.32,
          0.29,
          0.36,
          0.27,
          0.5,
          0.37,
          0.48,
          0.55,
          0.58,
          0.72,
          0.56,
          0.6,
          0.69,
          0.66,
          0.58,
          0.72
        ],
      ),
    ];

    return AdminLiveMonitoringSection(
      title: 'Live Monitoring',
      actionText: 'Open',
      onActionTap: onTap,
      metrics: metrics,
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    return AdminRecentActivitySection(
      actionText: 'View all',
      items: [
        shared_action.ActionFeedItem(
          label: '11:32 AM',
          title: 'Payment approved',
          subtitle: 'PKR 1,250,000 - CineFlex Studios',
          icon: Icons.check_circle_outline,
          accentColor: _dashboardToneColor(context, AdminDecisionTone.success),
        ),
        shared_action.ActionFeedItem(
          label: '10:45 AM',
          title: 'KYC rejected',
          subtitle: 'Applicant ID: CNK-87421',
          icon: Icons.cancel_outlined,
          accentColor: _dashboardToneColor(context, AdminDecisionTone.danger),
        ),
        shared_action.ActionFeedItem(
          label: '09:18 AM',
          title: 'Contract template published',
          subtitle: 'Template: Talent Agreement v2.1',
          icon: Icons.description_outlined,
          accentColor: _dashboardToneColor(context, AdminDecisionTone.info),
        ),
      ],
    );
  }
}

Color _dashboardToneColor(BuildContext context, AdminDecisionTone tone) {
  final colors = context.appColors;
  return switch (tone) {
    AdminDecisionTone.success => colors.success,
    AdminDecisionTone.warning => colors.goldMid,
    AdminDecisionTone.info => colors.infoBlue,
    AdminDecisionTone.danger => colors.danger,
    AdminDecisionTone.neutral => colors.textSecondary,
  };
}
