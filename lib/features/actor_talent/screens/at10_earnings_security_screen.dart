import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
import '../models/actor_talent_models.dart';
import '../widgets/actor_talent_components.dart';

/// AT-10 Earnings & Payment Security
class AT10EarningsSecurityScreen extends StatelessWidget {
  const AT10EarningsSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActorTalentDemoStore.instance,
      builder: (context, _) {
        final store = ActorTalentDemoStore.instance;
        return Column(
          children: [
            ActorSectionCard(
              title: 'Money Safe Summary',
              icon: Icons.account_balance_wallet_outlined,
              selected: !store.receiptConfirmed,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PKR 1,240,000',
                    style: AppTextStyles.metricNumber.copyWith(
                      color: context.appColors.textPrimary,
                      fontSize: 34,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Total protected talent earnings in demo state.',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                        label: store.receiptConfirmed
                            ? 'Receipt confirmed'
                            : 'Confirm deposit',
                        color: store.receiptConfirmed
                            ? context.appColors.success
                            : context.appColors.goldMid,
                      ),
                      StatusChip(
                        label:
                            store.paymentIssueOpen ? 'Issue open' : 'No issue',
                        color: store.paymentIssueOpen
                            ? context.appColors.danger
                            : context.appColors.infoBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ActorTwoColumn(
              left: ActorSectionCard(
                title: 'Payment Timeline',
                icon: Icons.timeline_outlined,
                child: Column(
                  children: [
                    for (final (i, item)
                        in ActorTalentDemoData.payments.indexed)
                      _PaymentRow(
                        item: item,
                        showDivider:
                            i != ActorTalentDemoData.payments.length - 1,
                      ),
                  ],
                ),
              ),
              right: ActorSectionCard(
                title: 'Security Actions',
                icon: Icons.verified_user_outlined,
                child: Column(
                  children: [
                    CorePrimaryButton(
                      icon: Icons.check_circle_outline,
                      label: 'I received payment',
                      compact: true,
                      onTap: store.receiptConfirmed
                          ? null
                          : () {
                              store.confirmReceipt();
                              actorSnack(context, 'Receipt confirmation saved');
                            },
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.receipt_long_outlined,
                      label: 'Open receipts',
                      compact: true,
                      onTap: () =>
                          Navigator.pushNamed(context, CoreRoutes.ledger),
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.report_gmailerrorred_outlined,
                      label: 'Raise issue',
                      compact: true,
                      onTap: () => _issueSheet(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _issueSheet(BuildContext context) {
    showActorSheet(
      context,
      title: 'Raise payment issue',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This opens a demo dispute and notifies admin payment verification.',
            style: AppTextStyles.body.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.report_outlined,
            label: 'Open dispute',
            compact: true,
            onTap: () {
              ActorTalentDemoStore.instance.raisePaymentIssue();
              Navigator.pop(context);
              Navigator.pushNamed(context, CoreRoutes.report);
            },
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final ActorPaymentMilestone item;
  final bool showDivider;

  const _PaymentRow({required this.item, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                item.amount,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Due ${item.dueDate}',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: StatusChip(
                    label: ActorTalentDemoData.statusLabel(item.status),
                    color: actorStatusColor(context, item.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
