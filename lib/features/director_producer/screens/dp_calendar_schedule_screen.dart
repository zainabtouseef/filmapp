import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.sync_rounded,
          label: 'Sync',
          onTap: () => dpSnack(context, 'Calendar sync simulated'),
        ),
        const SizedBox(height: 10),
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
          onTap: () => dpSnack(context, 'Call sheet draft created.'),
          secondary: true,
        ),
      ],
    );
  }
}
