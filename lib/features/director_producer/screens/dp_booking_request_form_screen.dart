import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../data/director_producer_demo_data.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_booking_status_spine.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPBookingRequestFormScreen extends StatelessWidget {
  const DPBookingRequestFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requirement = DirectorProducerDemoData.requirements.first;
    final candidate = DirectorProducerDemoData.candidates.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.send_rounded,
          label: 'Send',
          onTap: () =>
              Navigator.pushNamed(context, DirectorProducerRoutes.bargaining),
        ),
        const SizedBox(height: 8),
        const DPBookingStatusSpine(activeIndex: 0),
        const SizedBox(height: 14),
        DPTwoColumn(
          left: DPSectionCard(
            title: 'Request Details',
            icon: Icons.assignment_outlined,
            child: Column(
              children: [
                _RequestRow(label: 'Project', value: 'Hunza Winter Film'),
                _RequestRow(label: 'Requirement', value: requirement.title),
                _RequestRow(label: 'Stakeholder', value: candidate.name),
                _RequestRow(label: 'Dates', value: requirement.dates),
                _RequestRow(
                  label: 'Fee offer',
                  value: requirement.budgetRange,
                  showDivider: false,
                ),
              ],
            ),
          ),
          right: DPSectionCard(
            title: 'Terms Preview',
            icon: Icons.fact_check_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dpBullet(context, '30% deposit after signed contract.'),
                dpBullet(
                    context, 'Weather buffer applied to mountain exterior.'),
                dpBullet(
                    context, 'Travel, lodging, and usage rights included.'),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DPStatusChip(label: 'Expires 24h', tone: DpTone.warning),
                    DPStatusChip(label: 'Counter allowed', tone: DpTone.info),
                    DPStatusChip(
                        label: 'Contract auto-generate', tone: DpTone.success),
                  ],
                ),
                const SizedBox(height: 14),
                DPHolographicButton(
                  label: 'Send Booking Request',
                  icon: Icons.send_rounded,
                  onTap: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.bargaining,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _RequestRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Row(
        children: [
          Expanded(child: dpText(context, label)),
          const SizedBox(width: 10),
          Flexible(child: dpText(context, value, strong: true)),
        ],
      ),
    );
  }
}
