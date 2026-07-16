import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../widgets/dp_empty_state.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPCalendarScheduleScreen extends StatelessWidget {
  const DPCalendarScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final schedule = DirectorProducerDemoData.schedule.take(9).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.sync_rounded,
          label: 'Sync',
          onTap: () => dpSnack(context, 'Calendar sync simulated'),
        ),
        const SizedBox(height: 8),
        DPTwoColumn(
          left: DPSectionCard(
            title: 'Shoot Timeline',
            icon: Icons.timeline_rounded,
            child: schedule.isEmpty
                ? const DPEmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'No shoot days scheduled',
                    message: 'Confirmed shoot days will appear here.',
                  )
                : Column(
                    children: [
                      for (var i = 0; i < schedule.length; i++)
                        _ScheduleRow(
                          date: schedule[i].date,
                          time: schedule[i].time,
                          project: schedule[i].project,
                          location: schedule[i].location,
                          status: schedule[i].status,
                          conflict: schedule[i].conflict,
                          showDivider: i != schedule.length - 1,
                        ),
                    ],
                  ),
          ),
          right: DPSectionCard(
            title: 'Conflict Watch',
            icon: Icons.warning_amber_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dpBullet(context,
                    'Night exterior overlaps with line producer hold.'),
                dpBullet(context, 'Drone ridge needs permit before Aug 8.'),
                dpBullet(context, 'Weather buffer suggested for Hunza pass.'),
                const SizedBox(height: 12),
                const DPStatusChip(
                    label: '2 schedule risks', tone: DpTone.danger),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String date;
  final String time;
  final String project;
  final String location;
  final String status;
  final bool conflict;
  final bool showDivider;

  const _ScheduleRow({
    required this.date,
    required this.time,
    required this.project,
    required this.location,
    required this.status,
    required this.conflict,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          left: conflict
              ? BorderSide(color: colors.danger, width: 3)
              : BorderSide.none,
          bottom: showDivider
              ? BorderSide(color: colors.borderMuted)
              : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: conflict ? 9 : 0),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date.split(' ').first.toUpperCase(),
                    style:
                        AppTextStyles.micro.copyWith(color: colors.goldDark),
                  ),
                  Text(
                    date.split(' ').last,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dpText(context, project, strong: true),
                  const SizedBox(height: 3),
                  dpText(context, '$time - $location'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DPStatusChip(
              label: status,
              tone: conflict ? DpTone.danger : DpTone.info,
            ),
          ],
        ),
      ),
    );
  }
}
