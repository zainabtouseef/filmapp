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
import '../widgets/dashboard/dp_activity_feed.dart';
import '../widgets/dashboard/dp_deal_pipeline.dart';
import '../widgets/dashboard/dp_financial_centre.dart';
import '../widgets/dashboard/dp_mini_calendar_section.dart';
import '../widgets/dashboard/dp_priority_actions.dart';
import '../widgets/dashboard/dp_project_deck.dart';
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
  Future<_DirectorHomeData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_DirectorHomeData> _load() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      throw const ApiException(
        code: 'auth.required',
        message: 'Sign in to load the live Director dashboard.',
      );
    }
    final results = await Future.wait<Object>([
      auth.directorDashboard(),
      auth.directorSchedule(),
    ]);
    return _DirectorHomeData(
      dashboard: results[0] as DirectorDashboard,
      schedule: results[1] as DirectorSchedule,
    );
  }

  void _retry() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DirectorHomeData>(
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
        final dashboard = snapshot.data!.dashboard;
        final schedule = snapshot.data!.schedule;
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
                _CinePlannerEntry(dashboard: dashboard),
                const SizedBox(height: 14),
                _WidgetGridSection(
                  dashboard: dashboard,
                  schedule: schedule,
                ),
                const SizedBox(height: 14),
                _ProjectDeckSection(dashboard: dashboard),
                const SizedBox(height: 14),
                _ProductionWorkflowSection(dashboard: dashboard),
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

class _DirectorHomeData {
  final DirectorDashboard dashboard;
  final DirectorSchedule schedule;

  const _DirectorHomeData({
    required this.dashboard,
    required this.schedule,
  });
}

/// Planner sits directly below the Console header and uses live project counts.
class _CinePlannerEntry extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _CinePlannerEntry({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'CinePlanner',
      icon: Icons.view_timeline_rounded,
      actionText: 'Open planner',
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.cinePlanner),
      child: Text(
        '${dashboard.projects.length} ${dashboard.projects.length == 1 ? 'project' : 'projects'} · Screenplays, breakdowns, '
        'resources, schedules and call sheets in one production workspace.',
        style: AppTextStyles.body.copyWith(
          color: context.appColors.textSecondary,
        ),
      ),
    );
  }
}

/// Compact live widgets backed by the dashboard response.
class _WidgetGridSection extends StatefulWidget {
  final DirectorDashboard dashboard;
  final DirectorSchedule schedule;

  const _WidgetGridSection({
    required this.dashboard,
    required this.schedule,
  });

  @override
  State<_WidgetGridSection> createState() => _WidgetGridSectionState();
}

class _WidgetGridSectionState extends State<_WidgetGridSection> {
  DateTime _selectedDay = DateTime.now();

  static const _clockRingWidth = 168.0 * 2 + 14;
  static const _calendarWidth = 340.0;
  static const _calendarPipelineWidth = _calendarWidth * 2 + 14;
  static const _calendarPanelHeight = 318.0;

  /// Below this, there's room for both groups side by side exactly as
  /// designed — nothing changes from the wide desktop layout.
  static const _sideBySideThreshold =
      _clockRingWidth + 14 + _calendarPipelineWidth;

  /// Below this, even a single row of calendar + pipeline is too tight;
  /// they stack instead of squeezing pipeline into a sliver.
  static const _calendarRowThreshold = 420.0;

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.dashboard;
    final summary = dashboard.summary;
    final paid = summary.paidMinor ~/ 100;
    final pending = summary.pendingPaymentMinor ~/ 100;
    final total = paid + pending;
    final progress = total == 0 ? 0.0 : paid / total;

    final selectedEvents = widget.schedule.events.where((event) {
      final startsAt = event.startsAt;
      return startsAt != null &&
          startsAt.year == _selectedDay.year &&
          startsAt.month == _selectedDay.month &&
          startsAt.day == _selectedDay.day;
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
      child: DPMiniCalendarSection(
        events: widget.schedule.events,
        selectedDate: _selectedDay,
        onDaySelected: (day) => setState(() => _selectedDay = day),
        decorated: false,
      ),
    );
    final pipelineCard = _TodayPipelineWidget(
      selectedDate: _selectedDay,
      events: selectedEvents,
    );

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
                    SizedBox(
                      width: _clockRingWidth,
                      child: _ActivityNewsWidget(
                        items: dashboard.activity,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: _calendarPanelHeight,
                child: SizedBox(
                  width: _calendarPipelineWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      calendarCard,
                      const SizedBox(width: 14),
                      SizedBox(width: _calendarWidth, child: pipelineCard),
                    ],
                  ),
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
            SizedBox(
              width: width,
              child: _ActivityNewsWidget(items: dashboard.activity),
            ),
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
            : SizedBox(
                height: _calendarPanelHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    calendarCard,
                    const SizedBox(width: 14),
                    Expanded(child: pipelineCard),
                  ],
                ),
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

class _ActivityNewsWidget extends StatelessWidget {
  final List<DirectorActivityItem> items;

  const _ActivityNewsWidget({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PortalGlassWidgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign_outlined, size: 18, color: colors.goldDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live production news',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionSerifHeading.copyWith(
                    color: colors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DPActivityFeed(items: items.take(2).toList()),
        ],
      ),
    );
  }
}

