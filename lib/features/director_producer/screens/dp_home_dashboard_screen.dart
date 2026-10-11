import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/director/director_dashboard_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_target.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/dashboard/dashboard_kit.dart';
import '../../../shared/formatters/cine_format.dart';
import '../../../shared/widgets/cine_hover_zoom.dart';
import '../models/dp_candidate.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dashboard/dp_command_header.dart';
import '../widgets/dashboard/dp_deal_pipeline.dart';
import '../widgets/dashboard/dp_financial_centre.dart';
import '../widgets/dashboard/dp_mini_calendar_section.dart';
import '../widgets/dashboard/dp_priority_actions.dart';
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
      _loadDiscovery(auth),
    ]);
    return _DirectorHomeData(
      dashboard: results[0] as DirectorDashboard,
      schedule: results[1] as DirectorSchedule,
      candidates: results[2] as List<DpCandidate>,
    );
  }

  Future<List<DpCandidate>> _loadDiscovery(AuthController auth) async {
    try {
      final discovery = await auth.directorDiscovery(category: 'All');
      return discovery.items.map((item) => item.toCandidate()).toList();
    } on Object {
      // Discovery must never prevent the production dashboard from opening.
      return const <DpCandidate>[];
    }
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
        final candidates = snapshot.data!.candidates;
        final displayName = AuthScope.maybeOf(context)?.user?.displayName;
        return PortalDashboardPage(
          showLiveStrip: false,
          children: [
            DPCommandHeader(
              summary: dashboard.summary,
              displayName: displayName,
            ),
            _ActivityTicker(items: dashboard.activity),
            _WidgetGridSection(
              dashboard: dashboard,
              schedule: schedule,
            ),
            _PrioritySection(dashboard: dashboard),
            _ProjectDeckSection(dashboard: dashboard),
            _CinePlannerFeature(
              dashboard: dashboard,
              schedule: schedule,
            ),
            _DiscoverShowcase(candidates: candidates),
            _FinancialCommandSection(dashboard: dashboard),
          ],
        );
      },
    );
  }
}

class _DirectorHomeData {
  final DirectorDashboard dashboard;
  final DirectorSchedule schedule;
  final List<DpCandidate> candidates;

  const _DirectorHomeData({
    required this.dashboard,
    required this.schedule,
    required this.candidates,
  });
}

/// CinePlanner feature surface modelled on the reference dashboard while using
/// live projects, schedule events, and call-sheet state.
class _CinePlannerFeature extends StatelessWidget {
  final DirectorDashboard dashboard;
  final DirectorSchedule schedule;

