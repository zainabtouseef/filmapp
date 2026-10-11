import 'package:flutter/material.dart';

import '../../../core/contracts/contract_models.dart';
import '../../../core/contracts/contracts_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../widgets/legal_live_widgets.dart';
import '../widgets/legal_partner_components.dart';

class LG05ReviewHistoryBillingScreen extends StatefulWidget {
  const LG05ReviewHistoryBillingScreen({super.key});

  @override
  State<LG05ReviewHistoryBillingScreen> createState() =>
      _LG05ReviewHistoryBillingScreenState();
}

class _LG05ReviewHistoryBillingScreenState
    extends State<LG05ReviewHistoryBillingScreen> {
  Future<_LegalHistoryBundle>? _future;
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_LegalHistoryBundle>? _load() {
    final contracts = ContractsScope.maybeOf(context);
    if (contracts == null) return null;
    return Future.wait([
      contracts.legalReviews(force: true),
      contracts.legalBillingRecords(force: true),
    ]).then(
      (values) => _LegalHistoryBundle(
        reviews: values[0] as List<LegalReviewDto>,
        billing: values[1] as List<LegalBillingRecordDto>,
      ),
    );
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return LegalSectionCard(
      title: 'Review history & billing',
      icon: Icons.history_outlined,
      selected: true,
      actionText: _future == null ? null : 'Refresh',
      onActionTap: _refresh,
      child: _future == null
          ? const CoreEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to view legal history',
              message: 'Review and billing records are loaded from the server.',
            )
          : FutureBuilder<_LegalHistoryBundle>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonCard(height: 520);
                }
                if (snapshot.hasError) {
                  return LegalLoadError(
                    message: 'Could not load legal history',
                    onRetry: _refresh,
                  );
                }
                final data = snapshot.data!;
                final billed = data.billing.fold<int>(
                  0,
                  (total, item) => total + item.amountMinor,
                );
                final outstanding = data.billing
                    .where((item) =>
                        item.status == 'draft' || item.status == 'issued')
                    .fold<int>(
                      0,
                      (total, item) => total + item.amountMinor,
                    );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MetricActionRail(
                      items: [
                        MetricActionItem(
                          icon: Icons.history_outlined,
                          value: '${data.reviews.length}',
                          title: 'Review records',
                          subtitle: 'Live history',
                          accentColor: context.appColors.goldDark,
                        ),
                        MetricActionItem(
                          icon: Icons.receipt_long_outlined,
                          value: '${data.billing.length}',
                          title: 'Billing records',
                          subtitle: 'Tracked matters',
                          accentColor: context.appColors.infoPurple,
                        ),
                        MetricActionItem(
                          icon: Icons.payments_outlined,
                          value: compactMoney(billed, 'PKR'),
                          title: 'Reviewed value',
                          subtitle: 'Live legal total',
                          accentColor: context.appColors.infoBlue,
                        ),
                        MetricActionItem(
                          icon: Icons.pending_actions_outlined,
                          value: compactMoney(outstanding, 'PKR'),
                          title: 'Outstanding',
                          subtitle: 'Draft and issued',
                          accentColor: context.appColors.goldMid,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LegalTwoColumn(
                      left: LegalSectionCard(
                        title: 'Recent reviews',
                        icon: Icons.rate_review_outlined,
                        child: data.reviews.isEmpty
                            ? const CoreEmptyState(
                                icon: Icons.rate_review_outlined,
                                title: 'No review history',
                                message:
                                    'Completed contract and template reviews appear here.',
                              )
                            : Column(
                                children: [
                                  for (final review in data.reviews.take(8))
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: LegalReviewCard(review: review),
                                    ),
                                ],
                              ),
                      ),
                      right: LegalSectionCard(
                        title: 'Billing records',
                        icon: Icons.receipt_long_outlined,
                        child: data.billing.isEmpty
                            ? const CoreEmptyState(
                                icon: Icons.receipt_long_outlined,
                                title: 'No billing records',
                                message:
                                    'A draft billing row is created with every legal decision.',
                              )
                            : Column(
                                children: [
                                  for (final item in data.billing.take(10)) ...[
                                    _BillingCard(
                                      item: item,
                                      busy: _busyId == item.publicId,
                                      onIssue: item.status == 'draft'
                                          ? () => _updateBilling(item, 'issued')
                                          : null,
                                      onPaid: item.status == 'issued'
                                          ? () => _updateBilling(item, 'paid')
                                          : null,
                                    ),
                                    if (item != data.billing.take(10).last)
                                      const SizedBox(height: 9),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _updateBilling(
    LegalBillingRecordDto item,
    String status,
  ) async {
    final contracts = ContractsScope.maybeOf(context);
    if (contracts == null) return;
    setState(() => _busyId = item.publicId);
    try {
      await contracts.updateLegalBillingRecord(
        publicId: item.publicId,
        status: status,
        invoiceNumber: status == 'issued'
            ? 'CC-${item.publicId.split('-').last}'
            : item.invoiceNumber,
      );
      if (!mounted) return;
      legalSnack(context, 'Billing record marked $status');
      _refresh();
    } catch (error) {
      if (mounted) legalSnack(context, 'Could not update billing: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}

class _BillingCard extends StatelessWidget {
  final LegalBillingRecordDto item;
  final bool busy;
  final VoidCallback? onIssue;
  final VoidCallback? onPaid;

  const _BillingCard({
    required this.item,
    required this.busy,
    required this.onIssue,
    required this.onPaid,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Opacity(
      opacity: busy ? 0.62 : 1,
      child: GlassSectionCard(
        radius: 16,
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.matterId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                LegalStatusChip(
                  status: legalStatusFromString(item.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LegalInfoRow(
              icon: Icons.work_outline_rounded,
              label: 'Matter',
              value: item.matterType,
            ),
            LegalInfoRow(
              icon: Icons.schedule_outlined,
              label: 'Time',
              value: '${item.minutes} minutes',
            ),
            LegalInfoRow(
              icon: Icons.payments_outlined,
              label: 'Amount',
              value: item.displayAmount,
            ),
            LegalInfoRow(
              icon: Icons.confirmation_number_outlined,
              label: 'Invoice',
              value: item.invoiceNumber ?? 'Not issued',
            ),
            LegalInfoRow(
              icon: Icons.event_outlined,
              label: 'Created',
              value: _date(item.createdAt),
            ),
            if (onIssue != null || onPaid != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: onIssue != null
                    ? CorePrimaryButton(
                        icon: Icons.send_outlined,
                        label: 'Issue invoice',
                        compact: true,
                        onTap: busy ? null : onIssue,
                      )
                    : CorePrimaryButton(
                        icon: Icons.price_check_outlined,
                        label: 'Mark paid',
                        compact: true,
                        onTap: busy ? null : onPaid,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegalHistoryBundle {
  final List<LegalReviewDto> reviews;
  final List<LegalBillingRecordDto> billing;

  const _LegalHistoryBundle({
    required this.reviews,
    required this.billing,
  });
}

String _date(DateTime? value) {
  if (value == null) return 'Date unavailable';
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
