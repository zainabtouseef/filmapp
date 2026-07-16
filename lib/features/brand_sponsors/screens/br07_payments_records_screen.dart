import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/brand_sponsor_demo_data.dart';
import '../models/brand_sponsor_models.dart';
import '../widgets/brand_sponsor_components.dart';

class BR07PaymentsRecordsScreen extends StatefulWidget {
  const BR07PaymentsRecordsScreen({super.key});

  @override
  State<BR07PaymentsRecordsScreen> createState() =>
      _BR07PaymentsRecordsScreenState();
}

class _BR07PaymentsRecordsScreenState extends State<BR07PaymentsRecordsScreen> {
  @override
  Widget build(BuildContext context) {
    final store = BrandSponsorDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final rows = _rows(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MetricActionRail(
              items: [
                MetricActionItem(
                  value: 'PKR 7.8M',
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Committed',
                  subtitle: 'Current',
                  accentColor: brandToneColor(context, BrandTone.green),
                ),
                MetricActionItem(
                  value: 'PKR 1.6M',
                  icon: Icons.pending_actions_outlined,
                  title: 'Pending',
                  subtitle: 'Current',
                  accentColor: brandToneColor(context, BrandTone.gold),
                ),
                MetricActionItem(
                  value: '14',
                  icon: Icons.policy_outlined,
                  title: 'Usage records',
                  subtitle: 'Current',
                  accentColor: brandToneColor(context, BrandTone.blue),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BrandTwoColumn(
              left: BrandSectionCard(
                title: 'Campaign ledger',
                icon: Icons.table_rows_outlined,
                selected: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final filter in [
                            'All',
                            'Pending',
                            'Verified',
                            'Issue',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CoreChip(
                                label: filter,
                                selected: store.paymentsFilter == filter,
                                onTap: () {
                                  store.setPaymentsFilter(filter);
                                  brandSnack(context, '$filter payments shown');
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (rows.isEmpty)
                      CoreEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No payment records',
                        message: 'Try another payment status.',
                        actionLabel: 'Clear',
                        onAction: () => store.setPaymentsFilter('All'),
                      )
                    else
                      for (final row in rows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PaymentRow(
                            item: row,
                            status: store.paymentStatus(row),
                            onVerify: () {
                              store.verifyPayment(row.id);
                              brandSnack(context, 'Payment verified');
                            },
                            onIssue: () => _confirmIssue(context, store, row),
                            onReceipt: () => Navigator.pushNamed(
                              context,
                              CoreRoutes.ledger,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              right: Column(
                children: [
                  BrandSectionCard(
                    title: 'Usage rights record',
                    icon: Icons.policy_outlined,
                    child: Column(
                      children: [
                        BrandInfoRow(
                          icon: Icons.campaign_outlined,
                          label: 'Campaign',
                          value: 'Nova Cola Summer Launch',
                        ),
                        BrandInfoRow(
                          icon: Icons.public_outlined,
                          label: 'Territory',
                          value: 'Pakistan',
                        ),
                        BrandInfoRow(
                          icon: Icons.lock_clock_outlined,
                          label: 'Term',
                          value: '9 months',
                        ),
                        BrandInfoRow(
                          icon: Icons.verified_outlined,
                          label: 'Approvals',
                          value: 'Brand controlled',
                        ),
                        const SizedBox(height: 10),
                        CoreSecondaryButton(
                          icon: Icons.download_outlined,
                          label: 'Export files',
                          compact: true,
                          onTap: () => brandSnack(
                            context,
                            'Campaign records export prepared',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  BrandSectionCard(
                    title: 'Milestone timeline',
                    icon: Icons.account_tree_outlined,
                    child: Column(
                      children: const [
                        _TimelineRow(
                          label: 'Advance proof',
                          value: 'Pending',
                          status: BrandStatus.paymentPending,
                        ),
                        _TimelineRow(
                          label: 'Placement proof',
                          value: 'Verified',
                          status: BrandStatus.verified,
                        ),
                        _TimelineRow(
                          label: 'Completion release',
                          value: 'Due',
                          status: BrandStatus.pending,
                        ),
                        _TimelineRow(
                          label: 'Revision holdback',
                          value: 'Issue',
                          status: BrandStatus.disputed,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Iterable<BrandPaymentItem> _rows(BrandSponsorDemoStore store) {
    return BrandSponsorDemoData.payments.where((item) {
      final status = store.paymentStatus(item);
      return switch (store.paymentsFilter) {
        'Pending' =>
          status == BrandStatus.pending || status == BrandStatus.paymentPending,
        'Verified' => status == BrandStatus.verified,
        'Issue' => status == BrandStatus.disputed,
        _ => true,
      };
    });
  }

  void _confirmIssue(
    BuildContext context,
    BrandSponsorDemoStore store,
    BrandPaymentItem item,
  ) {
    showBrandSheet(
      context,
      title: 'Flag payment',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Flag ${item.label} for payment verification review?',
            style: AppTextStyles.body.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.close_rounded,
                  label: 'Cancel',
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.report_problem_outlined,
                  label: 'Flag',
                  onTap: () {
                    store.flagPayment(item.id);
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      CoreRoutes.report,
                      arguments: 'Brand payment issue',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final BrandPaymentItem item;
  final BrandStatus status;
  final VoidCallback onVerify;
  final VoidCallback onIssue;
  final VoidCallback onReceipt;

  const _PaymentRow({
    required this.item,
    required this.status,
    required this.onVerify,
    required this.onIssue,
    required this.onReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 16,
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.payer} -> ${item.payee} - ${item.amount}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          BrandStatusChip(status: status),
          IconButton(
            tooltip: 'Verify',
            visualDensity: VisualDensity.compact,
            onPressed: onVerify,
            icon: Icon(Icons.verified_outlined, color: colors.success),
          ),
          IconButton(
            tooltip: 'Receipt',
            visualDensity: VisualDensity.compact,
            onPressed: onReceipt,
            icon: Icon(Icons.receipt_long_outlined, color: colors.goldDark),
          ),
          IconButton(
            tooltip: 'Issue',
            visualDensity: VisualDensity.compact,
            onPressed: onIssue,
            icon: Icon(Icons.report_problem_outlined, color: colors.iconMuted),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final String value;
  final BrandStatus status;

  const _TimelineRow({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = brandStatusColor(context, status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.smallMeta.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
