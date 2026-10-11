import 'package:flutter/material.dart';

import '../../../../core/director/director_dashboard_models.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/dashboard/dashboard_kit.dart';
import '../../models/dp_project.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Mini month calendar for the DP dashboard, with event dots computed
/// from the real production schedule (`GET /director/schedule`) —
/// no fabricated/sample data.
/// A real schedule-event create call, matching
/// `AuthController.createDirectorScheduleEvent`.
typedef DPAddPlanCallback = Future<void> Function({
  required String projectId,
  required String title,
  required String eventType,
  required DateTime startsAt,
  required DateTime endsAt,
  String? location,
  String? notes,
});

class DPMiniCalendarSection extends StatefulWidget {
  final List<DirectorScheduleEvent> events;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDaySelected;
  final bool decorated;

  /// Real DP projects to populate the inline "Add plan" project picker.
  /// Leave empty (the default) to hide the inline add-plan form.
  final List<DpProject> addPlanProjects;

  /// Called with the real event fields when the inline form is submitted.
  /// Must hit the live `POST /director/schedule` endpoint and let this
  /// widget's caller refresh [events] on success.
  final DPAddPlanCallback? onAddPlan;

  const DPMiniCalendarSection({
    super.key,
    required this.events,
    required this.selectedDate,
    required this.onDaySelected,
    this.decorated = true,
    this.addPlanProjects = const [],
    this.onAddPlan,
  });

  @override
  State<DPMiniCalendarSection> createState() => _DPMiniCalendarSectionState();
}

class _DPMiniCalendarSectionState extends State<DPMiniCalendarSection> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  @override
  void didUpdateWidget(covariant DPMiniCalendarSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate.year != widget.selectedDate.year ||
        oldWidget.selectedDate.month != widget.selectedDate.month) {
      _visibleMonth = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
      );
    }
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    final eventDays = <int>{
      for (final item in widget.events)
        if (item.startsAt != null &&
            item.startsAt!.year == _visibleMonth.year &&
            item.startsAt!.month == _visibleMonth.month)
          item.startsAt!.day,
    };

    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // Sunday-first grid; DateTime.weekday is 1=Mon..7=Sun.
    final leadingBlanks = firstOfMonth.weekday % 7;

    final days = <PortalCalendarDay>[
      for (var i = 0; i < leadingBlanks; i++)
        const PortalCalendarDay(day: 0, inCurrentMonth: false),
      for (var day = 1; day <= daysInMonth; day++)
        PortalCalendarDay(
          day: day,
          selected: widget.selectedDate.year == _visibleMonth.year &&
              widget.selectedDate.month == _visibleMonth.month &&
              widget.selectedDate.day == day,
          isToday: now.year == _visibleMonth.year &&
              now.month == _visibleMonth.month &&
              now.day == day,
          hasEvents: eventDays.contains(day),
          eventColor: colors.goldMid,
          onTap: () => widget.onDaySelected(
            DateTime(_visibleMonth.year, _visibleMonth.month, day),
          ),
        ),
    ];

    final calendar = PortalMiniCalendar(
      monthLabel:
          '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
      dayNames: const ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
      days: days,
      onPrevMonth: () => _shiftMonth(-1),
      onNextMonth: () => _shiftMonth(1),
      decorated: widget.decorated,
    );
    final onAddPlan = widget.onAddPlan;
    if (onAddPlan == null) return calendar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        calendar,
        _InlineAddPlanForm(
          projects: widget.addPlanProjects,
          onSubmit: onAddPlan,
        ),
      ],
    );
  }
}

/// Collapsed "+ Add plan" button that expands into a small inline form
/// (title, project, date/time, type, notes) and calls the real
/// create-schedule-event endpoint via [onSubmit] — no fabricated data.
class _InlineAddPlanForm extends StatefulWidget {
  final List<DpProject> projects;
  final DPAddPlanCallback onSubmit;

  const _InlineAddPlanForm({required this.projects, required this.onSubmit});

  @override
  State<_InlineAddPlanForm> createState() => _InlineAddPlanFormState();
}

class _InlineAddPlanFormState extends State<_InlineAddPlanForm> {
  bool _expanded = false;
  bool _saving = false;
  String? _error;
  final _title = TextEditingController();
  final _notes = TextEditingController();
  String? _projectId;
  String _eventType = 'shoot';
  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);

  static const _eventTypes = [
    'shoot',
    'audition',
    'meeting',
    'deadline',
    'payment',
    'contract',
    'task',
    'reminder',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.projects.isNotEmpty) _projectId = widget.projects.first.id;
  }

  @override
  void didUpdateWidget(covariant _InlineAddPlanForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_projectId == null && widget.projects.isNotEmpty) {
      _projectId = widget.projects.first.id;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _pickTime({required bool start}) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (value == null) return;
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  DateTime _combine(TimeOfDay value) => DateTime(
        _date.year,
        _date.month,
        _date.day,
        value.hour,
        value.minute,
      );

  Future<void> _submit() async {
    final projectId = _projectId;
    if (projectId == null) {
      setState(() => _error = 'Select a project.');
      return;
    }
    if (_title.text.trim().length < 2) {
      setState(() => _error = 'Add a plan title.');
      return;
    }
    final startsAt = _combine(_start);
    final endsAt = _combine(_end);
    if (!endsAt.isAfter(startsAt)) {
      setState(() => _error = 'End time must be after start time.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await widget.onSubmit(
        projectId: projectId,
        title: _title.text.trim(),
        eventType: _eventType,
        startsAt: startsAt,
        endsAt: endsAt,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _expanded = false;
        _title.clear();
        _notes.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not add plan: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (!_expanded) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.projects.isEmpty
                ? null
                : () => setState(() => _expanded = true),
            icon: const Icon(Icons.add_task_rounded, size: 16),
            label: Text(
              widget.projects.isEmpty ? 'No projects yet' : 'Add plan',
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Plan title',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _projectId,
            isExpanded: true,
            decoration:
                const InputDecoration(labelText: 'Project', isDense: true),
            items: widget.projects
                .map(
                  (project) => DropdownMenuItem(
                    value: project.id,
                    child: Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _projectId = value),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined, size: 15),
                label: Text(
                  '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickTime(start: true),
                icon: const Icon(Icons.schedule_outlined, size: 15),
                label: Text('Start ${_start.format(context)}'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickTime(start: false),
                icon: const Icon(Icons.schedule_send_outlined, size: 15),
                label: Text('End ${_end.format(context)}'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _eventType,
            decoration:
                const InputDecoration(labelText: 'Plan type', isDense: true),
            items: _eventTypes
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value[0].toUpperCase() + value.substring(1)),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _eventType = value ?? _eventType),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            minLines: 1,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              isDense: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: AppTextStyles.caption.copyWith(color: colors.danger),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_task_rounded, size: 16),
                  label: const Text('Save plan'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed:
                    _saving ? null : () => setState(() => _expanded = false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
