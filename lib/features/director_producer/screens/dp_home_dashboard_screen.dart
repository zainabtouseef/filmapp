import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/director/director_dashboard_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_target.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/dashboard/dashboard_kit.dart';
import '../../../shared/formatters/cine_format.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dashboard/dp_command_header.dart';
import '../widgets/dashboard/dp_deal_pipeline.dart';
import '../widgets/dashboard/dp_financial_centre.dart';
import '../widgets/dashboard/dp_mini_calendar_section.dart';
import '../widgets/dashboard/dp_priority_actions.dart';
import '../widgets/dashboard/dp_project_deck.dart';
import '../widgets/dashboard/dp_today_timeline.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_layout_helpers.dart';

/// The Director/Producer command dashboard — a compact, cinematic
/// production-management console. Mobile gets a single scrolling
/// column; desktop splits into a dominant operational column plus a
/// contextual side rail, alongside the shell's own nav rail/top bar.
class DPHomeDashboardScreen extends StatefulWidget {
  const DPHomeDashboardScreen({super.key});

  @override
  State<DPHomeDashboardScreen> createState() => _DPHomeDashboardScreenState();
}

class _DPHomeDashboardScreenState extends State<DPHomeDashboardScreen> {
  Future<DirectorDashboard>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<DirectorDashboard> _load() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      throw const ApiException(
        code: 'auth.required',
        message: 'Sign in to load the live Director dashboard.',
      );
    }
    return auth.directorDashboard();
  }

  void _retry() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DirectorDashboard>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _DashboardLoadingState();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          final message = snapshot.error is ApiException
              ? (snapshot.error! as ApiException).message
              : 'Could not load the live Director dashboard.';
          return _DashboardErrorState(message: message, onRetry: _retry);
        }
        final dashboard = snapshot.data!;
        final displayName = AuthScope.maybeOf(context)?.user?.displayName;
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= AppBreakpoints.tablet;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DPCommandHeader(
                  summary: dashboard.summary,
                  displayName: displayName,
                ),
                const SizedBox(height: 14),
                _WidgetGridSection(dashboard: dashboard),
                const SizedBox(height: 14),
                _ModulesSection(dashboard: dashboard),
                const SizedBox(height: 14),
                if (wide)
                  _WideBody(dashboard: dashboard)
                else
                  _CompactBody(dashboard: dashboard),
              ],
            );
          },
        );
      },
    );
  }
}

/// macOS-widget-style grid: a live clock + payments ring (with an
/// animated glow filling the space beneath their shorter pair), the mini
/// calendar (real event dates from `dashboard.timeline`), and a preview
/// of today's real production pipeline — all frosted-glass, fixed-size
/// widgets that cascade in together, rather than full-width stat cards.
class _WidgetGridSection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _WidgetGridSection({required this.dashboard});

  static const _clockRingWidth = 168.0 * 2 + 14;
  static const _calendarWidth = 340.0;
  static const _calendarPipelineWidth = _calendarWidth * 2 + 14;

  /// Below this, there's room for both groups side by side exactly as
  /// designed — nothing changes from the wide desktop layout.
  static const _sideBySideThreshold =
      _clockRingWidth + 14 + _calendarPipelineWidth;

  /// Below this, even a single row of calendar + pipeline is too tight;
  /// they stack instead of squeezing pipeline into a sliver.
  static const _calendarRowThreshold = 420.0;

  @override
  Widget build(BuildContext context) {
    final summary = dashboard.summary;
    final paid = summary.paidMinor ~/ 100;
    final pending = summary.pendingPaymentMinor ~/ 100;
    final total = paid + pending;
    final progress = total == 0 ? 0.0 : paid / total;

    final now = DateTime.now();
    final todayEvents = dashboard.timeline.where((event) {
      final startsAt = event.startsAt;
      return startsAt != null &&
          startsAt.year == now.year &&
          startsAt.month == now.month &&
          startsAt.day == now.day;
    }).toList()
      ..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));

    final clockRingRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PortalLiveClockWidget(),
        const SizedBox(width: 14),
        PortalGlassRingWidget(
          progress: progress,
          value: CineFormat.currency(paid, compact: true),
          label: 'Payments cleared\nthis cycle',
          tone: CineTone.premium,
        ),
      ],
    );
    final calendarCard = PortalGlassWidgetCard(
      width: _calendarWidth,
      child: DPMiniCalendarSection(dashboard: dashboard, decorated: false),
    );
    final pipelineCard = _TodayPipelineWidget(events: todayEvents);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= _sideBySideThreshold) {
          // Wide desktop: both groups sit side by side at their designed
          // fixed sizes, exactly as before.
          return PortalStaggeredReveal(
            children: [
              SizedBox(
                width: _clockRingWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    clockRingRow,
                    const SizedBox(height: 14),
                    PortalGlassFireWidget(width: _clockRingWidth, height: 118),
                  ],
                ),
              ),
              SizedBox(
                width: _calendarPipelineWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    calendarCard,
                    const SizedBox(width: 14),
                    SizedBox(width: _calendarWidth, child: pipelineCard),
                  ],
                ),
              ),
            ],
          );
        }

        // Not enough room for both groups side by side: each group fills
        // the actual available width instead of sitting pinned at a
        // fixed pixel size with dead space left beside it.
        final clockRingGroup = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: width < _clockRingWidth
                  ? FittedBox(fit: BoxFit.scaleDown, child: clockRingRow)
                  : clockRingRow,
            ),
            const SizedBox(height: 14),
            PortalGlassFireWidget(width: width, height: 118),
          ],
        );

        final calendarPipelineGroup = width < _calendarRowThreshold
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: width < _calendarWidth
                        ? FittedBox(fit: BoxFit.scaleDown, child: calendarCard)
                        : calendarCard,
                  ),
                  const SizedBox(height: 14),
                  pipelineCard,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  calendarCard,
                  const SizedBox(width: 14),
                  Expanded(child: pipelineCard),
                ],
              );

        return PortalStaggeredReveal(
          children: [
            SizedBox(width: width, child: clockRingGroup),
            SizedBox(width: width, child: calendarPipelineGroup),
          ],
        );
      },
    );
  }
}

