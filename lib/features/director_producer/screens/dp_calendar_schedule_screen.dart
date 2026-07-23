import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/director/director_dashboard_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
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
  Future<DirectorSchedule>? _scheduleFuture;
  bool _synced = false;
  Timer? _syncResetTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleFuture ??= _loadSchedule();
  }

  @override
  void dispose() {
    _syncResetTimer?.cancel();
    super.dispose();
  }

  void _sync() {
    _syncResetTimer?.cancel();
    setState(() {
      _synced = true;
      _scheduleFuture = _loadSchedule();
    });
    _syncResetTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _synced = false);
    });
  }

  Future<DirectorSchedule> _loadSchedule() {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) {
      throw StateError('Auth scope is missing.');
    }
    return auth.directorSchedule(projectId: _projectId);
  }

  Future<void> _openCallSheet() async {
    DirectorSchedule? schedule;
    try {
      schedule = await (_scheduleFuture ?? _loadSchedule());
    } catch (_) {
      if (!mounted) return;
      dpSnack(context, 'Could not load the live call sheet.');
      return;
    }
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CallSheet(callSheet: schedule!.callSheet),
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
                onChanged: (value) => setState(() {
                  _projectId = value;
                  _scheduleFuture = _loadSchedule();
                }),
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
          child: _ScheduleRiskWatch(future: _scheduleFuture),
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
  final DirectorCallSheet callSheet;

  const _CallSheet({required this.callSheet});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final events = callSheet.dpEvents;
    final crew = <String>{...callSheet.crew};
    final label = callSheet.label;
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
                      body: callSheet.weatherSummary,
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

class _ScheduleRiskWatch extends StatelessWidget {
  final Future<DirectorSchedule>? future;

  const _ScheduleRiskWatch({required this.future});

  @override
  Widget build(BuildContext context) {
    final value = future;
    if (value == null) {
      return dpText(context, 'Live schedule risks unavailable.');
    }
    return FutureBuilder<DirectorSchedule>(
      future: value,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return dpText(context, 'Loading live schedule risks…');
        }
        if (snapshot.hasError) {
          return dpText(context, 'Could not load live schedule risks.');
        }
        final risks = snapshot.data?.risks ?? const [];
        if (risks.isEmpty) {
          return const DPStatusChip(
            label: 'No live risk records',
            tone: DpTone.neutral,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final risk in risks.take(5)) ...[
              dpBullet(context, '${risk.projectTitle}: ${risk.message}'),
              const SizedBox(height: 6),
            ],
            DPStatusChip(
              label: '${risks.length} live schedule risks',
              tone: risks.any((risk) => risk.riskLevel == 'high')
                  ? DpTone.danger
                  : DpTone.warning,
            ),
          ],
        );
      },
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