  const _CinePlannerFeature({
    required this.dashboard,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final boardItems = <_PlannerBoardItem>[
      for (final event in schedule.events.take(4))
        _PlannerBoardItem(
          code: 'SC',
          title: event.title,
          meta: event.status,
        ),
      for (final project in dashboard.dpProjects.take(4))
        _PlannerBoardItem(
          code: 'PRJ',
          title: project.title,
          meta: project.status,
        ),
    ];
    if (schedule.callSheet.status != 'empty') {
      boardItems.insert(
        0,
        _PlannerBoardItem(
          code: 'CALL',
          title: schedule.callSheet.label,
          meta: schedule.callSheet.status,
        ),
      );
    }
    if (boardItems.isEmpty) {
      boardItems.add(const _PlannerBoardItem(
        code: 'READY',
        title: 'Upload a script to begin',
        meta: 'CinePlanner workspace',
      ));
    }

    return TourTarget(
      id: 'dp.console.modules',
      child: CineHoverZoom(
        scale: 1.004,
        pressedScale: 1.01,
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.card,
                colors.goldSoft.withValues(alpha: colors.isLight ? .82 : .13),
                colors.elevatedSurface,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: colors.goldMid.withValues(alpha: .34)),
            boxShadow: [
              BoxShadow(
                color:
                    colors.shadow.withValues(alpha: colors.isLight ? .12 : .32),
                blurRadius: 32,
                spreadRadius: -20,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 38,
                top: -28,
                child: _PlannerBubble(size: 88, color: colors.infoBlue),
              ),
              Positioned(
                left: 46,
                bottom: -32,
                child: _PlannerBubble(size: 72, color: colors.goldMid),
              ),
              Padding(
                padding: const EdgeInsets.all(26),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 800;
                    final copy = _PlannerFeatureCopy(
                      projectCount: dashboard.projects.length,
                      scheduleCount: schedule.events.length,
                      callSheetReady: schedule.callSheet.status != 'empty',
                    );
                    final board =
                        _PlannerSceneBoard(items: boardItems.take(6).toList());
                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          copy,
                          const SizedBox(height: 24),
                          board,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 5, child: copy),
                        const SizedBox(width: 30),
                        Expanded(flex: 6, child: board),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlannerFeatureCopy extends StatelessWidget {
  final int projectCount;
  final int scheduleCount;
  final bool callSheetReady;

  const _PlannerFeatureCopy({
    required this.projectCount,
    required this.scheduleCount,
    required this.callSheetReady,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CINEPLANNER',
              style: AppTextStyles.micro.copyWith(
                color: colors.goldDark,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
              ),
            ),
            const SizedBox(width: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: colors.goldMid,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'AI',
                style: AppTextStyles.micro.copyWith(
                  color: colors.onGold,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'From screenplay',
          style: AppTextStyles.heroSerifHeadline.copyWith(
            color: colors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.normal,
            height: 1.02,
          ),
        ),
        Text(
          'to call sheet.',
          style: AppTextStyles.heroSerifHeadline.copyWith(
            color: colors.goldDark,
            fontSize: 34,
            fontWeight: FontWeight.w500,
            height: 1.04,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Break down scenes, schedule shoot days, and issue call sheets from one connected workspace.',
          style: AppTextStyles.body.copyWith(
            color: colors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _PlannerMetric(value: '$projectCount', label: 'Productions'),
            _PlannerMetric(value: '$scheduleCount', label: 'Scheduled'),
            _PlannerMetric(
              value: callSheetReady ? 'Ready' : 'Open',
              label: 'Call sheet',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                DirectorProducerRoutes.cinePlanner,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colors.goldMid,
                foregroundColor: colors.onGold,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: const Text('Plan now'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                DirectorProducerRoutes.cinePlanner,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              ),
              icon: const Icon(Icons.upload_file_outlined, size: 17),
              label: const Text('Upload script'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlannerMetric extends StatelessWidget {
  final String value;
  final String label;

  const _PlannerMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.metricNumberCompact.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _PlannerBoardItem {
  final String code;
  final String title;
  final String meta;

  const _PlannerBoardItem({
    required this.code,
    required this.title,
    required this.meta,
  });
}

class _PlannerSceneBoard extends StatelessWidget {
  final List<_PlannerBoardItem> items;

  const _PlannerSceneBoard({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.elevatedSurface.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIVE PRODUCTION BOARD',
            style: AppTextStyles.micro.copyWith(
              color: colors.textTertiary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 430 ? 3 : 2;
              final itemWidth =
                  (constraints.maxWidth - (columns - 1) * 9) / columns;
              return Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: itemWidth,
                      child: _PlannerSceneTile(item: item),
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

class _PlannerSceneTile extends StatelessWidget {
  final _PlannerBoardItem item;

  const _PlannerSceneTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                item.code,
                style: AppTextStyles.micro.copyWith(
                  color: colors.goldDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  item.meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.micro.copyWith(
                    color: colors.textTertiary,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardTitle.copyWith(
              color: colors.textPrimary,
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _PlannerBubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              context.appColors.surfaceHighlight.withValues(alpha: .7),
              color.withValues(alpha: .13),
              color.withValues(alpha: .02),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: .15)),
        ),
      ),
    );
  }
}

class _DiscoverShowcase extends StatefulWidget {
  final List<DpCandidate> candidates;

  const _DiscoverShowcase({required this.candidates});

  @override
  State<_DiscoverShowcase> createState() => _DiscoverShowcaseState();
}

class _DiscoverShowcaseState extends State<_DiscoverShowcase> {
  static const _categories = <String>[
    'All',
    'Actors',
    'Models',
    'Locations',
    'Crew',
    'Equipment',
  ];

  String _category = 'All';

  bool _matches(DpCandidate candidate) {
    if (_category == 'All') return true;
    if (_category == 'Equipment') {
      return candidate.category == 'Media & Equipment' ||
          candidate.category == 'Equipment';
    }
    return candidate.category == _category;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final filtered = widget.candidates.where(_matches).toList();
    final visible =
        filtered.isEmpty && _category != 'All' ? widget.candidates : filtered;

    return KeyedSubtree(
      key: const ValueKey('director-discover-section'),
      child: TourTarget(
        id: 'dp.findProviders',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    'Discover',
                    style: AppTextStyles.sectionHeaderStyle.copyWith(
                      color: colors.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                for (final category in _categories)
                  _DiscoveryCategoryPill(
                    label: category,
                    selected: _category == category,
                    onTap: () => setState(() => _category = category),
                  ),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.marketplace,
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('View marketplace'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (visible.isEmpty)
              _DiscoverEmptyState(
                onOpen: () => Navigator.pushNamed(
                  context,
                  DirectorProducerRoutes.marketplace,
                ),
              )
            else
              PortalDiscoverCarousel(
                height: 238,
                cards: [
                  for (var index = 0; index < visible.take(8).length; index++)
                    PortalDiscoverCard(
                      width: 182,
                      height: 238,
                      name: visible[index].name,
                      role:
                          '${visible[index].category} · ${visible[index].city}',
                      categoryLabel: visible[index].category,
                      ratingLabel: visible[index].rating > 0
                          ? visible[index].rating.toStringAsFixed(1)
                          : 'New',
                      verified: visible[index].verified,
                      imageUrl: visible[index].imageUrl,
                      tonePlateKind: _candidateTone(index),
                      onTap: () => _openCandidate(context, visible[index]),
                      onView: () => _openCandidate(context, visible[index]),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openCandidate(BuildContext context, DpCandidate candidate) {
    Navigator.pushNamed(
      context,
      DirectorProducerRoutes.profile,
      arguments: {
        'candidateId': candidate.profileId,
        'type': candidate.category,
      },
    );
  }
}

String _candidateTone(int index) => switch (index % 5) {
      0 => 'actor',
      1 => 'location',
      2 => 'equipment',
      3 => 'crew',
      _ => 'model',
    };

class _DiscoveryCategoryPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DiscoveryCategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: selected ? colors.goldMid : colors.card,
      shape: StadiumBorder(side: BorderSide(color: colors.border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: AppTextStyles.smallMeta.copyWith(
              color: selected ? colors.onGold : colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverEmptyState extends StatelessWidget {
  final VoidCallback onOpen;

  const _DiscoverEmptyState({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.travel_explore_rounded, color: colors.goldDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Open the live marketplace to discover collaborators.',
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
          ),
          TextButton(onPressed: onOpen, child: const Text('Discover')),
        ],
      ),
    );
  }
}

/// The reference dashboard's planning band: live time and payment state on
/// the left, the production month in the centre, and the selected day's plan
/// on the right. It preserves the same order at every breakpoint.
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

  List<DirectorScheduleEvent> get _selectedEvents {
    final events = widget.schedule.events.where((event) {
      final startsAt = event.startsAt;
      return startsAt != null &&
          startsAt.year == _selectedDay.year &&
          startsAt.month == _selectedDay.month &&
          startsAt.day == _selectedDay.day;
    }).toList()
      ..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.dashboard.summary;
    final paid = summary.paidMinor ~/ 100;
    final pending = summary.pendingPaymentMinor ~/ 100;
    final total = paid + pending;
    final progress = total == 0 ? 0.0 : paid / total;

    Widget sideCards(double size, {bool horizontal = false}) {
      final cards = <Widget>[
        PortalLiveClockWidget(size: size),
        PortalGlassRingWidget(
          size: size,
          progress: progress,
          value: CineFormat.currency(paid, compact: true),
          label: 'Payments cleared\nthis cycle',
          tone: CineTone.premium,
          onTap: () => Navigator.pushNamed(
            context,
            DirectorProducerRoutes.payments,
          ),
        ),
      ];
      if (horizontal) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [cards.first, const SizedBox(width: 12), cards.last],
        );
      }
      return Column(
        children: [cards.first, const SizedBox(height: 14), cards.last],
      );
    }

    Widget calendar({double? height}) => PortalGlassWidgetCard(
          height: height,
          child: DPMiniCalendarSection(
            events: widget.schedule.events,
            selectedDate: _selectedDay,
            onDaySelected: (day) => setState(() => _selectedDay = day),
            decorated: false,
          ),
        );

    Widget planner({double? height}) => _TodayPipelineWidget(
          height: height,
          selectedDate: _selectedDay,
          events: _selectedEvents,
          onAddPlan: () => Navigator.pushNamed(
            context,
            DirectorProducerRoutes.schedule,
          ),
        );

    return KeyedSubtree(
      key: const ValueKey('director-planning-grid'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (width >= 1060) {
            const height = 430.0;
            return SizedBox(
              height: height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 208, child: sideCards(208)),
                  const SizedBox(width: 14),
                  Expanded(flex: 6, child: calendar(height: height)),
                  const SizedBox(width: 14),
                  Expanded(flex: 4, child: planner(height: height)),
                ],
              ),
            );
          }
          if (width >= 720) {
            const height = 430.0;
            return Column(
              children: [
                SizedBox(
                  height: height,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 208, child: sideCards(208)),
                      const SizedBox(width: 14),
                      Expanded(child: calendar(height: height)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                planner(),
              ],
            );
          }
          final cardSize = ((width - 12) / 2).clamp(132.0, 180.0);
          return Column(
            children: [
              sideCards(cardSize, horizontal: true),
              const SizedBox(height: 14),
              calendar(),
              const SizedBox(height: 14),
              planner(),
            ],
          );
        },
      ),
    );
  }
}

class _ActivityTicker extends StatelessWidget {
  final List<DirectorActivityItem> items;

  const _ActivityTicker({required this.items});

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('director-live-ticker'),
      child: PortalNewsTicker(
        items: [
          for (final item in items)
            PortalNewsItem(
              badge: item.itemType.isNotEmpty
                  ? item.itemType[0].toUpperCase()
                  : '•',
              title: item.title,
              meta: item.projectTitle,
              ago: _activityAge(item.createdAt),
              onTap: () => Navigator.pushNamed(
                context,
                item.route ??
                    switch (item.itemType) {
                      'booking' => DirectorProducerRoutes.bargaining,
                      'payment' => DirectorProducerRoutes.payments,
                      'contract' => DirectorProducerRoutes.contracts,
                      _ => DirectorProducerRoutes.room,
                    },
                arguments: item.argument == null ? null : {'id': item.argument},
              ),
            ),
        ],
      ),
    );
  }
}

String _activityAge(DateTime? value) {
  if (value == null) return 'Now';
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.inMinutes < 1) return 'Now';
  if (difference.inHours < 1) return '${difference.inMinutes}m';
  if (difference.inDays < 1) return '${difference.inHours}h';
  return '${difference.inDays}d';
}

/// The selected-day planner from the reference dashboard. The Add plan action
/// opens the live schedule workspace, where the event is saved to the backend.
class _TodayPipelineWidget extends StatelessWidget {
  final DateTime selectedDate;
  final List<DirectorScheduleEvent> events;
  final VoidCallback onAddPlan;
  final double? height;

  const _TodayPipelineWidget({
    required this.selectedDate,
    required this.events,
    required this.onAddPlan,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final eventBody = events.isEmpty
        ? Container(
            constraints: const BoxConstraints(minHeight: 150),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month_outlined,
                    color: colors.goldMid, size: 27),
                const SizedBox(height: 8),
                Text(
                  'Nothing planned',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a shoot, recce or meeting.',
                  style: AppTextStyles.smallMeta
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          )
        : Column(
            children: [
              for (var i = 0; i < events.length.clamp(0, 4); i++) ...[
                _TodayPipelineRow(event: events[i]),
                if (i != events.length.clamp(0, 4) - 1)
                  Divider(height: 18, color: colors.borderMuted),
              ],
            ],
          );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLANNER',
                    style: AppTextStyles.micro.copyWith(
                      color: colors.goldDark,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _plannerDateLabel(selectedDate),
                    style: AppTextStyles.sectionSerifHeading.copyWith(
                      color: colors.textPrimary,
                      fontSize: 19,
                    ),
                  ),
                ],
              ),
            ),
            if (events.isNotEmpty)
              Text(
                '${events.length} ${events.length == 1 ? 'plan' : 'plans'}',
                style: AppTextStyles.smallMeta
                    .copyWith(color: colors.textTertiary),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: colors.borderMuted),
        const SizedBox(height: 8),
        if (height == null) eventBody else Expanded(child: eventBody),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: onAddPlan,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Add plan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.goldDark,
              side: BorderSide(
                color: colors.goldMid.withValues(alpha: .45),
                style: BorderStyle.solid,
              ),
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ],
    );

    return PortalGlassWidgetCard(height: height, child: body);
  }
}

String _plannerDateLabel(DateTime value) {
  if (_sameCalendarDay(value, DateTime.now())) return 'Today';
  const months = [
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
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

bool _sameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

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

class _PrioritySection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _PrioritySection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('director-attention-section'),
      child: TourTarget(
        id: 'dp.needsAttention',
        child: DPSectionCard(
          title: 'Needs your attention · ${dashboard.priorityActions.length}',
          icon: Icons.priority_high_rounded,
          actionText: 'View all',
          onActionTap: () =>
              Navigator.pushNamed(context, CoreRoutes.notifications),
          child: DPPriorityActions(items: dashboard.priorityActions),
        ),
      ),
    );
  }
}

class _ProjectDeckSection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _ProjectDeckSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final projects = dashboard.dpProjects;
    return KeyedSubtree(
      key: const ValueKey('director-project-deck'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Project Command Deck',
                  style: AppTextStyles.sectionHeaderStyle.copyWith(
                    color: colors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  DirectorProducerRoutes.projects,
                ),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PortalPosterCarousel(
            height: 260,
            cards: [
              for (var index = 0; index < projects.length; index++)
                PortalPosterCard(
                  width: 330,
                  height: 260,
                  title: projects[index].title,
                  meta:
                      '${projects[index].city} · ${projects[index].dateRange}',
                  statusLabel: projects[index].status,
                  statusColor: _projectStatusColor(
                    colors,
                    projects[index].status,
                  ),
                  tagLabel: projects[index].type,
                  progressLabel: 'Budget health',
                  progressValue: projects[index].budgetHealth,
                  trailingMeta:
                      '${projects[index].pendingActions} actions · ${projects[index].shootDate}',
                  primaryLabel: 'Open Hub',
                  imageUrl: projects[index].coverImageUrl,
                  tonePlateKind: _projectTone(index),
                  heroTag: 'project-poster-${projects[index].id}',
                  onTap: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.projectPath(projects[index].id),
                    arguments: projects[index].id,
                  ),
                  onPrimary: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.projectPath(projects[index].id),
                    arguments: projects[index].id,
                  ),
                ),
            ],
            createLabel: 'New project',
            onCreate: () => Navigator.pushNamed(
              context,
              DirectorProducerRoutes.createProject,
            ),
          ),
        ],
      ),
    );
  }
}

Color _projectStatusColor(CineThemeColors colors, String status) {
  final value = status.toLowerCase();
  if (value.contains('active') || value.contains('approved')) {
    return colors.success;
  }
  if (value.contains('contract') || value.contains('pending')) {
    return colors.warning;
  }
  if (value.contains('hold') || value.contains('risk')) return colors.danger;
  return colors.infoBlue;
}

String _projectTone(int index) => switch (index % 4) {
      0 => 'gold',
      1 => 'crew',
      2 => 'model',
      _ => 'location',
    };

class _FinancialCommandSection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _FinancialCommandSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return KeyedSubtree(
      key: const ValueKey('director-financial-command'),
      child: DPGlassCard(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Financial Command Centre',
                    style: AppTextStyles.sectionHeaderStyle.copyWith(
                      color: colors.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.payments,
                  ),
                  child: const Text('View payments'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DPFinancialCentre(
              payments: dashboard.dpPayments,
              summary: dashboard.summary,
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: colors.borderMuted),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Deals & Contracts Pipeline',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: colors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.bargaining,
                  ),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DPDealPipeline(items: dashboard.pipeline),
          ],
        ),
      ),
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
