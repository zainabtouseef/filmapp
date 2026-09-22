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
    setState(() => _future = _load());
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
            tone: CineTone.warning,
            description: '${dashboard.oldestPendingKycHours.toStringAsFixed(1)}'
                'h oldest pending · identity checks',
            actionLabel: 'Review',
          ),
          _DashboardQueue(
            label: 'Payment Proofs',
            count: dashboard.pendingPaymentProofs,
            route: SuperAdminRoutes.paymentQueue,
            icon: Icons.receipt_long_outlined,
            tone: CineTone.information,
            description: 'Finance verification queue.',
            actionLabel: 'Verify',
          ),
          _DashboardQueue(
            label: 'Moderation',
            count: dashboard.pendingModerationCases,
            route: SuperAdminRoutes.contentModeration,
            icon: Icons.policy_outlined,
            tone: CineTone.critical,
            description: 'Trust and safety review queue.',
            actionLabel: 'Moderate',
          ),
          _DashboardQueue(
            label: 'Disputes',
            count: dashboard.openDisputes,
            route: SuperAdminRoutes.disputes,
            icon: Icons.gavel_outlined,
            tone: CineTone.critical,
            description: 'Open case files awaiting resolution.',
            actionLabel: 'Resolve',
          ),
          _DashboardQueue(
            label: 'Support',
            count: dashboard.openSupportTickets,
            route: SuperAdminRoutes.support,
            icon: Icons.support_agent_outlined,
            tone: CineTone.warning,
            description: 'Member service tickets open.',
            actionLabel: 'Respond',
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AdminCommandHero(
              openWork: openWork,
              onReviewTap: () => Navigator.pushNamed(
                context,
                SuperAdminRoutes.reviewHub,
              ),
              onRefreshTap: _refresh,
            ),
            const SizedBox(height: 14),
            _AdminPulseStrip(dashboard: dashboard),
            const SizedBox(height: 14),
            _AdminQueueGrid(
              queues: queues,
              onReviewHubTap: () => Navigator.pushNamed(
                context,
                SuperAdminRoutes.reviewHub,
              ),
            ),
            const SizedBox(height: 14),
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

class _AdminCommandHero extends StatelessWidget {
  final int openWork;
  final VoidCallback onReviewTap;
  final VoidCallback onRefreshTap;

  const _AdminCommandHero({
    required this.openWork,
    required this.onReviewTap,
    required this.onRefreshTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 480;
    return SizedBox(
      width: double.infinity,
      height: compact ? 304 : 238,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.brandCampaignCover,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xE6111212),
                    Color(0xA6111212),
                    Color(0x35111212),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'LIVE PLATFORM COMMAND',
                        style: AppTextStyles.micro.copyWith(
                          color: const Color(0xFFFFD98A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        openWork == 0
                            ? 'All governed queues are clear.'
                            : '$openWork actions need review.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heroSerifHeadline.copyWith(
                          color: Colors.white,
                          fontSize: constraints.maxWidth < 480 ? 25 : 31,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Trust, money, safety and marketplace operations '
                        'from one verified control surface.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: onReviewTap,
                            icon: const Icon(Icons.fact_check_outlined),
                            label: const Text('Open review hub'),
                          ),
                          IconButton.filledTonal(
                            onPressed: onRefreshTap,
                            tooltip: 'Refresh dashboard',
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardQueue {
  final String label;
  final int count;
  final String route;
  final IconData icon;
  final CineTone tone;
  final String description;
  final String actionLabel;

  const _DashboardQueue({
    required this.label,
    required this.count,
    required this.route,
    required this.icon,
    required this.tone,
    required this.description,
    required this.actionLabel,
  });
}

/// Quick-stat row for the platform-health numbers — dashboard-kit's
/// [PortalQuickStatTile], matching the same shared component every other
/// portal's dashboard uses for its top-line metrics. Values are the exact
/// real figures the old [MetricStrip] rendered; only the presentation
/// changed. Deltas are honest neutral labels (no trend data is computed
/// for these platform totals), same convention as the DP portal's pulse
/// strip.
class _AdminPulseStrip extends StatelessWidget {
  final AdminDashboardDto dashboard;

  const _AdminPulseStrip({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      PortalQuickStatTile(
        icon: Icons.groups_2_outlined,
        value: '${dashboard.totalUsers}',
        label: 'Platform users',
        delta: 'Live now',
        tone: CineTone.positive,
        onTap: () => Navigator.pushNamed(context, SuperAdminRoutes.users),
      ),
      PortalQuickStatTile(
        icon: Icons.lock_outline_rounded,
        value: '${dashboard.securedBookings}',
        label: 'Secured bookings',
        delta: 'This cycle',
        tone: CineTone.information,
        onTap: () =>
            Navigator.pushNamed(context, SuperAdminRoutes.bookingsMonitor),
      ),
      PortalQuickStatTile(
        icon: Icons.percent_rounded,
        value: '${(dashboard.conversionRate * 100).toStringAsFixed(1)}%',
        label: 'Conversion',
        delta: 'This cycle',
        tone: CineTone.positive,
        onTap: () => Navigator.pushNamed(context, SuperAdminRoutes.analytics),
      ),
      PortalQuickStatTile(
        icon: Icons.account_balance_wallet_outlined,
        value: 'PKR ${_adminMoney(
          dashboard.calculatedPlatformFeesMinor ~/ 100,
        )}',
        label: 'Calculated fees',
        delta: 'This cycle',
        tone: CineTone.warning,
        onTap: () => Navigator.pushNamed(context, SuperAdminRoutes.fees),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 9.0;
        final columns = constraints.maxWidth < 360
            ? 1
            : constraints.maxWidth < 700
                ? 2
                : 4;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

/// Operational-queues grid — dashboard-kit's [PortalModuleCard], replacing
/// the bespoke [_DashboardQueueCard] left-bar tile with the same shortcut
/// card shape every other portal's "modules" grid uses. Counts and routes
/// are unchanged from the original queue cards; a zero count omits the
/// badge instead of showing a "0" (same convention as the DP portal's
/// module grid) since [PortalModuleCard] has no separate cleared-queue
/// indicator dot.
class _AdminQueueGrid extends StatelessWidget {
  final List<_DashboardQueue> queues;
  final VoidCallback onReviewHubTap;

  const _AdminQueueGrid({
    required this.queues,
    required this.onReviewHubTap,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'Operational queues',
            icon: Icons.fact_check_outlined,
            action: 'Review hub',
            onAction: onReviewHubTap,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpacing.md;
              final columns = (constraints.maxWidth / 216).floor().clamp(1, 3);
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final queue in queues)
                    SizedBox(
                      width: width,
                      child: PortalModuleCard(
                        icon: queue.icon,
                        name: queue.label,
                        count: queue.count > 0 ? queue.count : null,
                        description: queue.description,
                        actionLabel: queue.actionLabel,
                        tone: queue.tone,
                        onTap: () => Navigator.pushNamed(context, queue.route),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
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
