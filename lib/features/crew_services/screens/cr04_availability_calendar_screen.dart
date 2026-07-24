import 'package:flutter/material.dart';

import '../routes/crew_services_routes.dart';
import '../widgets/crew_backend_gap.dart';

class CR04AvailabilityCalendarScreen extends StatelessWidget {
  const CR04AvailabilityCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CrewBackendGap(
      title: 'Availability calendar',
      icon: Icons.calendar_month_outlined,
      needed: 'Crew availability blocks API',
      detail:
          'Crew availability no longer uses local colored calendar blocks. Add crew availability read/write endpoints, or link crew providers to the existing booking availability model.',
      actionRoute: CrewServicesRoutes.requests,
      actionLabel: 'Open requests gap',
    );
  }
}
