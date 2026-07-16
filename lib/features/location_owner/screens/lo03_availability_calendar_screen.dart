import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/location_owner_demo_data.dart';
import '../models/location_owner_models.dart';
import '../routes/location_owner_routes.dart';
import '../widgets/location_owner_components.dart';

class LO03AvailabilityCalendarScreen extends StatefulWidget {
  const LO03AvailabilityCalendarScreen({super.key});

  @override
  State<LO03AvailabilityCalendarScreen> createState() =>
      _LO03AvailabilityCalendarScreenState();
}

class _LO03AvailabilityCalendarScreenState
    extends State<LO03AvailabilityCalendarScreen> {
  int _selectedDay = 3;

  @override
  Widget build(BuildContext context) {
    final store = LocationOwnerDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final selectedStatus =
            store.calendar[_selectedDay] ?? LocationCalendarStatus.available;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocationSectionCard(
              title: 'Availability controls',
              icon: Icons.calendar_month_outlined,
              selected: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CalendarLegend(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      separatorBuilder: (_, __) => const SizedBox(width: 9),
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final status = store.calendar[day] ??
                            LocationCalendarStatus.available;
                        return _DayTile(
                          day: day,
                          status: status,
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
                      for (final status in LocationCalendarStatus.values)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            store.setCalendarStatus(_selectedDay, status);
                            locationSnack(
                              context,
                              'Jul $_selectedDay set to ${locationCalendarLabel(status)}',
                            );
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Center(
                              child: StatusChip(
                                label:
                                    locationCalendarLabel(status).toUpperCase(),
                                icon: locationCalendarIcon(status),
                                color: selectedStatus == status
                                    ? locationCalendarColor(context, status)
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
            LocationTwoColumn(
              left: LocationSectionCard(
                title: 'Selected day agenda',
                icon: Icons.event_note_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: locationCalendarColor(
                              context,
                              selectedStatus,
                            ).withValues(alpha: colors.isLight ? 0.12 : 0.18),
                            border: Border.all(
                              color: locationCalendarColor(
                                context,
                                selectedStatus,
                              ).withValues(alpha: 0.34),
                            ),
                          ),
                          child: Icon(
                            locationCalendarIcon(selectedStatus),
                            color:
                                locationCalendarColor(context, selectedStatus),
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jul $_selectedDay - ${locationCalendarLabel(selectedStatus)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.cardLabel.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _agendaText(selectedStatus),
                                style: AppTextStyles.smallMeta.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _AgendaActionRow(
                      status: selectedStatus,
                      selectedDay: _selectedDay,
                    ),
                  ],
                ),
              ),
              right: LocationSectionCard(
                title: 'Conflict monitor',
                icon: Icons.warning_amber_outlined,
                child: Column(
                  children: [
                    LocationInfoRow(
                      icon: Icons.lock_clock_outlined,
                      label: 'Tentative holds',
                      value:
                          '${_count(store, LocationCalendarStatus.tentativeHold)}',
                    ),
                    LocationInfoRow(
                      icon: Icons.event_available_outlined,
                      label: 'Secured bookings',
                      value: '${_count(store, LocationCalendarStatus.booked)}',
                    ),
                    LocationInfoRow(
                      icon: Icons.handyman_outlined,
                      label: 'Maintenance days',
                      value:
                          '${_count(store, LocationCalendarStatus.maintenance)}',
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.search_rounded,
                      label: 'Inspect requests',
                      compact: true,
                      onTap: () => Navigator.pushNamed(
                        context,
                        LocationOwnerRoutes.requests,
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

  int _count(LocationOwnerDemoStore store, LocationCalendarStatus status) {
    return store.calendar.values.where((item) => item == status).length;
  }

  String _agendaText(LocationCalendarStatus status) {
    return switch (status) {
      LocationCalendarStatus.available =>
        'Open for director discovery and instant shortlist.',
      LocationCalendarStatus.blocked =>
        'Private hold. This day will not appear in marketplace search.',
      LocationCalendarStatus.maintenance =>
        'Maintenance flag is visible to admin and hidden from director booking.',
      LocationCalendarStatus.tentativeHold =>
        'A producer has a soft hold; confirm or release before midnight.',
      LocationCalendarStatus.booked =>
        'Secured booking auto-blocked this date and linked to contract.',
    };
  }
}

class _CalendarLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final status in LocationCalendarStatus.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: StatusChip(
                label: locationCalendarLabel(status).toUpperCase(),
                icon: locationCalendarIcon(status),
                color: locationCalendarColor(context, status),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final int day;
  final LocationCalendarStatus status;
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
    final color = locationCalendarColor(context, status);
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
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.18), blurRadius: 20)
                ]
              : null,
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
            Icon(locationCalendarIcon(status), color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _AgendaActionRow extends StatelessWidget {
  final LocationCalendarStatus status;
  final int selectedDay;

  const _AgendaActionRow({
    required this.status,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    final store = LocationOwnerDemoStore.instance;
    return Row(
      children: [
        Expanded(
          child: CoreSecondaryButton(
            icon: Icons.block_rounded,
            label: 'Block',
            compact: true,
            onTap: () {
              store.setCalendarStatus(
                selectedDay,
                LocationCalendarStatus.blocked,
              );
              locationSnack(context, 'Day blocked');
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CoreSecondaryButton(
            icon: Icons.hourglass_top_rounded,
            label: 'Hold',
            compact: true,
            onTap: () {
              store.setCalendarStatus(
                selectedDay,
                LocationCalendarStatus.tentativeHold,
              );
              locationSnack(context, 'Tentative hold saved');
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CorePrimaryButton(
            icon: status == LocationCalendarStatus.booked
                ? Icons.open_in_new_rounded
                : Icons.check_circle_outline_rounded,
            label: status == LocationCalendarStatus.booked ? 'Booking' : 'Open',
            compact: true,
            onTap: () {
              if (status == LocationCalendarStatus.booked) {
                Navigator.pushNamed(context, LocationOwnerRoutes.requests);
              } else {
                store.setCalendarStatus(
                  selectedDay,
                  LocationCalendarStatus.available,
                );
                locationSnack(context, 'Day available');
              }
            },
          ),
        ),
      ],
    );
  }
}
