import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/director/director_dashboard_models.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dp_booking.dart';
import '../models/dp_contract.dart';
import '../models/dp_payment.dart';
import '../models/dp_project.dart';
import '../models/dp_requirement.dart';
import '../models/dp_schedule_item.dart';
import '../routes/director_producer_routes.dart';
import 'dp_budget_health_bar.dart';
import 'dp_glass_card.dart';
import 'dp_holographic_button.dart';
import 'dp_layout_helpers.dart';
import 'dp_status_chip.dart';

DpProject dpProjectForId(String? projectId) {
  return DpProject(
    id: projectId ?? 'project-unavailable',
    title: 'Project unavailable',
    type: 'Project',
    city: 'Database',
    dateRange: 'No live project selected',
    status: 'Unavailable',
    estimatedBudget: 0,
    confirmedCost: 0,
    budgetHealth: 0,
    pendingActions: 0,
    shootDate: 'TBD',
    bookingsCount: 0,
    contractsCount: 0,
    paymentsStatus: 'No live data',
    team: const [],
    progress: 0,
  );
}

String dpProjectTitleForId(String? projectId) =>
    dpProjectForId(projectId).title;

String dpProjectIdForTitle(String projectTitle) {
  return 'project-unavailable';
}

List<DpRequirement> dpRequirementsForProject(String projectId) {
  return const [];
}

List<DpBooking> dpBookingsForProject(String projectId) {
  return const [];
}

List<DpContract> dpContractsForProject(String projectTitle) {
  return const [];
}

List<DpPayment> dpPaymentsForProject(String projectTitle) {
  return const [];
}

List<DpScheduleItem> dpScheduleForProject(String? projectTitle) {
  return const [];
}

int dpMoneyFromLabel(String value) {
  final normalized = value.toLowerCase().replaceAll(',', '');
  final number = int.tryParse(normalized.replaceAll(RegExp(r'[^0-9]'), ''));
  if (number == null) return 0;
  if (normalized.contains('m')) return number * 1000000;
  if (normalized.contains('k')) return number * 1000;
  return number;
}

DpTone dpToneForStatus(String status) {
  final lower = status.toLowerCase();
  if (lower.contains('signed') ||
      lower.contains('verified') ||
      lower.contains('accepted') ||
      lower.contains('confirmed') ||
      lower.contains('secured')) {
    return DpTone.success;
  }
  if (lower.contains('rejected') ||
      lower.contains('cancelled') ||
      lower.contains('conflict')) {
    return DpTone.danger;
  }
  if (lower.contains('pending') ||
      lower.contains('due') ||
      lower.contains('expiring') ||
      lower.contains('tentative')) {
    return DpTone.warning;
  }
  return DpTone.info;
}

class DPProjectScopePicker extends StatelessWidget {
  final String? selectedProjectId;
  final ValueChanged<String?> onChanged;
  final bool includeAll;

