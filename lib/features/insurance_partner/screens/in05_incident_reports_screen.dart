import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../routes/insurance_partner_routes.dart';
import '../widgets/insurance_partner_components.dart';

class IN05IncidentReportsScreen extends StatelessWidget {
  const IN05IncidentReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InsuranceTwoColumn(
      left: InsuranceSectionCard(
        title: 'Incident reports',
        icon: Icons.warning_amber_outlined,
        selected: true,
        child: CoreEmptyState(
          icon: Icons.warning_amber_outlined,
          title: 'Live incident feed is not exposed yet',
          message:
              'The backend currently exposes an operations incident create endpoint, but this portal needs list/detail/update APIs before it can show database-backed incident rows.',
          actionLabel: 'Open claims',
          onAction: () => Navigator.pushNamed(
            context,
            InsurancePartnerRoutes.claims,
          ),
        ),
      ),
      right: const InsuranceSectionCard(
        title: 'Backend cleanup note',
        icon: Icons.api_outlined,
        child: Column(
          children: [
            InsuranceInfoRow(
              icon: Icons.check_circle_outline,
              label: 'Removed',
              value: 'Static incidents',
            ),
            InsuranceInfoRow(
              icon: Icons.storage_outlined,
              label: 'Needed',
              value: 'GET incidents',
            ),
            InsuranceInfoRow(
              icon: Icons.edit_note_outlined,
              label: 'Needed',
              value: 'PATCH incident',
            ),
          ],
        ),
      ),
    );
  }
}
