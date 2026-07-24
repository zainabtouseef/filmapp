import 'package:flutter/material.dart';

import '../routes/crew_services_routes.dart';
import '../widgets/crew_backend_gap.dart';

class CR05RequestsNegotiationScreen extends StatelessWidget {
  final String? initialRequestId;

  const CR05RequestsNegotiationScreen({super.key, this.initialRequestId});

  @override
  Widget build(BuildContext context) {
    return CrewBackendGap(
      title: 'Requests & negotiation',
      icon: Icons.handshake_outlined,
      needed: 'Crew request/offer negotiation API',
      detail: initialRequestId == null
          ? 'Crew requests and negotiation rows cannot be faked. Add crew marketplace/request endpoints and connect them to booking offers.'
          : 'Requested crew row $initialRequestId was passed by route, but no live crew request detail endpoint exists yet.',
      actionRoute: CrewServicesRoutes.contracts,
      actionLabel: 'Open contracts gap',
    );
  }
}
