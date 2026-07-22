import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dp_schedule_item.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_project_console_widgets.dart';
import '../widgets/dp_status_chip.dart';

class DPCalendarScheduleScreen extends StatefulWidget {
  const DPCalendarScheduleScreen({super.key});

  @override
  State<DPCalendarScheduleScreen> createState() =>
      _DPCalendarScheduleScreenState();
}

class _DPCalendarScheduleScreenState extends State<DPCalendarScheduleScreen> {
  String? _projectId;
  bool _synced = false;
  Timer? _syncResetTimer;

  @override
  void dispose() {
    _syncResetTimer?.cancel();
    super.dispose();
  }

  void _sync() {
    _syncResetTimer?.cancel();
    setState(() => _synced = true);
    _syncResetTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _synced = false);
    });
  }

  void _openCallSheet() {
    final projectTitle =
        _projectId == null ? null : dpProjectTitleForId(_projectId);
    final events = dpScheduleForProject(projectTitle);
    final todaysEvents = events
        .where((event) => event.date == 'Today' || event.date == 'Jul 21')
        .toList();
    final rows = todaysEvents.isEmpty ? events.take(3).toList() : todaysEvents;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CallSheet(events: rows),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPPageHeader(
          eyebrow: 'Production calendar',
          title: 'Calendar',
          actionLabel: _synced ? 'Synced ✓' : 'Sync',
          actionIcon: _synced ? Icons.check_rounded : Icons.sync_rounded,
          onActionTap: _sync,
        ),
        const SizedBox(height: 14),
        DPSectionCard(
          title: 'Production calendar',
          icon: Icons.calendar_month_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DPProjectScopePicker(
                selectedProjectId: _projectId,
                onChanged: (value) => setState(() => _projectId = value),
              ),
              const SizedBox(height: 12),
              ProductionCalendar(
                projectId: _projectId,
                initialMode: ProductionCalendarMode.today,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DPSectionCard(
          title: 'Schedule risk watch',
          icon: Icons.warning_amber_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dpBullet(context, 'Night exterior overlaps with crew hold.'),
              dpBullet(context, 'Drone ridge requires permit before Aug 8.'),
              dpBullet(context, 'Weather buffer suggested for mountain days.'),
              const SizedBox(height: 12),
              const DPStatusChip(
                label: '2 schedule risks',
                tone: DpTone.danger,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DPHolographicButton(
          label: 'Create Call Sheet',
          icon: Icons.description_outlined,
          onTap: _openCallSheet,
          secondary: true,
        ),
      ],
    );
  }
}

class _CallSheet extends StatelessWidget {
  final List<DpScheduleItem> events;

  const _CallSheet({required this.events});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final crew = <String>{for (final event in events) ...event.stakeholders};
    final label = events.isEmpty ? 'Today' : events.first.date;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: colors.border,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Call Sheet — $label',
                      style: AppTextStyles.cardTitle
                          .copyWith(color: colors.textPrimary, fontSize: 20),
                    ),
                    const SizedBox(height: 14),
                    if (events.isEmpty)
                      Text(
                        'No production events scheduled.',
                        style: AppTextStyles.smallMeta
                            .copyWith(color: colors.textSecondary),
                      )
                    else
                      for (final event in events)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DPGlassCard(
                            accentColor: event.conflict
                                ? colors.danger
                                : colors.goldDark,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${event.time} · ${event.location}',
                                  style: AppTextStyles.cardLabel.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${event.project} · ${event.status}',
                                  style: AppTextStyles.smallMeta
                                      .copyWith(color: colors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                    const SizedBox(height: 6),
                    _CallSheetBlock(
                      icon: Icons.wb_sunny_outlined,
                      title: 'Weather',
                      body: '31°C, clear — no rain cover needed.',
                    ),
                    const SizedBox(height: 12),
                    _CallSheetBlock(
                      icon: Icons.groups_outlined,
                      title: 'Crew on call',
                      body: crew.isEmpty
                          ? 'No crew assigned yet.'
                          : crew.join(', '),
                    ),
                    const SizedBox(height: 20),
                    DPHolographicButton(
                      label: 'Send to team',
                      icon: Icons.send_rounded,
                      onTap: () => Navigator.pop(context),
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

class _CallSheetBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _CallSheetBlock({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.goldDark, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.panelLabel
                      .copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTextStyles.smallMeta
                      .copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
