import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPContractCenterScreen extends StatelessWidget {
  const DPContractCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contracts = DirectorProducerDemoData.contracts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.article_outlined,
          label: 'Templates',
          onTap: () => dpSnack(context, 'Template browser simulated'),
        ),
        const SizedBox(height: 8),
        DPResponsiveGrid(
          minWidth: 310,
          children: contracts
              .map(
                (contract) => _ContractCard(
                  title: contract.title,
                  project: contract.project,
                  stakeholder: contract.candidate,
                  value: contract.value,
                  status: contract.status,
                  progress: contract.signatureProgress,
                  date: contract.createdDate,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ContractCard extends StatelessWidget {
  final String title;
  final String project;
  final String stakeholder;
  final String value;
  final String status;
  final double progress;
  final String date;

  const _ContractCard({
    required this.title,
    required this.project,
    required this.stakeholder,
    required this.value,
    required this.status,
    required this.progress,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = status == 'Signed'
        ? DpTone.success
        : status == 'Cancelled'
            ? DpTone.danger
            : status == 'Addendums'
                ? DpTone.info
                : DpTone.warning;
    return DPGlassCard(
      selected: status == 'Pending Signature',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: dpText(context, title, strong: true)),
              DPStatusChip(label: status, tone: tone),
            ],
          ),
          const SizedBox(height: 6),
          dpText(context, '$project - $stakeholder'),
          const SizedBox(height: 9),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: colors.surface.withValues(alpha: 0.28),
            valueColor: AlwaysStoppedAnimation<Color>(colors.goldMid),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                value,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              DPStatusChip(label: date, tone: DpTone.neutral),
            ],
          ),
          const SizedBox(height: 9),
          DPHolographicButton(
            label: 'Open Contract',
            icon: Icons.open_in_new_rounded,
            onTap: () => Navigator.pushNamed(context, CoreRoutes.contract),
            secondary: true,
          ),
        ],
      ),
    );
  }
}
