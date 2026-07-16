import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/media_equipment_demo_data.dart';
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
  int _selectedDay = 3;

  @override
  Widget build(BuildContext context) {
    final store = MediaEquipmentDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final status =
            store.calendar[_selectedDay] ?? MediaAvailabilityStatus.available;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaSectionCard(
              title: 'Item and team schedule',
              icon: Icons.calendar_month_outlined,
              selected: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AvailabilityLegend(),
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
                            MediaAvailabilityStatus.available;
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
                      for (final itemStatus in MediaAvailabilityStatus.values)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            store.setCalendarStatus(_selectedDay, itemStatus);
                            mediaSnack(
                              context,
                              'Jul $_selectedDay set to ${mediaAvailabilityLabel(itemStatus)}',
                            );
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Center(
                              child: StatusChip(
                                label: mediaAvailabilityLabel(itemStatus)
                                    .toUpperCase(),
                                icon: mediaAvailabilityIcon(itemStatus),
                                color: status == itemStatus
                                    ? mediaAvailabilityColor(
                                        context, itemStatus)
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
            MediaTwoColumn(
              left: MediaSectionCard(
                title: 'Selected agenda',
                icon: Icons.event_note_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MediaInfoRow(
                      icon: mediaAvailabilityIcon(status),
                      label: 'Jul $_selectedDay',
                      value: mediaAvailabilityLabel(status),
                    ),
                    MediaInfoRow(
                      icon: Icons.videocam_outlined,
                      label: 'Inventory context',
                      value: store.activeItem.modelName,
                    ),
                    MediaInfoRow(
                      icon: Icons.location_city_outlined,
                      label: 'City',
                      value: store.activeItem.city,
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
                            icon: Icons.hourglass_top_rounded,
                            label: 'Hold',
                            compact: true,
                            onTap: () => store.setCalendarStatus(
                              _selectedDay,
                              MediaAvailabilityStatus.hold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CorePrimaryButton(
                            icon: Icons.check_circle_outline,
                            label: 'Open',
                            compact: true,
                            onTap: () => store.setCalendarStatus(
                              _selectedDay,
                              MediaAvailabilityStatus.available,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              right: MediaSectionCard(
                title: 'Conflict monitor',
                icon: Icons.warning_amber_outlined,
                child: Column(
                  children: [
                    MediaInfoRow(
                      icon: Icons.event_available_outlined,
                      label: 'Booked',
                      value:
                          '${_count(store, MediaAvailabilityStatus.booked)} days',
                    ),
                    MediaInfoRow(
                      icon: Icons.local_shipping_outlined,
                      label: 'Transit',
                      value:
                          '${_count(store, MediaAvailabilityStatus.transit)} days',
                    ),
                    MediaInfoRow(
                      icon: Icons.handyman_outlined,
                      label: 'Maintenance',
                      value:
                          '${_count(store, MediaAvailabilityStatus.maintenance)} days',
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.move_to_inbox_outlined,
                      label: 'Inspect requests',
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

  int _count(MediaEquipmentDemoStore store, MediaAvailabilityStatus status) {
    return store.calendar.values.where((item) => item == status).length;
  }

  String _agendaText(MediaAvailabilityStatus status) {
    return switch (status) {
      MediaAvailabilityStatus.available =>
        'Open for item and team booking in marketplace search.',
      MediaAvailabilityStatus.hold =>
        'Soft hold pending producer confirmation.',
      MediaAvailabilityStatus.booked =>
        'Secured booking blocks this item automatically.',
      MediaAvailabilityStatus.maintenance =>
        'Maintenance day hides this item from booking.',
      MediaAvailabilityStatus.transit =>
        'Logistics buffer for pickup/drop route.',
    };
  }
}

class _AvailabilityLegend extends StatelessWidget {
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
  final int day;
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
            Icon(mediaAvailabilityIcon(status), color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