  const DPProjectScopePicker({
    super.key,
    required this.selectedProjectId,
    required this.onChanged,
    this.includeAll = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final projects = ProjectsScope.maybeOf(context);
    if (projects == null) {
      return dpText(context, 'Live project picker unavailable.');
    }
    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colors.surface.withValues(alpha: 0.52),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: FutureBuilder(
          future: projects.projects(),
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const [];
            final validValue =
                rows.any((project) => project.publicId == selectedProjectId)
                    ? selectedProjectId
                    : null;
            return DropdownButton<String?>(
              value: validValue,
              isExpanded: true,
              icon: Icon(Icons.expand_more_rounded, color: colors.iconMuted),
              style: AppTextStyles.label.copyWith(color: colors.textPrimary),
              onChanged: snapshot.hasError ? null : onChanged,
              items: [
                if (includeAll)
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All projects'),
                  ),
                for (final project in rows)
                  DropdownMenuItem<String?>(
                    value: project.publicId,
                    child: Text(project.title),
                  ),
                if (rows.isEmpty && !includeAll)
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No live projects'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class DPCollapsibleSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool collapsed;
  final VoidCallback onToggle;
  final Widget child;
  final Widget? trailing;
  final String? actionText;
  final VoidCallback? onActionTap;

  const DPCollapsibleSection({
    super.key,
    required this.title,
    required this.icon,
    required this.collapsed,
    required this.onToggle,
    required this.child,
    this.trailing,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final controlsMaxWidth =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: colors.goldDark, size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: collapsed ? 'Expand section' : 'Collapse section',
                    visualDensity: VisualDensity.compact,
                    onPressed: onToggle,
                    icon: Icon(
                      collapsed
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      color: colors.iconMuted,
                    ),
                  ),
                ],
              ),
              if (trailing != null || actionText != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (trailing != null)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: controlsMaxWidth,
                        ),
                        child: trailing!,
                      ),
                    if (actionText != null)
                      GestureDetector(
                        onTap: onActionTap,
                        child: Text(
                          actionText!,
                          style: AppTextStyles.sectionAction.copyWith(
                            color: colors.goldDark,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 180),
                firstChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: child,
                ),
                secondChild: const SizedBox.shrink(),
                crossFadeState: collapsed
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),
            ],
          );
        },
      ),
    );
  }
}

class DPStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final DpTone tone;
  final VoidCallback? onTap;

  const DPStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 196,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colors.surface.withValues(alpha: colors.isLight ? 0.72 : 0.24),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: dpToneColor(context, tone), size: 20),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 620),
              builder: (context, progress, _) => Opacity(
                opacity: progress,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.metricNumberCompact.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ProductionCalendarMode { today, month, list }

class ProductionCalendar extends StatefulWidget {
  final String? projectId;
  final ProductionCalendarMode initialMode;
  final int listLimit;

  const ProductionCalendar({
    super.key,
    this.projectId,
    this.initialMode = ProductionCalendarMode.today,
    this.listLimit = 30,
  });

  @override
  State<ProductionCalendar> createState() => _ProductionCalendarState();
}

class _ProductionCalendarState extends State<ProductionCalendar> {
  late ProductionCalendarMode _mode = widget.initialMode;
  Future<DirectorSchedule>? _future;
  int? _selectedDay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void didUpdateWidget(covariant ProductionCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      setState(() {
        _mode = ProductionCalendarMode.today;
        _selectedDay = null;
        _future = _load();
      });
    }
  }

  Future<DirectorSchedule> _load() {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) {
      throw StateError('Auth scope is missing.');
    }
    return auth.directorSchedule(projectId: widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CalendarToggle(
          value: _mode,
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 12),
        FutureBuilder<DirectorSchedule>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return dpText(context, 'Loading live production schedule…');
            }
            if (snapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dpText(context, 'Could not load live production schedule.'),
                  const SizedBox(height: 8),
                  DPHolographicButton(
                    label: 'Retry',
                    icon: Icons.refresh_rounded,
                    onTap: () => setState(() => _future = _load()),
                    secondary: true,
                  ),
                ],
              );
            }
            final events = snapshot.data?.dpEvents ?? const [];
            return switch (_mode) {
              ProductionCalendarMode.today => _TodayTimeline(events: events),
              ProductionCalendarMode.month => _MonthCalendar(
                  events: events,
                  selectedDay: _selectedDay,
                  onDaySelected: (day) => setState(() => _selectedDay = day),
                ),
              ProductionCalendarMode.list =>
                _AgendaList(events: events.take(widget.listLimit).toList()),
            };
          },
        ),
      ],
    );
  }
}

class _CalendarToggle extends StatelessWidget {
  final ProductionCalendarMode value;
  final ValueChanged<ProductionCalendarMode> onChanged;

