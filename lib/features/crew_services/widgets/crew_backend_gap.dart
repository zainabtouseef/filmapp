import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../routes/crew_services_routes.dart';
import 'crew_services_components.dart';

class CrewBackendGap extends StatelessWidget {
  final String title;
  final IconData icon;
  final String needed;
  final String detail;
  final String? actionRoute;
  final String? actionLabel;

  const CrewBackendGap({
    super.key,
    required this.title,
    required this.icon,
    required this.needed,
    required this.detail,
    this.actionRoute,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return CrewTwoColumn(
      left: CrewSectionCard(
        title: title,
        icon: icon,
        selected: true,
        child: CoreEmptyState(
          icon: icon,
          title: 'Live crew backend not exposed yet',
          message: detail,
          actionLabel:
              actionRoute == null ? null : actionLabel ?? 'Open dashboard',
          onAction: actionRoute == null
              ? null
              : () => Navigator.pushNamed(context, actionRoute!),
        ),
      ),
      right: CrewSectionCard(
        title: 'Backend cleanup note',
        icon: Icons.api_outlined,
        child: Column(
          children: [
            const CrewInfoRow(
              icon: Icons.check_circle_outline,
              label: 'Removed',
              value: 'Static crew data',
            ),
            CrewInfoRow(
              icon: Icons.storage_outlined,
              label: 'Needed',
              value: needed,
            ),
            const CrewInfoRow(
              icon: Icons.warning_amber_outlined,
              label: 'Rule',
              value: 'No fake rows',
            ),
          ],
        ),
      ),
    );
  }
}

const crewDashboardRoute = CrewServicesRoutes.home;
