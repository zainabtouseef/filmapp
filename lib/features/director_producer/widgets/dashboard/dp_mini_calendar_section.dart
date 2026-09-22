import 'package:flutter/material.dart';

import '../../../../core/director/director_dashboard_models.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../shared/dashboard/dashboard_kit.dart';

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
/// from the real production timeline (`dashboard.timeline[].startsAt`) —
/// no fabricated/sample data.
class DPMiniCalendarSection extends StatefulWidget {
  final DirectorDashboard dashboard;

  const DPMiniCalendarSection({super.key, required this.dashboard});

  @override
  State<DPMiniCalendarSection> createState() => _DPMiniCalendarSectionState();
}

class _DPMiniCalendarSectionState extends State<DPMiniCalendarSection> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
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
      for (final item in widget.dashboard.timeline)
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
          isToday: now.year == _visibleMonth.year &&
              now.month == _visibleMonth.month &&
              now.day == day,
          hasEvents: eventDays.contains(day),
          eventColor: colors.goldMid,
        ),
    ];

    return PortalMiniCalendar(
      monthLabel:
          '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
      dayNames: const ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
      days: days,
      onPrevMonth: () => _shiftMonth(-1),
      onNextMonth: () => _shiftMonth(1),
    );
  }
}