  const _CalendarToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ToggleChip(
          label: 'Today',
          selected: value == ProductionCalendarMode.today,
          onTap: () => onChanged(ProductionCalendarMode.today),
        ),
        _ToggleChip(
          label: 'Month',
          selected: value == ProductionCalendarMode.month,
          onTap: () => onChanged(ProductionCalendarMode.month),
        ),
        _ToggleChip(
          label: 'List',
          selected: value == ProductionCalendarMode.list,
          onTap: () => onChanged(ProductionCalendarMode.list),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DPStatusChip(
        label: label,
        tone: selected ? DpTone.warning : DpTone.neutral,
      ),
    );
  }
}

class _TodayTimeline extends StatelessWidget {
  final List<DpScheduleItem> events;

  const _TodayTimeline({required this.events});

  @override
  Widget build(BuildContext context) {
    final todayEvents = events
        .where((event) => event.date == 'Today' || event.date == 'Jul 21')
        .toList();
    final rows = todayEvents.isEmpty ? events.take(4).toList() : todayEvents;
    if (rows.isEmpty) {
      return dpText(context, 'No production events for the selected scope.');
    }
    return Column(
      children: [
        for (final event in rows) _CalendarEventRow(event: event),
      ],
    );
  }
}

class _AgendaList extends StatelessWidget {
  final List<DpScheduleItem> events;

  const _AgendaList({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return dpText(context, 'No upcoming production events.');
    }
    return Column(
      children: [
        for (final event in events) _CalendarEventRow(event: event),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  final List<DpScheduleItem> events;
  final int? selectedDay;
  final ValueChanged<int> onDaySelected;

  const _MonthCalendar({
    required this.events,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final days = List<int>.generate(35, (index) => index + 1);
    final selectedEvents = selectedDay == null
        ? const <DpScheduleItem>[]
        : events
            .where((event) => event.date.endsWith(' $selectedDay'))
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final day = days[index];
            final matches =
                events.where((event) => event.date.endsWith(' $day')).toList();
            return _CalendarDayTile(
              day: day,
              events: matches,
              selected: selectedDay == day,
              onTap: () => onDaySelected(day),
            );
          },
        ),
        if (selectedDay != null) ...[
          const SizedBox(height: 10),
          Container(height: 1, color: colors.borderMuted),
          const SizedBox(height: 10),
          Text(
            'Day $selectedDay',
            style:
                AppTextStyles.panelLabel.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          if (selectedEvents.isEmpty)
            Text(
              'No events on this day.',
              style:
                  AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
            )
          else
            for (final event in selectedEvents) _CalendarEventRow(event: event),
        ],
      ],
    );
  }
}

class _CalendarDayTile extends StatelessWidget {
  final int day;
  final List<DpScheduleItem> events;
  final bool selected;
  final VoidCallback onTap;

