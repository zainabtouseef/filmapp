import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/bookings/booking_models.dart' as booking_models;
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/actor_talent_models.dart';
import '../widgets/actor_talent_components.dart';

/// AT-04 Availability Calendar (own)
class AT04AvailabilityCalendarScreen extends StatefulWidget {
  const AT04AvailabilityCalendarScreen({super.key});

  @override
  State<AT04AvailabilityCalendarScreen> createState() =>
      _AT04AvailabilityCalendarScreenState();
}

class _AT04AvailabilityCalendarScreenState
    extends State<AT04AvailabilityCalendarScreen> {
  DateTime selectedDate = DateTime.now();
  Future<List<booking_models.AvailabilityEntry>>? _availabilityFuture;
  List<booking_models.AvailabilityEntry> _liveEntries = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bookings = BookingsScope.maybeOf(context);
    if (bookings != null) {
      _availabilityFuture ??= _loadAvailability(bookings);
    }
  }

  Future<List<booking_models.AvailabilityEntry>> _loadAvailability(
    BookingsController bookings,
  ) async {
    final rows = await bookings.availability();
    if (mounted) setState(() => _liveEntries = rows);
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final hasLiveAvailability = _availabilityFuture != null;
    return Column(
      children: [
        ActorSectionCard(
          title: 'Calendar Controls',
          icon: Icons.calendar_month_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateStrip(
                selectedDate: selectedDate,
                statuses: _dateStatuses(),
                onSelected: (date) => setState(() => selectedDate = date),
              ),
              const SizedBox(height: 12),
              _Legend(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: 'Availability Entries',
          icon: Icons.cloud_done_outlined,
          actionText: hasLiveAvailability ? 'Refresh' : null,
          onActionTap: _refreshAvailability,
          child: hasLiveAvailability
              ? FutureBuilder<List<booking_models.AvailabilityEntry>>(
                  future: _availabilityFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CoreEmptyState(
                        icon: Icons.hourglass_top_rounded,
                        title: 'Loading availability',
                        message: 'Fetching your server calendar.',
                      );
                    }
                    final rows = snapshot.data ?? const [];
                    if (snapshot.hasError) {
                      return Column(
                        children: [
                          const CoreEmptyState(
                            icon: Icons.cloud_off_outlined,
                            title: 'Could not load availability',
                            message: 'Check your connection and try again.',
                          ),
                          const SizedBox(height: 8),
                          CoreSecondaryButton(
                            icon: Icons.refresh_rounded,
                            label: 'Try again',
                            compact: true,
                            onTap: _refreshAvailability,
                          ),
                        ],
                      );
                    }
                    if (rows.isEmpty) {
                      return const CoreEmptyState(
                        icon: Icons.event_available_outlined,
                        title: 'No live entries yet',
                        message: 'Use Edit on a selected day to save one.',
                      );
                    }
                    return Column(
                      children: [
                        for (final row in rows.take(5))
                          ActorInfoRow(
                            icon: row.status == 'booked'
                                ? Icons.lock_clock_outlined
                                : Icons.event_available_outlined,
                            label: row.status,
                            value:
                                '${DateFormat('MMM d, h:mm a').format(row.startAt.toLocal())} - ${DateFormat('MMM d, h:mm a').format(row.endAt.toLocal())}',
                          ),
                      ],
                    );
                  },
                )
              : const CoreEmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Sign in to manage availability',
                  message:
                      'Calendar entries are saved and loaded from the server.',
                ),
        ),
        const SizedBox(height: 12),
        ActorTwoColumn(
          left: ActorSectionCard(
            title: 'Selected Day Agenda',
            icon: Icons.event_note_outlined,
            actionText: hasLiveAvailability ? 'Edit' : null,
            onActionTap: hasLiveAvailability
                ? () => _openStatusSheet(context, selectedDate)
                : null,
            child: _Agenda(
              date: selectedDate,
              status: _statusForDate(selectedDate),
            ),
          ),
          right: ActorSectionCard(
            title: 'Travel Limits',
            icon: Icons.flight_takeoff_outlined,
            tone: ActorTone.blue,
            child: Column(
              children: [
                const CoreEmptyState(
                  icon: Icons.flight_takeoff_outlined,
                  title: 'Travel preferences need live profile fields',
                  message:
                      'No dummy city/radius values are shown. Connect profile travel preferences when the backend exposes them.',
                ),
                const SizedBox(height: 8),
                ActorInfoRow(
                  icon: Icons.lock_clock_outlined,
                  label: 'Secured bookings',
                  value: _securedBookingCount().toString(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _refreshAvailability() {
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null) return;
    setState(() => _availabilityFuture = _loadAvailability(bookings));
  }

  void _openStatusSheet(BuildContext context, DateTime date) {
    showActorSheet(
      context,
      title: 'Set ${DateFormat('MMM d').format(date)} status',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final status in ActorAvailabilityStatus.values)
            if (status != ActorAvailabilityStatus.booked)
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _saveLiveAvailability(date, status);
                },
                icon: Icon(_statusIcon(status), size: 18),
                label: Text(_statusLabel(status)),
              ),
        ],
      ),
    );
  }

  Future<void> _saveLiveAvailability(
    DateTime date,
    ActorAvailabilityStatus status,
  ) async {
    final start = DateTime(date.year, date.month, date.day, 9).toUtc();
    final end = start.add(const Duration(hours: 8));
    final label = DateFormat('MMM d').format(date);
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null) {
      actorSnack(context, 'Sign in to save $label availability');
      return;
    }
    try {
      final existing = _manualEntryForDate(date);
      if (existing == null) {
        await bookings.createAvailability(
          startAt: start.toIso8601String(),
          endAt: end.toIso8601String(),
          status: _backendStatus(status),
          note: 'Talent availability',
        );
      } else {
        await bookings.updateAvailability(
          entryId: existing.publicId,
          status: _backendStatus(status),
          note: 'Talent availability',
        );
      }
      if (!mounted) return;
      setState(() {
        _availabilityFuture = _loadAvailability(bookings);
      });
      actorSnack(context, '$label marked ${_statusLabel(status)}');
    } catch (error) {
      if (!mounted) return;
      actorSnack(context, '$error');
    }
  }

  String _backendStatus(ActorAvailabilityStatus status) {
    return switch (status) {
      ActorAvailabilityStatus.available => 'available',
      ActorAvailabilityStatus.tentative => 'hold',
      ActorAvailabilityStatus.booked => 'hold',
      ActorAvailabilityStatus.unavailable => 'blocked',
    };
  }

  Map<DateTime, ActorAvailabilityStatus> _dateStatuses() {
    return {
      for (var offset = 0; offset < 14; offset++)
        DateUtils.dateOnly(DateTime.now().add(Duration(days: offset))):
            _statusForDate(DateTime.now().add(Duration(days: offset))),
    };
  }

  ActorAvailabilityStatus _statusForDate(DateTime date) {
    if (BookingsScope.maybeOf(context) == null) {
      return ActorAvailabilityStatus.available;
    }
    final matching =
        _liveEntries.where((entry) => _entryCoversDate(entry, date));
    if (matching.any((entry) => entry.status == 'booked')) {
      return ActorAvailabilityStatus.booked;
    }
    if (matching.any((entry) => entry.status == 'blocked')) {
      return ActorAvailabilityStatus.unavailable;
    }
    if (matching.any((entry) => entry.status == 'hold')) {
      return ActorAvailabilityStatus.tentative;
    }
    return ActorAvailabilityStatus.available;
  }

  booking_models.AvailabilityEntry? _manualEntryForDate(DateTime date) {
    for (final entry in _liveEntries) {
      if (entry.sourceBookingId == null && _entryCoversDate(entry, date)) {
        return entry;
      }
    }
    return null;
  }

  bool _entryCoversDate(
    booking_models.AvailabilityEntry entry,
    DateTime date,
  ) {
    final dayStart = DateUtils.dateOnly(date);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final entryStart = entry.startAt.toLocal();
    final entryEnd = entry.endAt.toLocal();
    return entryStart.isBefore(dayEnd) && entryEnd.isAfter(dayStart);
  }

  int _securedBookingCount() {
    return _liveEntries
        .where((entry) => entry.status == 'booked')
        .map((entry) => entry.sourceBookingId ?? entry.publicId)
        .toSet()
        .length;
  }
}

