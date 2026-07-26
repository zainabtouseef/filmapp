import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/payments/payment_models.dart';
import '../../../core/payments/payments_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/payments/payment_trust_timeline.dart';
import '../models/dp_payment.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_milestone_board.dart';
import '../widgets/dp_status_chip.dart';

class DPPaymentCenterScreen extends StatefulWidget {
  const DPPaymentCenterScreen({super.key});

  @override
  State<DPPaymentCenterScreen> createState() => _DPPaymentCenterScreenState();
}

class _DPPaymentCenterScreenState extends State<DPPaymentCenterScreen> {
  Future<PaymentDashboardDto>? _future;
  String _tab = 'Ledger';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final payments = PaymentsScope.maybeOf(context);
    if (payments != null) _future ??= payments.dashboard(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return const CoreEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in required',
        message: 'Connect a live Director account to view payment schedules.',
      );
    }
    return FutureBuilder<PaymentDashboardDto>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CoreEmptyState(
            icon: Icons.hourglass_top_rounded,
            title: 'Loading payment center',
            message: 'Fetching schedules and ledger totals.',
          );
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Payment center unavailable',
            message:
                'Could not load live payment schedules from the database. Check the API connection and try again.',
            actionLabel: 'Retry',
            onAction: _reload,
          );
        }
        final payments = _toDpPayments(snapshot.data?.schedules ?? const []);
        return _PaymentCenterContent(
          payments: payments,
          schedules: snapshot.data?.schedules ?? const [],
          tab: _tab,
          onTab: (value) => setState(() => _tab = value),
        );
      },
    );
  }

  void _reload() {
    final payments = PaymentsScope.maybeOf(context);
    if (payments == null) return;
    setState(() => _future = payments.dashboard(force: true));
  }

  List<DpPayment> _toDpPayments(List<PaymentScheduleDto> schedules) {
    return [
      for (final schedule in schedules)
        for (final milestone in schedule.milestones)
          DpPayment(
            id: milestone.publicId,
            booking: schedule.bookingId,
            stakeholder: schedule.contractId ?? 'Contract pending',
            amount: milestone.amountMinor ~/ 100,
            dueDate: milestone.dueAt == null
                ? 'Due'
                : '${milestone.dueAt!.year}-${milestone.dueAt!.month.toString().padLeft(2, '0')}-${milestone.dueAt!.day.toString().padLeft(2, '0')}',
            stage: milestone.name,
            status: _statusFor(milestone.status),
          ),
    ];
  }

  String _statusFor(String status) {
    return switch (status) {
      'proof_submitted' => 'Proof Uploaded',
      'verified' => 'Verified',
      'rejected' => 'Rejected',
      _ => 'Due',
    };
  }
}

class _PaymentCenterContent extends StatelessWidget {
  final List<DpPayment> payments;
  final List<PaymentScheduleDto> schedules;
  final String tab;
  final ValueChanged<String> onTab;

  const _PaymentCenterContent({
    required this.payments,
    required this.schedules,
    required this.tab,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    final due = payments.where((p) => p.status == 'Due').toList();
    final proof = payments.where((p) => p.status == 'Proof Uploaded').toList();
    final verified = payments.where((p) => p.status == 'Verified').toList();
    final rejected = payments.where((p) => p.status == 'Rejected').toList();
    final dueTotal = due.fold<int>(0, (sum, payment) => sum + payment.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPPageHeader(
          eyebrow: '${payments.length} milestones · ${due.length} due',
          title: 'Payments',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            DpDotChip(
              label: 'Ledger',
              active: tab == 'Ledger',
              onTap: () => onTab('Ledger'),
            ),
            const SizedBox(width: 8),
            DpDotChip(
              label: 'Timeline',
              active: tab == 'Timeline',
              onTap: () => onTab('Timeline'),
            ),
            const SizedBox(width: 8),
            DpDotChip(
              label: 'History',
              active: tab == 'History',
              onTap: () => onTab('History'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatGrid(
          dueCount: due.length,
          dueTotal: dueTotal,
          proofCount: proof.length,
          verifiedCount: verified.length,
          rejectedCount: rejected.length,
        ),
        const SizedBox(height: 14),
        if (tab == 'Ledger')
          DPMilestoneBoard(payments: payments)
        else if (tab == 'Timeline')
          PaymentTrustTimeline(
            schedules: schedules,
            audience: PaymentTimelineAudience.producer,
          )
        else
          _HistoryList(items: [...verified, ...rejected]),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  final int dueCount;
  final int dueTotal;
  final int proofCount;
  final int verifiedCount;
  final int rejectedCount;

  const _StatGrid({
    required this.dueCount,
    required this.dueTotal,
    required this.proofCount,
    required this.verifiedCount,
    required this.rejectedCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      accentColor: colors.goldDark,
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 14,
        childAspectRatio: 2.6,
        children: [
          _StatCell(
            label: 'Due',
            value: '$dueCount',
            subtitle: 'PKR $dueTotal',
            color: colors.goldDark,
          ),
          _StatCell(
            label: 'Proof uploaded',
            value: '$proofCount',
            subtitle: 'Awaiting verification',
            color: colors.infoBlue,
          ),
          _StatCell(
            label: 'Verified',
            value: '$verifiedCount',
            subtitle: 'Milestones clear',
            color: colors.success,
          ),
          _StatCell(
            label: 'Rejected',
            value: '$rejectedCount',
            subtitle: 'Needs fresh proof',
            color: colors.danger,
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCell({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style:
                  AppTextStyles.caption.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.cardTitle
              .copyWith(color: colors.textPrimary, fontSize: 21),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
        ),
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<DpPayment> items;

  const _HistoryList({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (items.isEmpty) {
      return Text(
        'No verified or rejected payments yet.',
        style: AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
      );
    }
    return Column(
      children: [
        for (final item in items) ...[
          DPGlassCard(
            accentColor:
                item.status == 'Verified' ? colors.success : colors.danger,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
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
                        '${item.stakeholder} · PKR ${item.amount} · ${item.dueDate}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.smallMeta
                            .copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                DPStatusChip(
                  label: item.status,
                  tone: item.status == 'Verified'
                      ? DpTone.success
                      : DpTone.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
