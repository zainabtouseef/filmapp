import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/cards/cine_card_system.dart';
import '../../models/dp_schedule_item.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_glass_card.dart';

CineTone _eventTone(DpScheduleItem event) {
  if (event.conflict) return CineTone.critical;
  final status = event.status.toLowerCase();
  if (status.contains('confirmed')) return CineTone.positive;
  if (status.contains('pending') || status.contains('hold')) {
    return CineTone.information;
  }
  return CineTone.warning;
}

/// Today's production timeline — the next three events, with the full
/// schedule available from the parent section action.
class DPTodayTimeline extends StatelessWidget {
  final List<DpScheduleItem> events;

  const DPTodayTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final previewRows = events.take(3).toList();

    if (previewRows.isEmpty) {
      return Text(
        'No production events scheduled today.',
        style: AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
      );
    }

    return DPGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          for (var i = 0; i < previewRows.length; i++)
            _TimelineRow(event: previewRows[i], showDivider: i > 0),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final DpScheduleItem event;
  final bool showDivider;

  const _TimelineRow({required this.event, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = _eventTone(event);
    final color = cineToneColor(context, tone);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.schedule),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(top: BorderSide(color: colors.borderMuted))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 62,
              child: Text(
                event.time,
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${event.project} — ${event.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: colors.textPrimary,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.stakeholders.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMeta
                        .copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 5),
            Text(
              event.status,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
