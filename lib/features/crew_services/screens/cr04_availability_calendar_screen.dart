import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
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
  BookingsController? _bookings;
  Future<List<AvailabilityEntry>>? _future;
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null || identical(bookings, _bookings)) return;
    _bookings = bookings;
    _future = bookings.availability();
  }

  void _reload() {
    if (_bookings == null) return;
    setState(() => _future = _bookings!.availability());
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CrewSectionCard(
          title: 'Live availability',
          icon: Icons.calendar_month_outlined,
          selected: true,
          actionText: 'Add dates',
          onActionTap: _addDates,
          child: Text(
            'Publish available days, tentative holds and unavailable periods. Confirmed bookings appear separately and cannot be overwritten here.',
            style: AppTextStyles.smallMeta.copyWith(
              color: context.appColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (future == null)
          const CoreEmptyState(
            icon: Icons.cloud_sync_outlined,
            title: 'Sign in to manage availability',
            message: 'Your crew schedule is stored in the backend.',
          )
        else
          FutureBuilder<List<AvailabilityEntry>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return CoreEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Calendar unavailable',
                  message: 'Could not load the live availability calendar.',
                  actionLabel: 'Try again',
                  onAction: _reload,
                );
              }
              final rows =
                  List<AvailabilityEntry>.from(snapshot.data ?? const [])
                    ..sort((a, b) => a.startAt.compareTo(b.startAt));
              final active = rows
                  .where((entry) => entry.endAt.isAfter(DateTime.now()))
                  .toList();
              return Column(
                children: [
                  CrewKpiRail(
                    metrics: [
                      CrewMetric(
                        label: 'Available',
                        value:
                            '${active.where((e) => e.status == 'available').length}',
                        delta: 'Published blocks',
                        icon: Icons.event_available_outlined,
                        tone: CrewTone.green,
                        route: CrewServicesRoutes.availability,
                      ),
                      CrewMetric(
                        label: 'Tentative',
                        value:
                            '${active.where((e) => e.status == 'tentative').length}',
                        delta: 'Soft holds',
                        icon: Icons.hourglass_top_rounded,
                        tone: CrewTone.gold,
                        route: CrewServicesRoutes.availability,
                      ),
                      CrewMetric(
                        label: 'Booked',
                        value:
                            '${active.where((e) => e.status == 'booked').length}',
                        delta: 'Project locked',
                        icon: Icons.movie_filter_outlined,
                        tone: CrewTone.blue,
                        route: CrewServicesRoutes.requests,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (rows.isEmpty)
                    CoreEmptyState(
                      icon: Icons.edit_calendar_outlined,
                      title: 'No schedule blocks yet',
                      message:
                          'Add your available dates so directors can book your crew with confidence.',
                      actionLabel: 'Add availability',
                      onAction: _addDates,
                    )
                  else
                    CrewResponsiveGrid(
                      minWidth: 300,
                      children: [
                        for (final entry in rows)
                          _AvailabilityCard(
                            entry: entry,
                            busy: _busyId == entry.publicId,
                            onStatus: (status) => _setStatus(entry, status),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Future<void> _addDates() async {
    final bookings = _bookings;
    if (bookings == null) return;
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: DateTimeRange(
        start: now.add(const Duration(days: 1)),
        end: now.add(const Duration(days: 3)),
      ),
    );
    if (range == null || !mounted) return;
    try {
      await bookings.createAvailability(
        startAt: DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        ).toUtc().toIso8601String(),
        endAt: DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
          23,
          59,
        ).toUtc().toIso8601String(),
        status: 'available',
        note: 'Published from Crew Workspace',
      );
      if (!mounted) return;
      crewSnack(context, 'Availability published');
      _reload();
    } catch (error) {
      if (mounted) crewSnack(context, 'Could not add dates: $error');
    }
  }

  Future<void> _setStatus(
    AvailabilityEntry entry,
    String status,
  ) async {
    final bookings = _bookings;
    if (bookings == null || entry.sourceBookingId != null) return;
    setState(() => _busyId = entry.publicId);
    try {
      await bookings.updateAvailability(
        entryId: entry.publicId,
        status: status,
        note: entry.note,
      );
      if (!mounted) return;
      crewSnack(context, 'Calendar status updated');
      _reload();
    } catch (error) {
      if (mounted) crewSnack(context, 'Could not update calendar: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}

class _AvailabilityCard extends StatelessWidget {
  final AvailabilityEntry entry;
  final bool busy;
  final ValueChanged<String> onStatus;

  const _AvailabilityCard({
    required this.entry,
    required this.busy,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = switch (entry.status) {
      'available' => colors.success,
      'booked' => colors.infoBlue,
      'tentative' => colors.goldMid,
      _ => colors.textSecondary,
    };
    final locked = entry.sourceBookingId != null;
    return GlassSectionCard(
      radius: 16,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: statusColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_shortDate(entry.startAt)} – ${_shortDate(entry.endAt)}',
                            style: AppTextStyles.cardLabel.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        StatusChip(
                          label: entry.status,
                          color: statusColor,
                          icon: locked ? Icons.lock_outline_rounded : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      entry.note?.trim().isNotEmpty == true
                          ? entry.note!
                          : locked
                              ? 'Created by a confirmed booking'
                              : 'Crew schedule block',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (busy)
                      const LinearProgressIndicator(minHeight: 2)
                    else if (!locked)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final status in const [
                            'available',
                            'tentative',
                            'unavailable',
                          ])
                            ChoiceChip(
                              label: Text(status),
                              selected: entry.status == status,
                              onSelected: (_) => onStatus(status),
                            ),
                        ],
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

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
