import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import 'dp_holographic_button.dart';

/// Bookme.pk-style range picker: tap a start day, then tap an end day —
/// the range between them highlights live. Returns the picked range, or
/// null if dismissed without a full selection.
Future<DateTimeRange?> showDpDateRangeSheet(
  BuildContext context, {
  DateTime? initialStart,
  DateTime? initialEnd,
}) {
  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _DateRangeSheet(
      initialStart: initialStart,
      initialEnd: initialEnd,
    ),
  );
}

class _DateRangeSheet extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const _DateRangeSheet({this.initialStart, this.initialEnd});

  @override
  State<_DateRangeSheet> createState() => _DateRangeSheetState();
}

class _DateRangeSheetState extends State<_DateRangeSheet> {
  late DateTime _month;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    final anchor = _start ?? DateTime.now();
    _month = DateTime(anchor.year, anchor.month);
  }

  void _pick(DateTime day) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = day;
        _end = null;
      } else if (day.isBefore(_start!)) {
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday % 7;
    final duration = (_start != null && _end != null)
        ? _end!.difference(_start!).inDays + 1
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: colors.border,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  _monthLabel(_month),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cardTitle
                      .copyWith(color: colors.textPrimary, fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final w in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                Expanded(
                  child: Text(
                    w,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: firstWeekday + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday) return const SizedBox.shrink();
              final day =
                  DateTime(_month.year, _month.month, index - firstWeekday + 1);
              final isStart = _start != null && _isSameDay(day, _start!);
              final isEnd = _end != null && _isSameDay(day, _end!);
              final inRange = _start != null &&
                  _end != null &&
                  day.isAfter(_start!) &&
                  day.isBefore(_end!);
              final selected = isStart || isEnd;
              return GestureDetector(
                onTap: () => _pick(day),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: selected ? colors.goldGradient : null,
                    color: selected
                        ? null
                        : inRange
                            ? colors.softSurface
                            : Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: AppTextStyles.caption.copyWith(
                      color: selected ? colors.onGold : colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            duration == null
                ? (_start == null
                    ? 'Tap a start date, then an end date.'
                    : 'Now tap an end date.')
                : '$duration day${duration == 1 ? '' : 's'} selected',
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          DPHolographicButton(
            label: 'Done',
            icon: Icons.check_rounded,
            onTap: _start == null
                ? null
                : () => Navigator.pop(
                      context,
                      DateTimeRange(start: _start!, end: _end ?? _start!),
                    ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthLabel(DateTime month) {
    const names = [
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
    return '${names[month.month - 1]} ${month.year}';
  }
}