  const _CalendarDayTile({
    required this.day,
    required this.events,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: selected ? colors.goldGradient : null,
          color: selected
              ? null
              : colors.surface.withValues(alpha: colors.isLight ? 0.72 : 0.18),
          border: Border.all(
            color: selected
                ? colors.goldMid
                : events.isEmpty
                    ? colors.borderMuted
                    : colors.goldMid,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$day',
              style: AppTextStyles.caption.copyWith(
                color: selected ? colors.onGold : colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 3,
              runSpacing: 3,
              children: [
                for (final event in events.take(3))
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? colors.onGold
                          : event.conflict
                              ? colors.danger
                              : event.status.toLowerCase().contains('pending')
                                  ? colors.infoBlue
                                  : colors.goldMid,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarEventRow extends StatelessWidget {
  final DpScheduleItem event;

  const _CalendarEventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colors.surface.withValues(alpha: colors.isLight ? 0.68 : 0.2),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              event.time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(_iconForEvent(event), color: colors.goldDark, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dpText(context, event.location, strong: true),
                const SizedBox(height: 4),
                dpText(
                  context,
                  '${event.date} • ${event.project} • ${event.stakeholders.join(', ')}',
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DPStatusChip(
            label: event.status,
            tone:
                event.conflict ? DpTone.danger : dpToneForStatus(event.status),
          ),
        ],
      ),
    );
  }

  IconData _iconForEvent(DpScheduleItem event) {
    final location = event.location.toLowerCase();
    if (location.contains('payment')) return Icons.payments_outlined;
    if (location.contains('contract')) return Icons.article_outlined;
    if (location.contains('travel')) return Icons.flight_takeoff_outlined;
    if (location.contains('drone') || location.contains('lighting')) {
      return Icons.videocam_outlined;
    }
    return Icons.movie_creation_outlined;
  }
}

class DPProjectsRail extends StatelessWidget {
  final ValueChanged<String>? onScope;

  const DPProjectsRail({super.key, this.onScope});

  @override
  Widget build(BuildContext context) {
    final projects = ProjectsScope.maybeOf(context);
    if (projects == null) {
      return dpText(context, 'Live projects unavailable.');
    }
    return FutureBuilder(
      future: projects.projects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return dpText(context, 'Loading live projects…');
        }
        if (snapshot.hasError) {
          return dpText(context, 'Could not load live projects.');
        }
        final rows = (snapshot.data ?? const [])
            .map((project) => project.toDpProject())
            .toList();
        if (rows.isEmpty) {
          return dpText(context, 'No live projects yet.');
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final project in rows) ...[
                SizedBox(
                  width: 280,
                  child:
                      _ConsoleProjectCard(project: project, onScope: onScope),
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ConsoleProjectCard extends StatelessWidget {
  final DpProject project;
  final ValueChanged<String>? onScope;

  const _ConsoleProjectCard({required this.project, this.onScope});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => onScope?.call(project.id),
      child: DPGlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: dpText(context, project.title, strong: true)),
                _ProgressRing(value: project.progress),
              ],
            ),
            const SizedBox(height: 8),
            DPBudgetHealthBar(value: project.budgetHealth, label: 'Budget'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                DPStatusChip(label: project.status, tone: DpTone.info),
                DPStatusChip(
                  label: '${project.contractsCount} signed/active',
                  tone: DpTone.success,
                ),
                DPStatusChip(
                  label: 'Next ${project.shootDate}',
                  tone: DpTone.warning,
                ),
              ],
            ),
            const SizedBox(height: 10),
            DPHolographicButton(
              label: 'Open Project',
              icon: Icons.open_in_new_rounded,
              onTap: () => Navigator.pushNamed(
                context,
                DirectorProducerRoutes.projectDetail,
                arguments: project.id,
              ),
              secondary: true,
            ),
          ],
        ),
      ),
    );
  }
}

class DPProductionChecklist extends StatelessWidget {
  final DpProject project;
  final List<DpRequirement> requirements;
  final List<DpBooking> bookings;

  const DPProductionChecklist({
    super.key,
    required this.project,
    required this.requirements,
    required this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    final stages = [
      _StageSpec('Cast', 'Roles', Icons.theater_comedy_outlined),
      _StageSpec('Models', 'Models', Icons.style_outlined),
      _StageSpec('Locations', 'Locations', Icons.location_city_outlined),
      _StageSpec('Crew', 'Crew', Icons.groups_2_outlined),
      _StageSpec('Media & Equipment', 'Media & Equipment',
          Icons.video_camera_back_outlined),
      _StageSpec('Brands / Partners', 'Partners', Icons.campaign_outlined),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final stage in stages)
          _ProductionStageCard(
            stage: stage,
            project: project,
            requirements: requirements
                .where((requirement) => requirement.category == stage.category)
                .toList(),
            bookings: bookings
                .where((booking) => booking.requirement
                    .toLowerCase()
                    .contains(stage.lookupTerm.toLowerCase()))
                .toList(),
          ),
      ],
    );
  }
}

class _StageSpec {
  final String label;
  final String category;
  final IconData icon;