/// Compact preview of today's real production timeline — the same
/// `dashboard.timeline` data the full "Today's Production Timeline"
/// section (below) shows in detail; this is a glanceable summary, not a
/// duplicate data source.
class _TodayPipelineWidget extends StatelessWidget {
  final List<DirectorTimelineItem> events;

  const _TodayPipelineWidget({required this.events});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PortalGlassWidgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                "Today's pipeline",
                style: AppTextStyles.sectionSerifHeading
                    .copyWith(color: colors.textPrimary, fontSize: 15),
              ),
              const Spacer(),
              if (events.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.goldSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${events.length}',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.goldDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (events.isEmpty)
            Text(
              'No production events scheduled today.',
              style:
                  AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
            )
          else
            for (var i = 0; i < events.length.clamp(0, 3); i++) ...[
              if (i != 0) const SizedBox(height: 10),
              _TodayPipelineRow(event: events[i]),
            ],
        ],
      ),
    );
  }
}

class _TodayPipelineRow extends StatelessWidget {
  final DirectorTimelineItem event;

  const _TodayPipelineRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final time = event.startsAt;
    final timeLabel = time == null
        ? '--:--'
        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Text(
            timeLabel,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.goldDark,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle
                    .copyWith(fontSize: 12.5, color: colors.textPrimary),
              ),
              Text(
                event.projectTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Modules" grid — the flagship's shortcut launchpad, replacing the
/// previous ad hoc CinePlanner/applications button rows with the
/// dashboard-kit's module-card grid. Counts are real pipeline/payment
/// figures already computed elsewhere on this dashboard, not fabricated.
class _ModulesSection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _ModulesSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final negotiating = dashboard.pipeline
        .where((item) =>
            item.kind == 'booking' &&
            ['sent', 'under_negotiation'].contains(item.status.toLowerCase()))
        .length;
    final contractsPending = dashboard.pipeline
        .where((item) =>
            item.kind == 'contract' &&
            item.status.toLowerCase().contains('pending'))
        .length;
    final paymentsDue =
        dashboard.dpPayments.where((p) => p.status == 'Due').length;

    final modules = [
      PortalModuleCard(
        icon: Icons.view_timeline_rounded,
        name: 'CinePlanner',
        description: 'Breakdowns, scenes, call sheets.',
        actionLabel: 'Open planner',
        tone: CineTone.information,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.cinePlanner),
      ),
      TourTarget(
        id: 'dp.reviewApplications',
        child: PortalModuleCard(
          icon: Icons.how_to_reg_outlined,
          name: 'Casting',
          description: 'Applications and auditions.',
          actionLabel: 'Review',
          tone: CineTone.premium,
          onTap: () =>
              Navigator.pushNamed(context, DirectorProducerRoutes.projects),
        ),
      ),
      TourTarget(
        id: 'dp.findProviders',
        child: PortalModuleCard(
          icon: Icons.travel_explore_outlined,
          name: 'Discover',
          description: 'Talent, crew, locations, gear.',
          actionLabel: 'Browse',
          tone: CineTone.information,
          onTap: () =>
              Navigator.pushNamed(context, DirectorProducerRoutes.marketplace),
        ),
      ),
      PortalModuleCard(
        icon: Icons.handshake_outlined,
        name: 'Bargaining',
        count: negotiating > 0 ? negotiating : null,
        description: 'Counter offers, lock rates.',
        actionLabel: 'Open deals',
        tone: CineTone.information,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.bargaining),
      ),
      PortalModuleCard(
        icon: Icons.description_outlined,
        name: 'Contracts',
        count: contractsPending > 0 ? contractsPending : null,
        description: 'Agreements and e-signatures.',
        actionLabel: 'View',
        tone: CineTone.warning,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.contracts),
      ),
      PortalModuleCard(
        icon: Icons.shield_outlined,
        name: 'Escrow',
        count: paymentsDue > 0 ? paymentsDue : null,
        description: 'Milestones and proof uploads.',
        actionLabel: 'Release',
        tone: CineTone.positive,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.payments),
      ),
    ];

    return TourTarget(
      id: 'dp.console.modules',
      child: DPSectionCard(
        title: 'Modules',
        icon: Icons.dashboard_customize_rounded,
        actionText: 'Review applications',
        onActionTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.projects),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = AppSpacing.md;
            final columns = (constraints.maxWidth / 216).floor().clamp(1, 3);
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final module in modules)
                  SizedBox(width: width, child: module),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WideBody extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _WideBody({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TodaySection(dashboard: dashboard),
              const SizedBox(height: 14),
              _ProjectDeckSection(dashboard: dashboard),
              const SizedBox(height: 14),
              _FinancialSection(dashboard: dashboard),
              const SizedBox(height: 14),
              _PipelineSection(dashboard: dashboard),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 4,
          child: _PrioritySection(dashboard: dashboard),
        ),
      ],
    );
  }
}