/// Compact preview of the current planner day.
class _TodayPipelineWidget extends StatelessWidget {
  final DateTime selectedDate;
  final List<DirectorScheduleEvent> events;

  const _TodayPipelineWidget({
    required this.selectedDate,
    required this.events,
  });

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
                _isToday(selectedDate)
                    ? "Today's schedule"
                    : '${selectedDate.day} ${_shortMonth(selectedDate.month)} schedule',
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
              'No production events scheduled for this date.',
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

  static bool _isToday(DateTime value) {
    final today = DateTime.now();
    return value.year == today.year &&
        value.month == today.month &&
        value.day == today.day;
  }

  static String _shortMonth(int month) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][month - 1];
}

class _TodayPipelineRow extends StatelessWidget {
  final DirectorScheduleEvent event;

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

/// Goal-oriented production workflows backed by live dashboard counts.
class _ProductionWorkflowSection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _ProductionWorkflowSection({required this.dashboard});

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

    final workflows = [
      _WorkflowAction(
        icon: Icons.view_timeline_rounded,
        name: 'Plan production',
        description: 'Build schedules, scenes, and call sheets.',
        actionLabel: 'Plan now',
        tone: CineTone.information,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.cinePlanner),
      ),
      _WorkflowAction(
        tourId: 'dp.reviewApplications',
        icon: Icons.how_to_reg_outlined,
        name: 'Build your cast',
        description: 'Review applications and auditions.',
        actionLabel: 'Review talent',
        tone: CineTone.premium,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.projects),
      ),
      _WorkflowAction(
        tourId: 'dp.findProviders',
        icon: Icons.travel_explore_outlined,
        name: 'Find collaborators',
        description: 'Discover talent, crew, locations, and gear.',
        actionLabel: 'Open marketplace',
        tone: CineTone.information,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.marketplace),
      ),
      _WorkflowAction(
        icon: Icons.handshake_outlined,
        name: 'Close negotiations',
        count: negotiating > 0 ? negotiating : null,
        description: 'Counter offers, lock rates.',
        actionLabel: 'Open deals',
        tone: CineTone.information,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.bargaining),
      ),
      _WorkflowAction(
        icon: Icons.description_outlined,
        name: 'Contracts to sign',
        count: contractsPending > 0 ? contractsPending : null,
        description: 'Agreements and e-signatures.',
        actionLabel: 'View',
        tone: CineTone.warning,
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.contracts),
      ),
      _WorkflowAction(
        icon: Icons.shield_outlined,
        name: 'Payment milestones',
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
        title: 'Production workflow',
        icon: Icons.account_tree_outlined,
        actionText: 'Review applications',
        onActionTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.projects),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = constraints.maxWidth >= 1120
                ? constraints.maxWidth / workflows.length
                : 218.0;
            return SizedBox(
              height: 178,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < workflows.length; i++)
                        SizedBox(
                          width: tileWidth,
                          child: _WorkflowStepTile(
                            step: i + 1,
                            action: workflows[i],
                            showDivider: i != workflows.length - 1,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WorkflowAction {
  final String? tourId;
  final IconData icon;
  final String name;
  final int? count;
  final String description;
  final String actionLabel;
  final CineTone tone;
  final VoidCallback onTap;

  const _WorkflowAction({
    this.tourId,
    required this.icon,
    required this.name,
    this.count,
    required this.description,
    required this.actionLabel,
    required this.tone,
    required this.onTap,
  });
}

class _WorkflowStepTile extends StatefulWidget {
  final int step;
  final _WorkflowAction action;
  final bool showDivider;

  const _WorkflowStepTile({
    required this.step,
    required this.action,
    required this.showDivider,
  });

  @override
  State<_WorkflowStepTile> createState() => _WorkflowStepTileState();
}

class _WorkflowStepTileState extends State<_WorkflowStepTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = cineToneColor(context, widget.action.tone);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget tile = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        constraints: const BoxConstraints(minHeight: 150),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tone.withValues(alpha: _hovered ? 0.12 : 0.055),
              colors.elevatedSurface.withValues(alpha: 0.72),
            ],
          ),
          border: widget.showDivider
              ? Border(right: BorderSide(color: colors.border))
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.action.onTap,
            hoverColor: tone.withValues(alpha: 0.035),
            splashColor: tone.withValues(alpha: 0.10),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconBadge(
                        icon: widget.action.icon,
                        tone: widget.action.tone,
                        compact: true,
                      ),
                      const Spacer(),
                      Text(
                        widget.step.toString().padLeft(2, '0'),
                        style: AppTextStyles.micro.copyWith(
                          color: tone,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                        ),
                      ),
                      if (widget.action.count != null) ...[
                        const SizedBox(width: 8),
                        CountBadge(
                          count: widget.action.count!,
                          tone: widget.action.tone,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.action.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: colors.textPrimary,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.action.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.action.actionLabel,
                        style: AppTextStyles.smallMeta.copyWith(
                          color: tone,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: tone),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.action.tourId != null) {
      tile = TourTarget(id: widget.action.tourId!, child: tile);
    }
    return Semantics(
      button: true,
      label: '${widget.action.name}. ${widget.action.actionLabel}',
      child: tile,
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