class _DateStrip extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, ActorAvailabilityStatus> statuses;
  final ValueChanged<DateTime> onSelected;

  const _DateStrip({
    required this.selectedDate,
    required this.statuses,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = DateUtils.dateOnly(
            DateTime.now().add(Duration(days: index)),
          );
          final status = statuses[date] ?? ActorAvailabilityStatus.available;
          final active = DateUtils.isSameDay(date, selectedDate);
          return GestureDetector(
            onTap: () => onSelected(date),
            child: Container(
              width: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: active
                    ? context.appColors.goldGradient
                    : context.appColors.inactiveChipGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active
                      ? context.appColors.goldMid
                      : context.appColors.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: AppTextStyles.micro.copyWith(
                      color: active
                          ? context.appColors.onGold
                          : context.appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('d').format(date),
                    style: AppTextStyles.cardLabel.copyWith(
                      color: active
                          ? context.appColors.onGold
                          : context.appColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Icon(
                    _statusIcon(status),
                    color: active
                        ? context.appColors.onGold
                        : _statusColor(context, status),
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final status in ActorAvailabilityStatus.values)
          StatusChip(
            label: _statusLabel(status),
            icon: _statusIcon(status),
            color: _statusColor(context, status),
          ),
      ],
    );
  }
}

class _Agenda extends StatelessWidget {
  final DateTime date;
  final ActorAvailabilityStatus status;

  const _Agenda({
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActorInfoRow(
          icon: _statusIcon(status),
          label: DateFormat('EEEE, MMM d').format(date),
          value: _statusLabel(status),
        ),
        const ActorInfoRow(
          icon: Icons.schedule_rounded,
          label: 'Timezone',
          value: 'Asia/Karachi',
        ),
        ActorInfoRow(
          icon: Icons.warning_amber_rounded,
          label: 'Conflict check',
          value: status == ActorAvailabilityStatus.booked
              ? 'Secured booking'
              : 'No conflict',
        ),
      ],
    );
  }
}

String _statusLabel(ActorAvailabilityStatus status) {
  return switch (status) {
    ActorAvailabilityStatus.available => 'Available',
    ActorAvailabilityStatus.tentative => 'Tentative',
    ActorAvailabilityStatus.booked => 'Booked',
    ActorAvailabilityStatus.unavailable => 'Unavailable',
  };
}

IconData _statusIcon(ActorAvailabilityStatus status) {
  return switch (status) {
    ActorAvailabilityStatus.available => Icons.check_circle_outline,
    ActorAvailabilityStatus.tentative => Icons.hourglass_top_rounded,
    ActorAvailabilityStatus.booked => Icons.lock_clock_outlined,
    ActorAvailabilityStatus.unavailable => Icons.block_rounded,
  };
}

Color _statusColor(BuildContext context, ActorAvailabilityStatus status) {
  final colors = context.appColors;
  return switch (status) {
    ActorAvailabilityStatus.available => colors.success,
    ActorAvailabilityStatus.tentative => colors.goldMid,
    ActorAvailabilityStatus.booked => colors.infoBlue,
    ActorAvailabilityStatus.unavailable => colors.danger,
  };
}
