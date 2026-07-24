import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/location_owner_models.dart';
import '../routes/location_owner_routes.dart';
import '../widgets/location_owner_components.dart';
import '../widgets/location_owner_live.dart';

class LO03AvailabilityCalendarScreen extends StatefulWidget {
  const LO03AvailabilityCalendarScreen({super.key});

  @override
  State<LO03AvailabilityCalendarScreen> createState() =>
      _LO03AvailabilityCalendarScreenState();
}

class _LO03AvailabilityCalendarScreenState
    extends State<LO03AvailabilityCalendarScreen> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  Future<List<AvailabilityEntry>>? _future;
  List<AvailabilityEntry> _entries = const [];
  BookingsController? _bookings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null || identical(bookings, _bookings)) return;
    _bookings = bookings;
    _future = _load();
  }

  Future<List<AvailabilityEntry>> _load() async {
    final rows = await _bookings!.availability();
    if (mounted) setState(() => _entries = rows);
    return rows;
  }

  void _refresh() {
    if (_bookings == null) return;
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final selectedStatus = _statusForDate(_selectedDate);
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
              const _CalendarLegend(),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 14,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final date = DateUtils.dateOnly(
                      DateTime.now().add(Duration(days: index)),
                    );
                    return _DayTile(
                      date: date,
                      status: _statusForDate(date),
                      selected: DateUtils.isSameDay(_selectedDate, date),
                      onTap: () => setState(() => _selectedDate = date),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in [
                    LocationCalendarStatus.available,
                    LocationCalendarStatus.blocked,
                    LocationCalendarStatus.tentativeHold,
                  ])
                    CoreSecondaryButton(
                      icon: locationCalendarIcon(status),
                      label: locationCalendarLabel(status),
                      compact: true,
                      onTap: selectedStatus == LocationCalendarStatus.booked
                          ? null
                          : () => _saveStatus(status),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LocationSectionCard(
          title: 'Server calendar',
          icon: Icons.cloud_done_outlined,
          actionText: _future == null ? null : 'Refresh',
          onActionTap: _refresh,
          tone: LocationTone.blue,
          child: _future == null
              ? const CoreEmptyState(
                  icon: Icons.cloud_sync_outlined,
                  title: 'Sign in to load calendar',
                  message:
                      'Booking-generated and manual availability entries are fetched from the backend.',
                )
              : FutureBuilder<List<AvailabilityEntry>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return CoreEmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Calendar unavailable',
                        message: locationApiMessage(snapshot.error!),
                        actionLabel: 'Try again',
                        onAction: _refresh,
                      );
                    }
                    final rows = snapshot.data ?? const [];
                    if (rows.isEmpty) {
                      return const CoreEmptyState(
                        icon: Icons.event_available_outlined,
                        title: 'No saved entries',
                        message:
                            'Select a day and set it available, blocked or on hold.',
                      );
                    }
                    return Column(
                      children: [
                        for (final entry in rows.take(6))
                          LocationInfoRow(
                            icon: entry.status == 'booked'
                                ? Icons.lock_clock_outlined
                                : Icons.event_available_outlined,
                            label: readableLocationStatus(entry.status),
                            value:
                                '${DateFormat('MMM d, h:mm a').format(entry.startAt.toLocal())} - '
                                '${DateFormat('MMM d, h:mm a').format(entry.endAt.toLocal())}',
                          ),
                      ],
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        LocationTwoColumn(
          left: LocationSectionCard(
            title: 'Selected day',
            icon: Icons.event_note_outlined,
            tone: LocationTone.purple,
            child: _SelectedDayAgenda(
              date: _selectedDate,
              status: selectedStatus,
            ),
          ),
          right: LocationSectionCard(
            title: 'Conflict monitor',
            icon: Icons.warning_amber_outlined,
            tone: LocationTone.gold,
            child: Column(
              children: [
                LocationInfoRow(
                  icon: Icons.lock_clock_outlined,
                  label: 'Manual holds',
                  value:
                      '${_entries.where((item) => item.status == 'hold').length}',
                ),
                LocationInfoRow(
                  icon: Icons.event_available_outlined,
                  label: 'Secured bookings',
                  value: '${_securedBookingCount()}',
                ),
                LocationInfoRow(
                  icon: Icons.block_rounded,
                  label: 'Blocked entries',
                  value:
                      '${_entries.where((item) => item.status == 'blocked').length}',
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
  }

  Future<void> _saveStatus(LocationCalendarStatus status) async {
    final bookings = _bookings;
    final label = DateFormat('MMM d').format(_selectedDate);
    if (bookings == null) {
      locationSnack(context, 'Sign in to update availability for $label');
      return;
    }
    final start =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
            .toUtc();
    final end = start.add(const Duration(days: 1));
    try {
      final existing = _manualEntryForDate(_selectedDate);
      if (existing == null) {
        await bookings.createAvailability(
          startAt: start.toIso8601String(),
          endAt: end.toIso8601String(),
          status: _backendStatus(status),
          note: 'Location availability',
        );
      } else {
        await bookings.updateAvailability(
          entryId: existing.publicId,
          status: _backendStatus(status),
          note: 'Location availability',
        );
      }
      if (!mounted) return;
      setState(() => _future = _load());
      locationSnack(
        context,
        '$label marked ${locationCalendarLabel(status)}',
      );
    } catch (error) {
      if (!mounted) return;
      locationSnack(context, locationApiMessage(error));
    }
  }

  LocationCalendarStatus _statusForDate(DateTime date) {
    if (_bookings == null) {
      return LocationCalendarStatus.available;
    }
    final matching = _entries.where((entry) => _entryCoversDate(entry, date));
    if (matching.any((entry) => entry.status == 'booked')) {
      return LocationCalendarStatus.booked;
    }
    if (matching.any((entry) => entry.status == 'blocked')) {
      return LocationCalendarStatus.blocked;
    }
    if (matching.any((entry) => entry.status == 'hold')) {
      return LocationCalendarStatus.tentativeHold;
    }
    return LocationCalendarStatus.available;
  }

  AvailabilityEntry? _manualEntryForDate(DateTime date) {
    for (final entry in _entries) {
      if (entry.sourceBookingId == null && _entryCoversDate(entry, date)) {
        return entry;
      }
    }
    return null;
  }

  bool _entryCoversDate(AvailabilityEntry entry, DateTime date) {
    final dayStart = DateUtils.dateOnly(date);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return entry.startAt.toLocal().isBefore(dayEnd) &&
        entry.endAt.toLocal().isAfter(dayStart);
  }

  int _securedBookingCount() {
    return _entries
        .where((entry) => entry.status == 'booked')
        .map((entry) => entry.sourceBookingId ?? entry.publicId)
        .toSet()
        .length;
  }

  String _backendStatus(LocationCalendarStatus status) {
    return switch (status) {
      LocationCalendarStatus.available => 'available',
      LocationCalendarStatus.tentativeHold => 'hold',
      _ => 'blocked',
    };
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final status in [
            LocationCalendarStatus.available,
            LocationCalendarStatus.blocked,
            LocationCalendarStatus.tentativeHold,
            LocationCalendarStatus.booked,
          ])
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
  final DateTime date;
  final LocationCalendarStatus status;
  final bool selected;
  final VoidCallback onTap;

  const _DayTile({
    required this.date,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = locationCalendarColor(context, status);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 68,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          gradient: selected
              ? colors.activeChipGradient
              : colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : colors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('E').format(date).toUpperCase(),
              style: AppTextStyles.micro.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${date.day}',
              style: AppTextStyles.metricNumberCompact.copyWith(
                color: colors.textPrimary,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 5),
            Icon(locationCalendarIcon(status), color: color, size: 17),
          ],
        ),
      ),
    );
  }
}

class _SelectedDayAgenda extends StatelessWidget {
  final DateTime date;
  final LocationCalendarStatus status;

  const _SelectedDayAgenda({required this.date, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = locationCalendarColor(context, status);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: colors.isLight ? 0.12 : 0.18),
            border: Border.all(color: color.withValues(alpha: 0.34)),
          ),
          child: Icon(locationCalendarIcon(status), color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${DateFormat('MMM d').format(date)} · '
                '${locationCalendarLabel(status)}',
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                switch (status) {
                  LocationCalendarStatus.available =>
                    'Open for new location requests.',
                  LocationCalendarStatus.blocked =>
                    'Blocked by the owner for the full day.',
                  LocationCalendarStatus.tentativeHold =>
                    'A manual hold is preventing conflicting bookings.',
                  LocationCalendarStatus.booked =>
                    'Locked by an accepted booking and cannot be edited here.',
                  LocationCalendarStatus.maintenance =>
                    'Unavailable for property maintenance.',
                },
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
