import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dp_payment.dart';
import 'dp_glass_card.dart';
import 'dp_holographic_button.dart';
import 'dp_status_chip.dart';

class DPMilestoneBoard extends StatelessWidget {
  final List<DpPayment> payments;

  const DPMilestoneBoard({
    super.key,
    required this.payments,
  });

  static const columns = ['Due', 'Proof Uploaded', 'Verified', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth >= AppBreakpoints.tablet
            ? (constraints.maxWidth - 36) / 4
            : 260.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < columns.length; index++) ...[
                SizedBox(
                  width: columnWidth,
                  child: _MilestoneColumn(
                    title: columns[index],
                    items: payments
                        .where((payment) => payment.status == columns[index])
                        .toList(),
                  ),
                ),
                if (index != columns.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MilestoneColumn extends StatelessWidget {
  final String title;
  final List<DpPayment> items;

  const _MilestoneColumn({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.sectionHeaderStyle.copyWith(
              color: colors.textPrimary,
              fontSize: 13,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      colors.card.withValues(alpha: colors.isLight ? 0.5 : 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.booking,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardLabel.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.stakeholder} - PKR ${item.amount}',
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      children: [
                        DPStatusChip(label: item.stage, tone: DpTone.info),
                        DPStatusChip(label: item.dueDate, tone: DpTone.warning),
                      ],
                    ),
                    if (title == 'Due') ...[
                      const SizedBox(height: 10),
                      DPHolographicButton(
                        label: 'Upload Proof',
                        icon: Icons.upload_file_rounded,
                        onTap: () => Navigator.pushNamed(
                          context,
                          CoreRoutes.paymentProof,
                          arguments: item.id,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (items.isEmpty)
            Text(
              'No milestones',
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
