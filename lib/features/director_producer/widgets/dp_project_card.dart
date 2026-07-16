import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dp_project.dart';
import 'dp_budget_health_bar.dart';
import 'dp_glass_card.dart';
import 'dp_holographic_button.dart';
import 'dp_status_chip.dart';

class DPProjectCard extends StatelessWidget {
  final DpProject project;
  final VoidCallback? onOpen;

  const DPProjectCard({
    super.key,
    required this.project,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      selected: project.pendingActions > 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardLabel.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${project.city} - ${project.dateRange}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              DPStatusChip(label: project.type, tone: DpTone.warning),
            ],
          ),
          const SizedBox(height: 9),
          DPBudgetHealthBar(
            value: project.budgetHealth,
            label: 'Budget health',
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DPStatusChip(label: project.status, tone: DpTone.info),
              DPStatusChip(
                label: '${project.pendingActions} actions',
                tone:
                    project.pendingActions > 7 ? DpTone.danger : DpTone.success,
              ),
              DPStatusChip(
                  label: 'Shoot ${project.shootDate}', tone: DpTone.neutral),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${project.bookingsCount} bookings - ${project.contractsCount} contracts - ${project.paymentsStatus}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DPHolographicButton(
                label: 'Open Hub',
                icon: Icons.open_in_new_rounded,
                onTap: onOpen,
                secondary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