class _CompactBody extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _CompactBody({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PrioritySection(dashboard: dashboard),
        const SizedBox(height: 14),
        _TodaySection(dashboard: dashboard),
        const SizedBox(height: 14),
        _ProjectDeckSection(dashboard: dashboard),
        const SizedBox(height: 14),
        _FinancialSection(dashboard: dashboard),
        const SizedBox(height: 14),
        _PipelineSection(dashboard: dashboard),
      ],
    );
  }
}

class _PrioritySection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _PrioritySection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return TourTarget(
      id: 'dp.needsAttention',
      child: DPSectionCard(
        title: 'Needs your attention · ${dashboard.priorityActions.length}',
        icon: Icons.priority_high_rounded,
        actionText: 'View all',
        onActionTap: () =>
            Navigator.pushNamed(context, CoreRoutes.notifications),
        child: DPPriorityActions(items: dashboard.priorityActions),
      ),
    );
  }
}

class _TodaySection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _TodaySection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: "Today's Production Timeline",
      icon: Icons.today_outlined,
      actionText: 'Full schedule',
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.schedule),
      child: DPTodayTimeline(events: dashboard.dpTimeline),
    );
  }
}

class _ProjectDeckSection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _ProjectDeckSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Project Command Deck',
      icon: Icons.dashboard_customize_rounded,
      actionText: 'View all',
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.projects),
      child: DPProjectDeck(projects: dashboard.dpProjects),
    );
  }
}

class _FinancialSection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _FinancialSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Financial Command Centre',
      icon: Icons.account_balance_wallet_outlined,
      actionText: 'View payments',
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.payments),
      child: DPFinancialCentre(
        payments: dashboard.dpPayments,
        summary: dashboard.summary,
      ),
    );
  }
}

class _PipelineSection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _PipelineSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Deals & Contracts Pipeline',
      icon: Icons.handshake_outlined,
      actionText: 'View all',
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.bargaining),
      child: DPDealPipeline(items: dashboard.pipeline),
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading live Director dashboard…',
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, color: colors.warning, size: 28),
          const SizedBox(height: 10),
          Text(
            'Live dashboard unavailable',
            style: AppTextStyles.cardTitle.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
