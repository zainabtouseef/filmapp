import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
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
  int selectedDay = 3;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActorTalentDemoStore.instance,
      builder: (context, _) {
        final store = ActorTalentDemoStore.instance;
        return Column(
          children: [
            ActorSectionCard(
              title: 'Calendar Controls',
              icon: Icons.calendar_month_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DateStrip(
                    selectedDay: selectedDay,
                    onSelected: (day) => setState(() => selectedDay = day),
                  ),
                  const SizedBox(height: 12),
                  _Legend(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ActorTwoColumn(
              left: ActorSectionCard(
                title: 'Selected Day Agenda',
                icon: Icons.event_note_outlined,
                actionText: 'Edit',
                onActionTap: () => _openStatusSheet(context, selectedDay),
                child: _Agenda(day: selectedDay),
              ),
              right: ActorSectionCard(
                title: 'Travel Limits',
                icon: Icons.flight_takeoff_outlined,
                actionText: 'Edit',
                onActionTap: () => _openTravelLimitsSheet(context, store),
                child: Column(
                  children: [
                    ActorInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Preferred cities',
                      value: store.preferredCities,
                    ),
                    ActorInfoRow(
                      icon: Icons.public_outlined,
                      label: 'Travel radius',
                      value: store.travelRadius,
                    ),
                    ActorInfoRow(
                      icon: Icons.lock_clock_outlined,
                      label: 'Secured bookings',
                      value: store.availability.values
                          .where((s) => s == ActorAvailabilityStatus.booked)
                          .length
                          .toString(),
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

  void _openTravelLimitsSheet(
      BuildContext context, ActorTalentDemoStore store) {
    final cities = TextEditingController(text: store.preferredCities);
    final radius = TextEditingController(text: store.travelRadius);
    showActorSheet(
      context,
      title: 'Edit Travel Limits',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: cities,
            label: 'Preferred cities',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 10),
          CoreTextField(
            controller: radius,
            label: 'Travel radius',
            icon: Icons.public_outlined,
          ),
          const SizedBox(height: 14),
          CorePrimaryButton(
            icon: Icons.check_rounded,
            label: 'Save',
            onTap: () {
              store.updateTravelLimits(
                cities: cities.text.trim(),
                radius: radius.text.trim(),
              );
              Navigator.pop(context);
              actorSnack(context, 'Travel limits updated');
            },
          ),
        ],
      ),
    );
  }

  void _openStatusSheet(BuildContext context, int day) {
    showActorSheet(
      context,
      title: 'Set Jul $day status',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final status in ActorAvailabilityStatus.values)
            ElevatedButton.icon(
              onPressed: () {
                ActorTalentDemoStore.instance.setAvailability(day, status);
                Navigator.pop(context);
                actorSnack(context, 'Jul $day marked ${_statusLabel(status)}');
              },
              icon: Icon(_statusIcon(status), size: 18),
              label: Text(_statusLabel(status)),
            ),
        ],
      ),
    );
  }
}

class _DateStrip extends StatelessWidget {
  final int selectedDay;
  final ValueChanged<int> onSelected;

  const _DateStrip({
    required this.selectedDay,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final store = ActorTalentDemoStore.instance;
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = index + 1;
          final status =
              store.availability[day] ?? ActorAvailabilityStatus.available;
          final active = day == selectedDay;
          return GestureDetector(
            onTap: () => onSelected(day),
            child: Container(
              width: 54,
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
                    '$day',
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
  final int day;

  const _Agenda({required this.day});

  @override
  Widget build(BuildContext context) {
    final status = ActorTalentDemoStore.instance.availability[day] ??
        ActorAvailabilityStatus.available;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActorInfoRow(
          icon: _statusIcon(status),
          label: 'Jul $day',
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
