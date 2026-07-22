import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../models/dp_booking.dart';
import '../models/dp_candidate.dart';
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
  final projects = DirectorProducerDemoData.projects;
  return projects.firstWhere(
    (project) => project.id == projectId,
    orElse: () => projects.first,
  );
}

String dpProjectTitleForId(String? projectId) =>
    dpProjectForId(projectId).title;

String dpProjectIdForTitle(String projectTitle) {
  return DirectorProducerDemoData.projects
      .firstWhere(
        (project) => project.title == projectTitle,
        orElse: () => DirectorProducerDemoData.projects.first,
      )
      .id;
}

List<DpRequirement> dpRequirementsForProject(String projectId) {
  return DirectorProducerDemoData.requirements
      .where((requirement) => requirement.projectId == projectId)
      .toList();
}

List<DpBooking> dpBookingsForProject(String projectId) {
  return DirectorProducerDemoData.bookings
      .where((booking) => booking.projectId == projectId)
      .toList();
}

List<DpContract> dpContractsForProject(String projectTitle) {
  return DirectorProducerDemoData.contracts
      .where((contract) => contract.project == projectTitle)
      .toList();
}

List<DpPayment> dpPaymentsForProject(String projectTitle) {
  final contractNames = dpContractsForProject(projectTitle)
      .map((contract) => contract.title)
      .toSet();
  final stakeholderNames = dpContractsForProject(projectTitle)
      .map((contract) => contract.candidate)
      .toSet();
  return DirectorProducerDemoData.payments
      .where(
        (payment) =>
            contractNames.any(payment.booking.contains) ||
            stakeholderNames.contains(payment.stakeholder),
      )
      .toList();
}

List<DpScheduleItem> dpScheduleForProject(String? projectTitle) {
  if (projectTitle == null) return DirectorProducerDemoData.schedule;
  return DirectorProducerDemoData.schedule
      .where((item) => item.project == projectTitle)
      .toList();
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
    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colors.surface.withValues(alpha: 0.52),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedProjectId,
          isExpanded: true,
          icon: Icon(Icons.expand_more_rounded, color: colors.iconMuted),
          style: AppTextStyles.label.copyWith(color: colors.textPrimary),
          onChanged: onChanged,
          items: [
            if (includeAll)
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All projects'),
              ),
            for (final project in DirectorProducerDemoData.projects)
              DropdownMenuItem<String?>(
                value: project.id,
                child: Text(project.title),
              ),
          ],
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

  @override
  void didUpdateWidget(covariant ProductionCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      setState(() => _mode = ProductionCalendarMode.today);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectTitle =
        widget.projectId == null ? null : dpProjectTitleForId(widget.projectId);
    final events = dpScheduleForProject(projectTitle);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CalendarToggle(
          value: _mode,
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 12),
        switch (_mode) {
          ProductionCalendarMode.today => _TodayTimeline(events: events),
          ProductionCalendarMode.month => _MonthCalendar(events: events),
          ProductionCalendarMode.list =>
            _AgendaList(events: events.take(widget.listLimit).toList()),
        },
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

  const _MonthCalendar({required this.events});

  @override
  Widget build(BuildContext context) {
    final days = List<int>.generate(35, (index) => index + 1);
    return GridView.builder(
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
        return _CalendarDayTile(day: day, events: matches);
      },
    );
  }
}

class _CalendarDayTile extends StatelessWidget {
  final int day;
  final List<DpScheduleItem> events;

  const _CalendarDayTile({required this.day, required this.events});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.surface.withValues(alpha: colors.isLight ? 0.72 : 0.18),
        border: Border.all(
          color: events.isEmpty ? colors.borderMuted : colors.goldMid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$day',
            style: AppTextStyles.caption.copyWith(
              color: colors.textPrimary,
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
                    color: event.conflict
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final project in DirectorProducerDemoData.projects) ...[
            SizedBox(
              width: 280,
              child: _ConsoleProjectCard(project: project, onScope: onScope),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
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
                Icon(stage.icon,
                    size: 18,
                    color: dpToneColor(
                        context, complete ? DpTone.success : DpTone.warning)),
                const SizedBox(width: 8),
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
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                DPStatusChip(
                    label: '$shortlisted shortlisted', tone: DpTone.info),
                DPStatusChip(
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
    final requirements = dpRequirementsForProject(project.id);
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
                  child: _RequirementShortlistColumn(requirement: requirement),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RequirementShortlistColumn extends StatelessWidget {
  final DpRequirement requirement;

  const _RequirementShortlistColumn({required this.requirement});

  @override
  Widget build(BuildContext context) {
    final items = DirectorProducerDemoData.candidates
        .where((candidate) => _matchesRequirement(candidate, requirement))
        .take(4)
        .toList();
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
          for (final candidate in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _ScopedCandidateTile(candidate: candidate),
            ),
        ],
      ),
    );
  }

  bool _matchesRequirement(DpCandidate candidate, DpRequirement requirement) {
    if (requirement.category == 'Roles') return candidate.category == 'Talent';
    if (requirement.category == candidate.category) return true;
    if (requirement.category == 'Media & Equipment') {
      return candidate.category == 'Media & Equipment';
    }
    return false;
  }
}

class _ScopedCandidateTile extends StatelessWidget {
  final DpCandidate candidate;

  const _ScopedCandidateTile({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return DPGlassCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: dpText(context, candidate.name, strong: true)),
              DPStatusChip(
                label: candidate.verified ? 'Verified' : 'Needs KYC',
                tone: candidate.verified ? DpTone.success : DpTone.warning,
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
