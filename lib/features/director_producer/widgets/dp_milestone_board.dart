import 'package:flutter/material.dart';

import '../../../core/core_payment/screens/payment_proof_screen.dart';
import '../../../core/theme/app_breakpoints.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth >= AppBreakpoints.tablet
            ? (constraints.maxWidth - 36) / 4
            : 250.0;
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
                    highlightFirstItem:
                        highlightFirstDue && columns[index] == 'Due',
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

Color _columnColor(BuildContext context, String title) {
  final colors = context.appColors;
  return switch (title) {
    'Due' => colors.goldDark,
    'Proof Uploaded' => colors.infoBlue,
    'Verified' => colors.success,
    _ => colors.danger,
  };
}

class _MilestoneColumn extends StatelessWidget {
  final String title;
  final List<DpPayment> items;
  final bool highlightFirstItem;

  const _MilestoneColumn({
    required this.title,
    required this.items,
    this.highlightFirstItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = _columnColor(context, title);
    return DPGlassCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.panelLabel.copyWith(
              color: color,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          for (final (index, item) in items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MilestoneCard(
                item: item,
                title: title,
                color: color,
                wrapProofButton: highlightFirstItem && index == 0,
              ),
            ),
          if (items.isEmpty)
            Text(
              'No milestones',
              style:
                  AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
            ),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 4),
          Text(
            '${item.stakeholder} · PKR ${item.amount}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              DpDotLabel(label: item.stage, tone: DpTone.info),
              DpDotLabel(label: item.dueDate, tone: DpTone.warning),
            ],
          ),
          if (title == 'Due') ...[
            const SizedBox(height: 10),
            _wrapIfNeeded(
              DPHolographicButton(
                label: 'Upload Proof',
                icon: Icons.upload_file_rounded,
                onTap: () => openPaymentProofSheet(context, item.id),
              ),
            ),
          ] else if (title == 'Rejected') ...[
            const SizedBox(height: 10),
            _wrapIfNeeded(
              DPHolographicButton(
                label: 'Resubmit Proof',
                icon: Icons.refresh_rounded,
                secondary: true,
                onTap: () => openPaymentProofSheet(context, item.id),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: colors.surface
                      .withValues(alpha: colors.isLight ? 0.7 : 0.2),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  title == 'Proof Uploaded'
                      ? 'Awaiting verification'
                      : 'Verified',
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
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
