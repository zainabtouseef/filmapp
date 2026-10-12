import 'package:flutter/material.dart';

import '../../../core/core_payment/screens/payment_proof_screen.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_target.dart';
import '../models/dp_payment.dart';
import 'dp_glass_card.dart';
import 'dp_holographic_button.dart';
import 'dp_status_chip.dart';

/// Opens the real payment-proof form as a tall bottom sheet instead of
/// navigating to a separate page — submitting (or closing) returns to
/// the board it was opened from.
void openPaymentProofSheet(BuildContext context, String milestoneId) {
  final colors = context.appColors;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: colors.border,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: PaymentProofUploadScreen(
                  milestoneId: milestoneId,
                  embedded: true,
                  onClose: () => Navigator.pop(sheetContext),
                  onDone: () => Navigator.pop(sheetContext),
                  doneLabel: 'Back to board',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DPMilestoneBoard extends StatelessWidget {
  final List<DpPayment> payments;

  /// When true, wraps the first "Due" milestone's proof action with a
  /// `TourTarget` so the guided tour can spotlight a real, single proof
  /// button instead of one per (repeated) milestone card.
  final bool highlightFirstDue;

  const DPMilestoneBoard({
    super.key,
    required this.payments,
    this.highlightFirstDue = false,
  });

  static const columns = ['Due', 'Proof Uploaded', 'Verified', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return DPGlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: context.appColors.goldDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No payment milestones have been created yet.',
                  style: AppTextStyles.body.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final timeline = DPGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PAYMENT TIMELINE',
                style: AppTextStyles.panelLabel.copyWith(
                  color: context.appColors.goldDark,
                  letterSpacing: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Milestones and proof actions',
                style: AppTextStyles.heroSerifHeadline.copyWith(
                  color: context.appColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              for (final (columnIndex, title) in columns.indexed) ...[
                _MilestoneSection(
                  title: title,
                  items: payments
                      .where((payment) => payment.status == title)
                      .toList(),
                  highlightFirstItem: highlightFirstDue && title == 'Due',
                ),
                if (columnIndex != columns.length - 1)
                  const SizedBox(height: 12),
              ],
            ],
          ),
        );

        final workflow = _PaymentWorkflowRail(payments: payments);
        if (constraints.maxWidth < 820) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              workflow,
              const SizedBox(height: 12),
              timeline,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: timeline),
            const SizedBox(width: 12),
            SizedBox(width: 280, child: workflow),
          ],
        );
      },
    );
  }
}

Color _columnColor(BuildContext context, String title) {
  final colors = context.appColors;
  return switch (title) {
    'Due' => colors.goldDark,
    'Proof Uploaded' => colors.infoBlue,
    'Verified' => colors.success,
    _ => colors.danger,
  };
}

class _MilestoneSection extends StatelessWidget {
  final String title;
  final List<DpPayment> items;
  final bool highlightFirstItem;

  const _MilestoneSection({
    required this.title,
    required this.items,
    this.highlightFirstItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = _columnColor(context, title);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(
          colors.elevatedSurface,
          color,
          colors.isLight ? .025 : .07,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color.lerp(colors.border, color, .25)!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: .3), blurRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: AppTextStyles.panelLabel.copyWith(
                      color: color,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${items.length}',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'No milestones in this stage',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              )
            else
              for (final (index, item) in items.indexed) ...[
                _MilestoneCard(
                  item: item,
                  title: title,
                  color: color,
                  wrapProofButton: highlightFirstItem && index == 0,
                ),
                if (index != items.length - 1) const SizedBox(height: 7),
              ],
          ],
        ),
      ),
    );
  }
}

class _PaymentWorkflowRail extends StatelessWidget {
  final List<DpPayment> payments;

  const _PaymentWorkflowRail({required this.payments});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WORKFLOW',
            style: AppTextStyles.panelLabel.copyWith(
              color: colors.goldDark,
              letterSpacing: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Proof to settlement',
            style: AppTextStyles.heroSerifHeadline.copyWith(
              color: colors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          for (final (index, title) in DPMilestoneBoard.columns.indexed) ...[
            _WorkflowStep(
              index: index + 1,
              title: title,
              count: payments.where((item) => item.status == title).length,
              color: _columnColor(context, title),
            ),
            if (index != DPMilestoneBoard.columns.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Container(
                  width: 1,
                  height: 13,
                  color: colors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  final int index;
  final String title;
  final int count;
  final Color color;

  const _WorkflowStep({
    required this.index,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 31,
          height: 31,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: .45)),
          ),
          child: Text(
            '$index',
            style: AppTextStyles.smallMeta.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.label.copyWith(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '$count',
          style: AppTextStyles.cardTitle.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final DpPayment item;
  final String title;
  final Color color;
  final bool wrapProofButton;

  const _MilestoneCard({
    required this.item,
    required this.title,
    required this.color,
    this.wrapProofButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canUpload = title == 'Due' || title == 'Rejected';
    final action = canUpload
        ? _wrapIfNeeded(
            DPHolographicButton(
              label: title == 'Rejected' ? 'Resubmit' : 'Upload proof',
              icon: title == 'Rejected'
                  ? Icons.refresh_rounded
                  : Icons.upload_file_rounded,
              secondary: title == 'Rejected',
              onTap: () => openPaymentProofSheet(context, item.id),
            ),
          )
        : DPStatusChip(
            label: title == 'Proof Uploaded' ? 'Awaiting review' : 'Verified',
            tone: title == 'Verified' ? DpTone.success : DpTone.info,
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: colors.elevatedSurface.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.borderMuted),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
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
                const SizedBox(height: 3),
                Text(
                  '${item.stakeholder} · PKR ${item.amount}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.stage} · ${item.dueDate}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          action,
        ],
      ),
    );
  }

  Widget _wrapIfNeeded(Widget child) {
    return wrapProofButton
        ? TourTarget(id: 'dp.payments.proofButton', child: child)
        : child;
  }
}
