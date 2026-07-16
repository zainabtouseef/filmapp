import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/crew_services_demo_data.dart';
import '../models/crew_services_models.dart';
import '../routes/crew_services_routes.dart';
import '../widgets/crew_services_components.dart';

class CR04AvailabilityCalendarScreen extends StatefulWidget {
  const CR04AvailabilityCalendarScreen({super.key});

  @override
  State<CR04AvailabilityCalendarScreen> createState() =>
      _CR04AvailabilityCalendarScreenState();
}

class _CR04AvailabilityCalendarScreenState
    extends State<CR04AvailabilityCalendarScreen> {
  int _selectedDay = 3;

  @override
  Widget build(BuildContext context) {
    final store = CrewServicesDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final status =
            store.calendar[_selectedDay] ?? CrewAvailabilityStatus.available;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CrewSectionCard(
              title: 'Availability controls',
              icon: Icons.calendar_month_outlined,
              selected: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CrewCalendarLegend(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      separatorBuilder: (_, __) => const SizedBox(width: 9),
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final dayStatus = store.calendar[day] ??
                            CrewAvailabilityStatus.available;
                        return _DayTile(
                          day: day,
                          status: dayStatus,
                          selected: _selectedDay == day,
                          onTap: () => setState(() => _selectedDay = day),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in CrewAvailabilityStatus.values)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            store.setCalendarStatus(_selectedDay, option);
                            crewSnack(
                              context,
                              'Jul $_selectedDay set to ${crewAvailabilityLabel(option)}',
                            );
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Center(
                              child: StatusChip(
                                label:
                                    crewAvailabilityLabel(option).toUpperCase(),
                                icon: crewAvailabilityIcon(option),
                                color: status == option
                                    ? crewAvailabilityColor(context, option)
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CrewTwoColumn(
              left: CrewSectionCard(
                title: 'Selected day agenda',
                icon: Icons.event_note_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CrewInfoRow(
                      icon: crewAvailabilityIcon(status),
                      label: 'Jul $_selectedDay',
                      value: crewAvailabilityLabel(status),
                    ),
                    CrewInfoRow(
                      icon: Icons.movie_creation_outlined,
                      label: 'Linked booking',
                      value: status == CrewAvailabilityStatus.booked
                          ? (store.activeBookingLabel ?? 'Booked (unlinked)')
                          : 'None',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _agendaText(status),
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CoreSecondaryButton(
                            icon: Icons.block_rounded,
                            label: 'Block',
                            compact: true,
                            onTap: () => store.setCalendarStatus(
                              _selectedDay,
                              CrewAvailabilityStatus.unavailable,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CorePrimaryButton(
                            icon: Icons.check_circle_outline,
                            label: 'Available',
                            compact: true,
                            onTap: () => store.setCalendarStatus(
                              _selectedDay,
                              CrewAvailabilityStatus.available,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              right: CrewSectionCard(
                title: 'Conflict monitor',
                icon: Icons.warning_amber_outlined,
                child: Column(
                  children: [
                    CrewInfoRow(
                      icon: Icons.event_available_outlined,
                      label: 'Booked',
                      value:
                          '${_count(store, CrewAvailabilityStatus.booked)} days',
                    ),
                    CrewInfoRow(
                      icon: Icons.hourglass_top_rounded,
                      label: 'Tentative',
                      value:
                          '${_count(store, CrewAvailabilityStatus.tentative)} days',
                    ),
                    CrewInfoRow(
                      icon: Icons.block_rounded,
                      label: 'Unavailable',
                      value:
                          '${_count(store, CrewAvailabilityStatus.unavailable)} days',
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.move_to_inbox_outlined,
                      label: 'Inspect requests',
                      compact: true,
                      onTap: () => Navigator.pushNamed(
                        context,
                        CrewServicesRoutes.requests,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  int _count(CrewServicesDemoStore store, CrewAvailabilityStatus status) {
    return store.calendar.values.where((item) => item == status).length;
  }

  String _agendaText(CrewAvailabilityStatus status) {
    return switch (status) {
      CrewAvailabilityStatus.available =>
        'Open for new director requests and marketplace discovery.',
      CrewAvailabilityStatus.unavailable =>
        'Private block; requests cannot target this day.',
      CrewAvailabilityStatus.tentative =>
        'Soft hold until producer confirms contract terms.',
      CrewAvailabilityStatus.booked =>
        'Secured booking automatically blocks this day.',
    };
  }
}

class _CrewCalendarLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final status in CrewAvailabilityStatus.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: StatusChip(
                label: crewAvailabilityLabel(status).toUpperCase(),
                icon: crewAvailabilityIcon(status),
                color: crewAvailabilityColor(context, status),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final int day;
  final CrewAvailabilityStatus status;
  final bool selected;
  final VoidCallback onTap;

  const _DayTile({
    required this.day,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = crewAvailabilityColor(context, status);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 76,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? color : colors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'JUL',
              style: AppTextStyles.micro.copyWith(
                color: colors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$day',
              style: AppTextStyles.metricNumberCompact.copyWith(
                color: colors.textPrimary,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 6),
            Icon(crewAvailabilityIcon(status), color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