  const _StageSpec(this.label, this.category, this.icon);

  String get lookupTerm {
    if (category == 'Roles') return 'actor';
    if (category == 'Media & Equipment') return 'lighting';
    return label.split(' ').first;
  }

  String get monogram {
    final words = label.split(RegExp(r'[\s/]+')).where((w) => w.isNotEmpty);
    final letters = words.take(2).map((w) => w[0]).join();
    return letters.toUpperCase();
  }
}

class _ProductionStageCard extends StatelessWidget {
  final _StageSpec stage;
  final DpProject project;
  final List<DpRequirement> requirements;
  final List<DpBooking> bookings;

  const _ProductionStageCard({
    required this.stage,
    required this.project,
    required this.requirements,
    required this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    final needed = requirements.isEmpty ? 1 : requirements.length;
    final signed = bookings.where((booking) => booking.statusIndex >= 9).length;
    final shortlisted = requirements.fold<int>(
      0,
      (total, requirement) => total + requirement.candidateCount.clamp(0, 9),
    );
    final negotiating =
        bookings.where((booking) => booking.statusIndex > 0).length;
    final progress = (signed / needed).clamp(0.0, 1.0);
    final complete = progress >= 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: DPGlassCard(
        padding: const EdgeInsets.all(12),
        selected: complete,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    color: context.appColors.softSurface,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    stage.monogram,
                    style: AppTextStyles.caption.copyWith(
                      color: context.appColors.goldDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: dpText(
                    context,
                    '${stage.label} — $signed of $needed signed',
                    strong: true,
                  ),
                ),
                DPStatusChip(
                  label: complete ? 'Green' : 'In progress',
                  tone: complete ? DpTone.success : DpTone.warning,
                ),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: progress, minHeight: 3),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                DpDotLabel(
                    label: '$shortlisted shortlisted', tone: DpTone.info),
                DpDotLabel(
                  label: '$negotiating negotiating',
                  tone: negotiating > 0 ? DpTone.warning : DpTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DPHolographicButton(
                  label: 'Add requirement',
                  icon: Icons.add_task_outlined,
                  onTap: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.requirements,
                    arguments: project.id,
                  ),
                  secondary: true,
                ),
                DPHolographicButton(
                  label: 'Find ${stage.label}',
                  icon: Icons.manage_search_rounded,
                  onTap: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.marketplace,
                    arguments: {
                      'projectId': project.id,
                      'category':
                          stage.category == 'Roles' ? 'Talent' : stage.category,
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DPProjectBreadcrumbs extends StatelessWidget {
  final DpProject? project;
  final String current;

  const DPProjectBreadcrumbs({
    super.key,
    this.project,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final crumbs = [
      _Crumb('Console', DirectorProducerRoutes.console),
      if (project != null)
        _Crumb(
          project!.title,
          DirectorProducerRoutes.projectDetail,
          project!.id,
        ),
      _Crumb(current, null),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < crumbs.length; i++) ...[
            GestureDetector(
              onTap: crumbs[i].route == null
                  ? null
                  : () => Navigator.pushNamed(
                        context,
                        crumbs[i].route!,
                        arguments: crumbs[i].argument,
                      ),
              child: Text(
                crumbs[i].label,
                style: AppTextStyles.caption.copyWith(
                  color: crumbs[i].route == null
                      ? colors.textSecondary
                      : colors.goldDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (i != crumbs.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Icon(Icons.chevron_right_rounded,
                    size: 14, color: colors.iconMuted),
              ),
          ],
        ],
      ),
    );
  }
}

class _Crumb {
  final String label;
  final String? route;
  final Object? argument;

  const _Crumb(this.label, this.route, [this.argument]);
}

class DPDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const DPDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderMuted)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: colors.goldDark, size: 16),
            const SizedBox(width: 8),
          ],
          Expanded(child: dpText(context, label)),
          const SizedBox(width: 12),
          Flexible(child: dpText(context, value, strong: true)),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double value;

  const _ProgressRing({required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 4,
            color: colors.goldMid,
            backgroundColor: colors.borderMuted,
          ),
          Center(
            child: Text(
              '${(value * 100).round()}',
              style: AppTextStyles.caption.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DPProjectScopedShortlists extends StatelessWidget {
  final DpProject project;

  const DPProjectScopedShortlists({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final projects = ProjectsScope.maybeOf(context);
    final auth = AuthScope.maybeOf(context);
    if (projects == null || auth == null) {
      return dpText(context, 'Live shortlists unavailable.');
    }
    return FutureBuilder(
      future: projects.requirements(project.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return dpText(context, 'Loading live project requirements…');
        }
        if (snapshot.hasError) {
          return dpText(context, 'Could not load live project requirements.');
        }
        final requirements = (snapshot.data ?? const [])
            .map((requirement) => requirement.toDpRequirement())
            .toList();
        if (requirements.isEmpty) {
          return dpText(
            context,
            'No live requirements yet. Add requirements before shortlisting.',
          );
        }
        return FutureBuilder(
          future: auth.shortlistBundle(),
          builder: (context, shortlistSnapshot) {
            if (shortlistSnapshot.connectionState == ConnectionState.waiting) {
              return dpText(context, 'Loading live shortlist boards…');
            }
            if (shortlistSnapshot.hasError) {
              return dpText(context, 'Could not load live shortlist boards.');
            }
            final shortlists = shortlistSnapshot.data?.shortlists ?? const [];
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth > 900
                    ? (constraints.maxWidth - 24) / 3
                    : 292.0;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final requirement in requirements) ...[
                        SizedBox(
                          width: width.clamp(280.0, 380.0),
                          child: _RequirementShortlistColumn(
                            requirement: requirement,
                            shortlists: shortlists
                                .where(
                                  (board) =>
                                      board.requirementId == requirement.id,
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RequirementShortlistColumn extends StatelessWidget {
  final DpRequirement requirement;
  final List<MarketplaceShortlist> shortlists;

  const _RequirementShortlistColumn({
    required this.requirement,
    required this.shortlists,
  });

  @override
  Widget build(BuildContext context) {
    final items = shortlists.expand((board) => board.items).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    return DPSectionCard(
      title: requirement.title,
      icon: Icons.view_kanban_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              DPStatusChip(label: requirement.category, tone: DpTone.info),
              DPStatusChip(label: requirement.status, tone: DpTone.warning),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            dpText(
              context,
              'No saved shortlist items for this requirement yet.',
            )
          else
            for (final item in items.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _ScopedShortlistTile(item: item),
              ),
          const SizedBox(height: 10),
          DPHolographicButton(
            label: items.isEmpty ? 'Find live matches' : 'Add more matches',
            icon: Icons.manage_search_rounded,
            onTap: () => Navigator.pushNamed(
              context,
              DirectorProducerRoutes.marketplace,
            ),
            secondary: true,
          ),
        ],
      ),
    );
  }
}

class _ScopedShortlistTile extends StatelessWidget {
  final MarketplaceShortlistItem item;

  const _ScopedShortlistTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final candidate = item.listing.toCandidate();
    return DPGlassCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              dpText(context, candidate.name, strong: true),
              DPStatusChip(
                label: item.status == 'selected' ? 'Selected' : '#${item.rank}',
                tone:
                    item.status == 'selected' ? DpTone.success : DpTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 5),
          dpText(context, '${candidate.city} • ${candidate.rateRange}'),
          const SizedBox(height: 8),
          DPHolographicButton(
            label: 'Compare',
            icon: Icons.compare_arrows_rounded,
            onTap: () => Navigator.pushNamed(
              context,
              DirectorProducerRoutes.profile,
              arguments: candidate.id,
            ),
            secondary: true,
          ),
        ],
      ),
    );
  }
}
