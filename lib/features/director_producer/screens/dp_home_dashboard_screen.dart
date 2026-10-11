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
import '../../../shared/widgets/cine_hover_zoom.dart';
import '../models/dp_candidate.dart';
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
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= AppBreakpoints.tablet;
            return PortalDashboardPage(
              children: [
                DPCommandHeader(
                  summary: dashboard.summary,
                  displayName: displayName,
                ),
                _WidgetGridSection(
                  dashboard: dashboard,
                  schedule: schedule,
                ),
                _ProjectDeckSection(dashboard: dashboard),
                _CinePlannerFeature(
                  dashboard: dashboard,
                  schedule: schedule,
                ),
                _DiscoverShowcase(candidates: candidates),
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

    return TourTarget(
      id: 'dp.findProviders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 2),
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
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Talent, locations, crew, and equipment from the live marketplace.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
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
            SizedBox(
              height: 310,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: visible.take(8).length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final candidate = visible[index];
                  return _DiscoverCandidateCard(
                    candidate: candidate,
                    onOpen: () => Navigator.pushNamed(
                      context,
                      DirectorProducerRoutes.profile,
                      arguments: {
                        'candidateId': candidate.profileId,
                        'type': candidate.category,
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

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

class _DiscoverCandidateCard extends StatelessWidget {
  final DpCandidate candidate;
  final VoidCallback onOpen;

  const _DiscoverCandidateCard({
    required this.candidate,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 226,
      child: CineHoverZoom(
        scale: 1.012,
        pressedScale: 1.022,
        child: Material(
          color: colors.card,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _CandidateVisual(candidate: candidate),
                        Positioned(
                          left: 12,
                          top: 12,
                          child: _CandidateBadge(label: candidate.category),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: _CandidateBadge(
                            label: candidate.rating > 0
                                ? '★ ${candidate.rating.toStringAsFixed(1)}'
                                : 'New',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                candidate.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.cardTitle.copyWith(
                                  color: colors.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (candidate.verified) ...[
                              const SizedBox(width: 5),
                              Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: colors.goldMid,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${candidate.category} · ${candidate.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.smallMeta.copyWith(
                            color: colors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 11),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: onOpen,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.border),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            child: const Text('View profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CandidateVisual extends StatelessWidget {
  final DpCandidate candidate;

  const _CandidateVisual({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.goldSoft,
            colors.infoBlue.withValues(alpha: colors.isLight ? .16 : .24),
            colors.infoPurple.withValues(alpha: colors.isLight ? .12 : .2),
          ],
        ),
      ),
      child: Center(
        child: Text(
          candidate.avatarLabel,
          style: AppTextStyles.heroSerifNumber.copyWith(
            color: colors.textPrimary.withValues(alpha: .16),
            fontSize: 62,
          ),
        ),
      ),
    );
    final imageUrl = candidate.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) return fallback;
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _CandidateBadge extends StatelessWidget {
  final String label;

  const _CandidateBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: .91),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.micro.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
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
