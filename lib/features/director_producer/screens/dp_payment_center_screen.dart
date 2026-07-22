import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/payments/payment_models.dart';
import '../../../core/payments/payments_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/director_producer_demo_data.dart';
import '../models/dp_payment.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_milestone_board.dart';

class DPPaymentCenterScreen extends StatefulWidget {
  const DPPaymentCenterScreen({super.key});

  @override
  State<DPPaymentCenterScreen> createState() => _DPPaymentCenterScreenState();
}

class _DPPaymentCenterScreenState extends State<DPPaymentCenterScreen> {
  Future<PaymentDashboardDto>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final payments = PaymentsScope.maybeOf(context);
    if (payments != null) _future ??= payments.dashboard(force: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_future != null) {
      return FutureBuilder<PaymentDashboardDto>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CoreEmptyState(
              icon: Icons.hourglass_top_rounded,
              title: 'Loading payment center',
              message: 'Fetching schedules and ledger totals.',
            );
          }
          if (!snapshot.hasError && snapshot.data != null) {
            return _PaymentCenterContent(
              payments: _toDpPayments(snapshot.data!.schedules),
              dashboard: snapshot.data!,
            );
          }
          return _PaymentCenterContent(
            payments: DirectorProducerDemoData.payments,
          );
        },
      );
    }
    return _PaymentCenterContent(payments: DirectorProducerDemoData.payments);
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
  final PaymentDashboardDto? dashboard;

  const _PaymentCenterContent({required this.payments, this.dashboard});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dueTotal = payments
        .where((payment) => payment.status == 'Due')
        .fold<int>(0, (sum, payment) => sum + payment.amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.receipt_long_outlined,
          label: 'Ledger',
          onTap: () => Navigator.pushNamed(context, CoreRoutes.ledger),
        ),
        const SizedBox(height: 8),
        MetricActionRail(
          items: [
            MetricActionItem(
              icon: Icons.pending_actions_rounded,
              value: "${payments.where((p) => p.status == 'Due').length}",
              title: 'Due',
              subtitle: dashboard == null
                  ? 'PKR $dueTotal'
                  : 'Paid PKR ${dashboard!.debitMinor ~/ 100}',
              accentColor: colors.goldMid,
            ),
            MetricActionItem(
              icon: Icons.upload_file_rounded,
              value:
                  "${payments.where((p) => p.status == 'Proof Uploaded').length}",
              title: 'Proof Uploaded',
              subtitle: 'Awaiting verification',
              accentColor: colors.infoBlue,
            ),
            MetricActionItem(
              icon: Icons.verified_rounded,
              value: "${payments.where((p) => p.status == 'Verified').length}",
              title: 'Verified',
              subtitle: 'Milestones clear',
              accentColor: colors.success,
            ),
            MetricActionItem(
              icon: Icons.error_outline_rounded,
              value: "${payments.where((p) => p.status == 'Rejected').length}",
              title: 'Rejected',
              subtitle: 'Needs fresh proof',
              accentColor: colors.danger,
            ),
          ],
        ),
        const SizedBox(height: 14),
        DPMilestoneBoard(payments: payments),
      ],
    );
  }
}
