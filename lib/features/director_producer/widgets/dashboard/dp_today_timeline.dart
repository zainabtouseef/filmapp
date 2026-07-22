import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/director_producer_demo_data.dart';
import '../../models/dp_schedule_item.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_project_console_widgets.dart';
import '../dp_status_chip.dart';

/// Compact vertical "today, across every production" timeline.
class DPTodayTimeline extends StatelessWidget {
  const DPTodayTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final events = DirectorProducerDemoData.schedule
        .where((event) => event.date == 'Today' || event.date == 'Jul 21')
        .toList();
    final rows = events.isEmpty
        ? DirectorProducerDemoData.schedule.take(4).toList()
        : events;

    if (rows.isEmpty) {
      final colors = context.appColors;
      return Text(
        'No production events scheduled today.',
        style: AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          _TimelineRow(event: rows[i], isLast: i == rows.length - 1),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final DpScheduleItem event;
  final bool isLast;

  const _TimelineRow({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dotColor = event.conflict
        ? colors.danger
        : event.status.toLowerCase().contains('pending')
            ? colors.infoBlue
            : colors.goldMid;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.schedule),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 62,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  event.time,
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.4,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: colors.borderMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardLabel
                                .copyWith(color: colors.textPrimary),
                          ),
                        ),
                        DPStatusChip(
                          label: event.status,
                          tone: event.conflict
                              ? DpTone.danger
                              : dpToneForStatus(event.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${event.project} • ${event.stakeholders.join(', ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta
                          .copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
