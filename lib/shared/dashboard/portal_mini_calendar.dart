import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/cine_card_system.dart';

/// A day in [PortalMiniCalendar]'s grid.
class PortalCalendarDay {
  final int day;
  final bool inCurrentMonth;
  final bool selected;
  final bool isToday;
  final bool hasEvents;
  final Color? eventColor;
  final VoidCallback? onTap;

  const PortalCalendarDay({
    required this.day,
    this.inCurrentMonth = true,
    this.selected = false,
    this.isToday = false,
    this.hasEvents = false,
    this.eventColor,
    this.onTap,
  });
}

/// Dashboard-kit mini month calendar — prev/next month controls, a 7-column
/// day grid, and small event-dot markers. No existing analog in the app
/// before this rollout.
class PortalMiniCalendar extends StatelessWidget {
  final String monthLabel;
  final List<String> dayNames;
  final List<PortalCalendarDay> days;
  final VoidCallback? onPrevMonth;
  final VoidCallback? onNextMonth;

  /// Wrap in the standard [CardShell] chrome (default). Pass `false` when
  /// embedding inside another surface (e.g. [PortalGlassWidgetCard]) that
  /// already provides its own background/border.
  final bool decorated;

  const PortalMiniCalendar({
    super.key,
    required this.monthLabel,
    required this.dayNames,
    required this.days,
    this.onPrevMonth,
    this.onNextMonth,
    this.decorated = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              monthLabel,
              style: AppTextStyles.sectionSerifHeading
                  .copyWith(color: colors.textPrimary, fontSize: 15),
            ),
            const Spacer(),
            _NavButton(icon: Icons.chevron_left_rounded, onTap: onPrevMonth),
            const SizedBox(width: 6),
            _NavButton(icon: Icons.chevron_right_rounded, onTap: onNextMonth),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // A fixed, compact aspect ratio — GridView.count's implicit 1.0
        // default made cells scale their HEIGHT off the (often very wide)
        // parent width, ballooning the whole grid with empty space.
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            childAspectRatio: 1.25,
          ),
          children: [
            for (final name in dayNames)
              Center(
                child: Text(
                  name,
                  style: AppTextStyles.micro.copyWith(
                    color: colors.textTertiary,
                    fontSize: 9,
                  ),
                ),
              ),
            for (final day in days) _DayCell(day: day),
          ],
        ),
      ],
    );
    if (!decorated) return body;
    return CardShell(child: body);
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, size: 15, color: colors.textSecondary),
        style: IconButton.styleFrom(
          side: BorderSide(color: colors.border),
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final PortalCalendarDay day;

  const _DayCell({required this.day});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dim = !day.inCurrentMonth;
    if (day.day <= 0) return const SizedBox.shrink();
    return InkWell(
      onTap: day.onTap,
      borderRadius: BorderRadius.circular(9),
      hoverColor: colors.goldSoft,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: day.selected
              ? colors.goldMid
              : day.isToday
                  ? colors.goldSoft
                  : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: AppTextStyles.smallMeta.copyWith(
                fontWeight: day.isToday || day.selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: day.selected
                    ? colors.onGold
                    : dim
                        ? colors.textTertiary.withValues(alpha: 0.5)
                        : colors.textPrimary,
              ),
            ),
            if (day.hasEvents)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: day.eventColor ?? colors.goldMid,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
