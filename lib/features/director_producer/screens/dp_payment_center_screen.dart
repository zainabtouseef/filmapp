import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/sections/admin_quick_actions_section.dart';
import '../data/director_producer_demo_data.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_milestone_board.dart';

class DPPaymentCenterScreen extends StatelessWidget {
  const DPPaymentCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final payments = DirectorProducerDemoData.payments;
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
        AdminQuickActionsSection(
          items: [
            MetricActionItem(
              icon: Icons.pending_actions_rounded,
              value: "${payments.where((p) => p.status == 'Due').length}",
              title: 'Due',
              subtitle: 'PKR $dueTotal',
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
