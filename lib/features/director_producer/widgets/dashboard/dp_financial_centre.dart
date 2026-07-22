import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/cards/cine_card_system.dart';
import '../../../../shared/formatters/cine_format.dart';
import '../../data/director_producer_demo_data.dart';
import '../../models/dp_payment.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_glass_card.dart';
import '../dp_holographic_button.dart';

/// The Financial Command Centre — ledger health plus three payment previews,
/// with the complete ledger available from the parent section action.
class DPFinancialCentre extends StatelessWidget {
  const DPFinancialCentre({super.key});

  @override
  Widget build(BuildContext context) {
    final payments = DirectorProducerDemoData.payments;
    final total = payments.fold<int>(0, (sum, p) => sum + p.amount);
    final verified = payments.where((p) => p.status == 'Verified');
    final underReview = payments.where((p) => p.status == 'Proof Uploaded');
    final due = payments.where((p) => p.status == 'Due');
    final rejected = payments.where((p) => p.status == 'Rejected');
    final paid = verified.fold<int>(0, (sum, p) => sum + p.amount);
    final progress = total == 0 ? 0.0 : paid / total;
    final attention = [...rejected, ...due].take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LedgerCard(
          label: 'Verified ledger',
          amount: CineFormat.currency(paid, compact: true),
          period:
              '${(progress * 100).round()}% paid · ${CineFormat.currency(total, compact: true)} total',
          status:
              rejected.isNotEmpty ? '${rejected.length} rejected' : 'On track',
          tone: rejected.isNotEmpty
              ? CineTone.critical
              : progress >= 0.5
                  ? CineTone.positive
                  : CineTone.warning,
          progress: progress,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _LegendDot(
                label: '${verified.length} verified', tone: CineTone.positive),
            _LegendDot(
                label: '${underReview.length} review',
                tone: CineTone.information),
            _LegendDot(label: '${due.length} due', tone: CineTone.warning),
            if (rejected.isNotEmpty)
              _LegendDot(
                  label: '${rejected.length} rejected',
                  tone: CineTone.critical),
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

class _LegendDot extends StatelessWidget {
  final String label;
  final CineTone tone;

  const _LegendDot({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final color = cineToneColor(context, tone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final DpPayment payment;

  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rejected = payment.status == 'Rejected';
    final tone = rejected ? CineTone.critical : CineTone.warning;
    final accent = cineToneColor(context, tone);
    void openPayments() {
      Navigator.pushNamed(context, DirectorProducerRoutes.payments);
    }

    return DPGlassCard(
      accentColor: accent,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      onTap: openPayments,
      child: Row(
        children: [
          Icon(
            rejected ? Icons.error_outline_rounded : Icons.upload_file_outlined,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        payment.stakeholder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: colors.textPrimary,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    _LegendDot(label: payment.status, tone: tone),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${payment.booking} · ${CineFormat.currency(payment.amount)} · ${payment.dueDate}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DPHolographicButton(
            label: rejected ? 'Review' : 'Upload Proof',
            icon: rejected ? Icons.rate_review_outlined : Icons.upload_rounded,
            onTap: openPayments,
            secondary: true,
          ),
        ],
      ),
    );
  }
}

class _LedgerCard extends StatelessWidget {
  final String label;
  final String amount;
  final String period;
  final String status;
  final CineTone tone;
  final double progress;

  const _LedgerCard({
    required this.label,
    required this.amount,
    required this.period,
    required this.status,
    required this.tone,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = cineToneColor(context, tone);
    return DPGlassCard(
      accentColor: accent,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _LegendDot(label: status, tone: tone),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: AppTextStyles.heroSerifNumber.copyWith(
              color: colors.textPrimary,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            period,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedProgress(
            values: [progress.clamp(0, 1), 1 - progress.clamp(0, 1)],
            tones: [tone, CineTone.neutral],
          ),
        ],
      ),
    );
  }
}
