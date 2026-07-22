import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/director_producer_demo_data.dart';
import '../../models/dp_payment.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_glass_card.dart';
import '../dp_holographic_button.dart';
import '../dp_status_chip.dart';

/// The Financial Command Centre — ledger health plus the payments that
/// most need a producer's attention (rejected first, then due).
class DPFinancialCentre extends StatelessWidget {
  const DPFinancialCentre({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final payments = DirectorProducerDemoData.payments;
    final total = payments.fold<int>(0, (sum, p) => sum + p.amount);
    final paid = payments
        .where((p) => p.status == 'Verified')
        .fold<int>(0, (sum, p) => sum + p.amount);
    final progress = total == 0 ? 0.0 : paid / total;

    final rejected = payments.where((p) => p.status == 'Rejected');
    final due = payments.where((p) => p.status == 'Due');
    final attention = [...rejected, ...due].take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Verified ledger',
                  style: AppTextStyles.cardLabel
                      .copyWith(color: colors.textPrimary)),
            ),
            Text(
              '${(progress * 100).round()}% paid • PKR ${(total / 1000000).toStringAsFixed(1)}M total',
              style:
                  AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress,
            color: colors.success,
            backgroundColor: colors.borderMuted,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            DPStatusChip(
              label:
                  '${payments.where((p) => p.status == 'Verified').length} verified',
              tone: DpTone.success,
            ),
            DPStatusChip(
              label:
                  '${payments.where((p) => p.status == 'Proof Uploaded').length} under review',
              tone: DpTone.info,
            ),
            DPStatusChip(
              label: '${due.length} due',
              tone: DpTone.warning,
            ),
            if (rejected.isNotEmpty)
              DPStatusChip(
                label: '${rejected.length} rejected',
                tone: DpTone.danger,
              ),
          ],
        ),
        if (attention.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final payment in attention) ...[
            _PaymentTile(payment: payment),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final DpPayment payment;

  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return DPGlassCard(
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.stakeholder,
                    style: AppTextStyles.cardLabel
                        .copyWith(color: context.appColors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  '${payment.booking} • PKR ${payment.amount} • ${payment.dueDate}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta
                      .copyWith(color: context.appColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DPHolographicButton(
            label: payment.status == 'Rejected' ? 'Review' : 'Upload Proof',
            icon: Icons.upload_file_outlined,
            onTap: () =>
                Navigator.pushNamed(context, DirectorProducerRoutes.payments),
            secondary: true,
          ),
        ],
      ),
    );
  }
}
