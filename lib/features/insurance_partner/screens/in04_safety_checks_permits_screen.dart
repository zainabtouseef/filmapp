import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../routes/insurance_partner_routes.dart';
import '../widgets/insurance_partner_components.dart';

class IN04SafetyChecksPermitsScreen extends StatelessWidget {
  const IN04SafetyChecksPermitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InsuranceTwoColumn(
      left: InsuranceSectionCard(
        title: 'Safety checks & permits',
        icon: Icons.fact_check_outlined,
        selected: true,
        child: CoreEmptyState(
          icon: Icons.fact_check_outlined,
          title: 'Live safety checklist feed is not exposed yet',
          message:
              'The backend currently exposes operations safety-check create endpoints, but this portal needs list/detail/update APIs before it can show database-backed safety rows.',
          actionLabel: 'Open policies',
          onAction: () => Navigator.pushNamed(
            context,
            InsurancePartnerRoutes.records,
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
              value: 'Static checklist',
            ),
            InsuranceInfoRow(
              icon: Icons.storage_outlined,
              label: 'Needed',
              value: 'GET safety checks',
            ),
            InsuranceInfoRow(
              icon: Icons.edit_note_outlined,
              label: 'Needed',
              value: 'PATCH check item',
            ),
          ],
        ),
      ),
    );
  }
}
