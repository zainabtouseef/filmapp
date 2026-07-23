import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/media_equipment_models.dart';
import '../routes/media_equipment_routes.dart';
import '../widgets/media_equipment_components.dart';

class ME05AvailabilityCalendarScreen extends StatefulWidget {
  const ME05AvailabilityCalendarScreen({super.key});

  @override
  State<ME05AvailabilityCalendarScreen> createState() =>
      _ME05AvailabilityCalendarScreenState();
}

class _ME05AvailabilityCalendarScreenState
    extends State<ME05AvailabilityCalendarScreen> {
  Future<_ScheduleData>? _dataFuture;
  late DateTime _selectedDay;
  String? _selectedItemId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dataFuture != null) return;
    _reload();
  }

  void _reload() {
    final bookings = BookingsScope.maybeOf(context);
    final operations = OperationsScope.maybeOf(context);
    if (bookings == null || operations == null) return;
    _dataFuture = _load(bookings, operations);
  }

  Future<_ScheduleData> _load(
    BookingsController bookings,
    OperationsController operations,
  ) async {
    final values = await Future.wait([
      bookings.availability(),
      operations.equipmentItems(force: true),
    ]);
    final data = _ScheduleData(
      entries: values[0] as List<AvailabilityEntry>,
      items: values[1] as List<EquipmentItemDto>,
    );
    if (_selectedItemId == null && data.items.isNotEmpty) {
      _selectedItemId = data.items.first.publicId;
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    if (_dataFuture == null) {
      return const InlineNotice(
        message: 'Preview mode. Sign in to manage equipment availability.',
        icon: Icons.visibility_outlined,
      );
    }
    return FutureBuilder<_ScheduleData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InlineNotice(
            message: 'Loading fleet schedule...',
            icon: Icons.hourglass_top_rounded,
          );
        }
        if (snapshot.hasError) {
          return InlineNotice(
            message: 'Could not load fleet schedule: ${snapshot.error}',
            icon: Icons.cloud_off_outlined,
          );
        }
        final data = snapshot.data!;
        if (data.items.isEmpty) {
          return CoreEmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'Inventory required',
            message:
                'Add equipment inventory before managing item availability.',
            actionLabel: 'Open inventory',
            onAction: () => Navigator.pushNamed(
              context,
              MediaEquipmentRoutes.inventory,
            ),
          );
        }
        final selectedItem = data.items.firstWhere(
          (item) => item.publicId == _selectedItemId,
          orElse: () => data.items.first,
        );
        final entry =
            _entryFor(data.entries, selectedItem.publicId, _selectedDay);
        final status = _statusFor(entry);
        final days = List.generate(
          14,
          (index) => DateTime.now()
              .add(Duration(days: index))
              .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaSectionCard(
              title: 'Fleet Availability',
              icon: Icons.calendar_month_outlined,
              selected: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory context',
                    style: AppTextStyles.cardLabel.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final item in data.items)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: item.modelName,
                              icon: Icons.videocam_outlined,
                              selected: item.publicId == selectedItem.publicId,
                              onTap: () => setState(
                                () => _selectedItemId = item.publicId,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _AvailabilityLegend(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: days.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 9),
                      itemBuilder: (context, index) {
                        final day = days[index];
                        final dayEntry =
                            _entryFor(data.entries, selectedItem.publicId, day);
                        return _DayTile(
                          day: day,
                          status: _statusFor(dayEntry),
                          selected: _sameDay(_selectedDay, day),
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
                      for (final value in const [
                        MediaAvailabilityStatus.available,
                        MediaAvailabilityStatus.hold,
                        MediaAvailabilityStatus.maintenance,
                        MediaAvailabilityStatus.transit,
                      ])
                        CoreChip(
                          label: mediaAvailabilityLabel(value),
                          icon: mediaAvailabilityIcon(value),
                          selected: status == value,
                          onTap: _saving || entry?.sourceBookingId != null
                              ? null
                              : () => _setStatus(
                                    item: selectedItem,
                                    entry: entry,
                                    status: value,
                                  ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            MediaTwoColumn(
              left: MediaSectionCard(
                title: 'Selected Day',
                icon: Icons.event_note_outlined,
                child: Column(
                  children: [
                    MediaInfoRow(
                      icon: mediaAvailabilityIcon(status),
                      label: _dateLabel(_selectedDay),
                      value: mediaAvailabilityLabel(status),
                    ),
                    MediaInfoRow(
                      icon: Icons.videocam_outlined,
                      label: 'Asset',
                      value: selectedItem.modelName,
                    ),
                    MediaInfoRow(
                      icon: Icons.notes_outlined,
                      label: 'Schedule note',
                      value: entry?.note?.trim().isNotEmpty == true
                          ? entry!.note!
                          : _agendaText(status),
                    ),
                    if (entry?.sourceBookingId != null)
                      MediaInfoRow(
                        icon: Icons.lock_clock_outlined,
                        label: 'Booking lock',
                        value: entry!.sourceBookingId!,
                      ),
                  ],
                ),
              ),
              right: MediaSectionCard(
                title: 'Conflict Monitor',
                icon: Icons.warning_amber_outlined,
                child: Column(
                  children: [
                    MediaInfoRow(
                      icon: Icons.event_available_outlined,
                      label: 'Booked',
                      value:
                          '${_count(data.entries, selectedItem.publicId, MediaAvailabilityStatus.booked)} blocks',
                    ),
                    MediaInfoRow(
                      icon: Icons.hourglass_top_outlined,
                      label: 'Holds',
                      value:
                          '${_count(data.entries, selectedItem.publicId, MediaAvailabilityStatus.hold)} blocks',
                    ),
                    MediaInfoRow(
                      icon: Icons.handyman_outlined,
                      label: 'Service / transit',
                      value:
                          '${_countBlocked(data.entries, selectedItem.publicId)} blocks',
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.move_to_inbox_outlined,
                      label: 'Inspect booking requests',
                      compact: true,
                      onTap: () => Navigator.pushNamed(
                        context,
                        MediaEquipmentRoutes.requests,
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

  Future<void> _setStatus({
    required EquipmentItemDto item,
    required AvailabilityEntry? entry,
    required MediaAvailabilityStatus status,
  }) async {
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null) return;
    final apiStatus = switch (status) {
      MediaAvailabilityStatus.available => 'available',
      MediaAvailabilityStatus.hold => 'hold',
      _ => 'blocked',
    };
    final note = switch (status) {
      MediaAvailabilityStatus.maintenance => 'Equipment maintenance',
      MediaAvailabilityStatus.transit => 'Pickup and return transit buffer',
      MediaAvailabilityStatus.hold => 'Provider hold',
      _ => 'Open for equipment booking',
    };
    setState(() => _saving = true);
    try {
      if (entry == null) {
        await bookings.createAvailability(
          startAt: _selectedDay.toUtc().toIso8601String(),
          endAt: _selectedDay
              .add(const Duration(days: 1))
              .toUtc()
              .toIso8601String(),
          status: apiStatus,
          note: note,
          resourceType: 'equipment',
          resourceId: item.publicId,
        );
      } else {
        await bookings.updateAvailability(
          entryId: entry.publicId,
          status: apiStatus,
          note: note,
        );
      }
      if (!mounted) return;
      setState(_reload);
      mediaSnack(
        context,
        '${item.modelName} set to ${mediaAvailabilityLabel(status)}',
      );
    } catch (error) {
      if (mounted) mediaSnack(context, 'Could not update schedule: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  AvailabilityEntry? _entryFor(
    List<AvailabilityEntry> entries,
    String itemId,
    DateTime day,
  ) {
    for (final entry in entries) {
      if (entry.resourceType == 'equipment' &&
          entry.resourceId == itemId &&
          !day.isBefore(_day(entry.startAt)) &&
          day.isBefore(_day(entry.endAt))) {
        return entry;
      }
    }
    return null;
  }

  int _count(
    List<AvailabilityEntry> entries,
    String itemId,
    MediaAvailabilityStatus status,
  ) {
    return entries
        .where(
          (entry) => entry.resourceId == itemId && _statusFor(entry) == status,
        )
        .length;
  }

  int _countBlocked(List<AvailabilityEntry> entries, String itemId) {
    return entries
        .where(
          (entry) => entry.resourceId == itemId && entry.status == 'blocked',
        )
        .length;
  }
}

class _AvailabilityLegend extends StatelessWidget {
  const _AvailabilityLegend();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final status in MediaAvailabilityStatus.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: StatusChip(
                label: mediaAvailabilityLabel(status).toUpperCase(),
                icon: mediaAvailabilityIcon(status),
                color: mediaAvailabilityColor(context, status),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final DateTime day;
  final MediaAvailabilityStatus status;
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
    final color = mediaAvailabilityColor(context, status);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 76,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : colors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _month(day.month),
              style: AppTextStyles.micro.copyWith(
                color: colors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${day.day}',
              style: AppTextStyles.metricNumberCompact.copyWith(
                color: colors.textPrimary,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Icon(mediaAvailabilityIcon(status), color: color, size: 17),
          ],
        ),
      ),
    );
  }
}

class _ScheduleData {
  final List<AvailabilityEntry> entries;
  final List<EquipmentItemDto> items;

  const _ScheduleData({
    required this.entries,
    required this.items,
  });
}

MediaAvailabilityStatus _statusFor(AvailabilityEntry? entry) {
  if (entry == null || entry.status == 'available') {
    return MediaAvailabilityStatus.available;
  }
  if (entry.sourceBookingId != null || entry.status == 'booked') {
    return MediaAvailabilityStatus.booked;
  }
  if (entry.status == 'hold') return MediaAvailabilityStatus.hold;
  if (entry.note?.toLowerCase().contains('transit') == true) {
    return MediaAvailabilityStatus.transit;
  }
  return MediaAvailabilityStatus.maintenance;
}

DateTime _day(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _dateLabel(DateTime value) {
  return '${_month(value.month)} ${value.day}, ${value.year}';
}

String _month(int month) {
  return const [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ][month - 1];
}

String _agendaText(MediaAvailabilityStatus status) {
  return switch (status) {
    MediaAvailabilityStatus.available =>
      'Open for equipment booking in Director discovery.',
    MediaAvailabilityStatus.hold => 'Soft hold pending producer confirmation.',
    MediaAvailabilityStatus.booked =>
      'Secured booking locks this asset automatically.',
    MediaAvailabilityStatus.maintenance =>
      'Asset is hidden while inspection or service is underway.',
    MediaAvailabilityStatus.transit =>
      'Logistics buffer for pickup, travel, or return.',
  };
}
