part of '../super_admin_screens.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Future<_AdminDashboardData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_AdminDashboardData> _load() async {
    final results = await Future.wait<Object>([
      AnalyticsScope.of(context).adminDashboard(force: true),
      AdminScope.of(context).auditEvents(force: true),
    ]);
    return _AdminDashboardData(
      dashboard: results[0] as AdminDashboardDto,
      events: results[1] as List<AdminAuditEventDto>,
    );
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AdminDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SkeletonCard(height: 260);
        }
        if (snapshot.hasError || snapshot.data == null) {
          final error = snapshot.error;
          return AdminSurface(
            child: Column(
              children: [
                AdminEmptyState(
                  icon: Icons.monitor_heart_outlined,
                  title: 'Platform command data unavailable',
                  message: error is ApiException
                      ? error.message
                      : 'Check the backend connection and try again.',
                ),
                const SizedBox(height: 12),
                AdminActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Retry',
                  secondary: true,
                  onTap: _refresh,
                ),
              ],
            ),
          );
        }
        final data = snapshot.data!;
        final dashboard = data.dashboard;
        final openWork = dashboard.pendingKycCount +
            dashboard.pendingPaymentProofs +
            dashboard.pendingModerationCases +
            dashboard.openDisputes +
            dashboard.openSupportTickets;
        final queues = [
          _DashboardQueue(
            label: 'KYC Reviews',
            count: dashboard.pendingKycCount,
            route: SuperAdminRoutes.verifications,
            icon: Icons.verified_user_outlined,
            description: '${dashboard.oldestPendingKycHours.toStringAsFixed(1)}'
                'h oldest pending · identity checks',
          ),
          _DashboardQueue(
            label: 'Payment Proofs',
            count: dashboard.pendingPaymentProofs,
            route: SuperAdminRoutes.paymentQueue,
            icon: Icons.receipt_long_outlined,
            description: 'Finance verification queue.',
          ),
          _DashboardQueue(
            label: 'Moderation',
            count: dashboard.pendingModerationCases,
            route: SuperAdminRoutes.contentModeration,
            icon: Icons.policy_outlined,
            description: 'Trust and safety review queue.',
          ),
          _DashboardQueue(
            label: 'Disputes',
            count: dashboard.openDisputes,
            route: SuperAdminRoutes.disputes,
            icon: Icons.gavel_outlined,
            description: 'Open case files awaiting resolution.',
          ),
          _DashboardQueue(
            label: 'Support',
            count: dashboard.openSupportTickets,
            route: SuperAdminRoutes.support,
            icon: Icons.support_agent_outlined,
            description: 'Member service tickets open.',
          ),
        ];
        return PortalDashboardPage(
          children: [
            PortalHeroCard(
              initials: 'CC',
              name: 'Platform Command',
              badgeLabel: 'Super Admin',
              stats: [
                PortalHeroStat(value: '$openWork', label: 'Open actions'),
                PortalHeroStat(
                    value: '${dashboard.totalUsers}', label: 'Users'),
                PortalHeroStat(
                    value: '${dashboard.securedBookings}', label: 'Secured'),
              ],
              ctaLabel: 'Open review hub',
              onCta: () => Navigator.pushNamed(
                context,
                SuperAdminRoutes.reviewHub,
              ),
              secondaryIcon: Icons.refresh_rounded,
              onSecondary: _refresh,
            ),
            _AdminQueueGrid(
              queues: queues,
              onReviewHubTap: () => Navigator.pushNamed(
                context,
                SuperAdminRoutes.reviewHub,
              ),
            ),
            AdminSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSectionHeader(
                    title: 'Recent governed activity',
                    icon: Icons.history_rounded,
                    action: 'Open audit log',
                    onAction: () => Navigator.pushNamed(
                      context,
                      SuperAdminRoutes.auditLogs,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (data.events.isEmpty)
                    const AdminEmptyState(
                      icon: Icons.history_toggle_off_rounded,
                      title: 'No recent audit events',
                      message: 'Admin decisions will appear here.',
                    )
                  else
                    for (final event in data.events.take(6)) ...[
                      _DashboardEventRow(event: event),
                      if (event != data.events.take(6).last)
                        _reviewDivider(context),
                    ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminDashboardData {
  final AdminDashboardDto dashboard;
  final List<AdminAuditEventDto> events;

  const _AdminDashboardData({
    required this.dashboard,
    required this.events,
  });
}

class _DashboardQueue {
  final String label;
  final int count;
  final String route;
  final IconData icon;
  final String description;

  const _DashboardQueue({
    required this.label,
    required this.count,
    required this.route,
    required this.icon,
    required this.description,
  });
}

/// Operational queues presented as the shared cross-portal command centre.
class _AdminQueueGrid extends StatelessWidget {
  final List<_DashboardQueue> queues;
  final VoidCallback onReviewHubTap;

  const _AdminQueueGrid({
    required this.queues,
    required this.onReviewHubTap,
  });

  @override
  Widget build(BuildContext context) {
    final pending = queues.where((queue) => queue.count > 0).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    final priority = pending.isEmpty ? null : pending.first;
    return PortalCommandCenter(
      eyebrow: 'Platform operations',
      title: 'Review Command Centre',
      subtitle: 'Verification, finance, trust and member support queues.',
      icon: Icons.fact_check_outlined,
      primaryTitle: 'Review sequence',
      actionLabel: 'Open review hub',
      onAction: onReviewHubTap,
      primary: priority == null
          ? const AdminEmptyState(
              icon: Icons.task_alt_outlined,
              title: 'All operational queues are clear',
              message: 'New verification and support work will appear here.',
            )
          : Column(
              children: [
                PortalCommandDataRow(
                  icon: priority.icon,
                  label: 'Priority',
                  value: priority.label,
                ),
                PortalCommandDataRow(
                  icon: Icons.rule_folder_outlined,
                  label: 'Review scope',
                  value: priority.description,
                ),
                const PortalCommandDataRow(
                  icon: Icons.policy_outlined,
                  label: 'Decision rule',
                  value: 'Evidence first · record every action',
                ),
              ],
            ),
      actions: [
        for (final queue in queues)
          PortalCommandAction(
            icon: queue.icon,
            title: queue.label,
            subtitle: queue.description,
            value: '${queue.count}',
            onTap: () => Navigator.pushNamed(context, queue.route),
          ),
      ],
    );
  }
}

class _DashboardEventRow extends StatelessWidget {
  final AdminAuditEventDto event;

  const _DashboardEventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            Icons.fiber_manual_record,
            color: event.risk == 'high'
                ? context.appColors.danger
                : context.appColors.goldMid,
            size: 10,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _text(context, event.description, strong: true),
                _text(
                  context,
                  '${event.actor} · ${_adminDateTime(event.occurredAt)}',
                ),
              ],
            ),
          ),
          AdminRiskBadge(
            label: event.risk,
            risk: event.risk == 'high'
                ? AdminRiskTone.high
                : event.risk == 'medium'
                    ? AdminRiskTone.medium
                    : AdminRiskTone.low,
          ),
        ],
      ),
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
