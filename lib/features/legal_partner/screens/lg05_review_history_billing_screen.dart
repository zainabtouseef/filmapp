import 'package:flutter/material.dart';

import '../../../core/contracts/contract_models.dart' as contract_models;
import '../../../core/contracts/contracts_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../data/legal_partner_demo_data.dart';
import '../models/legal_partner_models.dart';
import '../widgets/legal_partner_components.dart';

class LG05ReviewHistoryBillingScreen extends StatefulWidget {
  const LG05ReviewHistoryBillingScreen({super.key});

  @override
  State<LG05ReviewHistoryBillingScreen> createState() =>
      _LG05ReviewHistoryBillingScreenState();
}

class _LG05ReviewHistoryBillingScreenState
    extends State<LG05ReviewHistoryBillingScreen> {
  String _query = '';
  String _sort = 'Recent';
  Future<List<contract_models.LegalReviewDto>>? _reviewsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final contracts = ContractsScope.maybeOf(context);
    if (contracts != null) {
      _reviewsFuture ??= contracts.legalReviews(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = LegalPartnerDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final rows = _rows(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LegalSectionCard(
              title: 'History command',
              icon: Icons.receipt_long_outlined,
              selected: true,
              child: Column(
                children: [
                  LegalSearchField(
                    hintText: 'Search matters, clients, invoices...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in [
                          'All',
                          'Completed',
                          'Billed',
                          'Pending',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: filter,
                              selected: store.billingFilter == filter,
                              onTap: () => store.setBillingFilter(filter),
                            ),
                          ),
                        const SizedBox(width: 8),
                        for (final sort in ['Recent', 'Invoice'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: sort,
                              selected: _sort == sort,
                              icon: Icons.sort_rounded,
                              onTap: () {
                                setState(() => _sort = sort);
                                legalSnack(context, '$sort sorting applied');
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_reviewsFuture != null)
              FutureBuilder<List<contract_models.LegalReviewDto>>(
                future: _reviewsFuture,
                builder: (context, snapshot) {
                  final liveRows = snapshot.data ?? const [];
                  if (!snapshot.hasError && liveRows.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LegalSectionCard(
                        title: 'Live review history',
                        icon: Icons.history_outlined,
                        child: Column(
                          children: [
                            for (final row in liveRows.take(8))
                              LegalInfoRow(
                                icon: Icons.gavel_outlined,
                                label: row.status,
                                value:
                                    '${row.title} • ${row.requestedBy.displayName}',
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            LegalTwoColumn(
              left: LegalSectionCard(
                title: 'Review history',
                icon: Icons.table_rows_outlined,
                child: rows.isEmpty
                    ? CoreEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No legal records',
                        message: 'Clear filters or search another matter.',
                        actionLabel: 'Clear',
                        onAction: () {
                          setState(() => _query = '');
                          store.setBillingFilter('All');
                        },
                      )
                    : Column(
                        children: [
                          for (final row in rows)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _BillingRow(
                                row: row,
                                status: store.billingStatus(row),
                                onDetail: () => _showBilling(context, row),
                                onBill: () {
                                  store.markBilled(row.id);
                                  legalSnack(context, 'Invoice marked billed');
                                },
                              ),
                            ),
                        ],
                      ),
              ),
              right: LegalSectionCard(
                title: 'Billing summary',
                icon: Icons.analytics_outlined,
                child: Column(
                  children: [
                    LegalInfoRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Premium invoices',
                      value: 'PKR 1.8M',
                    ),
                    LegalInfoRow(
                      icon: Icons.timer_outlined,
                      label: 'Avg turnaround',
                      value: '5h 12m',
                    ),
                    LegalInfoRow(
                      icon: Icons.verified_outlined,
                      label: 'Completed',
                      value: '28 matters',
                    ),
                    LegalInfoRow(
                      icon: Icons.history_outlined,
                      label: 'Audit events',
                      value: '${store.auditEvents}',
                    ),
                    const SizedBox(height: 10),
                    CoreSecondaryButton(
                      icon: Icons.download_outlined,
                      label: 'Export billing',
                      compact: true,
                      onTap: () => legalSnack(
                        context,
                        'Legal billing export prepared',
                      ),
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

  Iterable<LegalBillingRecord> _rows(LegalPartnerDemoStore store) {
    final lower = _query.trim().toLowerCase();
    var result = LegalPartnerDemoData.billing.where((row) {
      final status = store.billingStatus(row);
      final matchesFilter = switch (store.billingFilter) {
        'Completed' => status == LegalStatus.completed,
        'Billed' => status == LegalStatus.billed,
        'Pending' => status == LegalStatus.templatePending,
        _ => true,
      };
      final haystack = '${row.matter} ${row.client} ${row.invoice} ${row.notes}'
          .toLowerCase();
      return matchesFilter && haystack.contains(lower);
    }).toList();
    if (_sort == 'Invoice') result = result.reversed.toList();
    return result;
  }

  void _showBilling(BuildContext context, LegalBillingRecord row) {
    showLegalSheet(
      context,
      title: row.matter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LegalInfoRow(
            icon: Icons.business_outlined,
            label: 'Client',
            value: row.client,
          ),
          LegalInfoRow(
            icon: Icons.timer_outlined,
            label: 'Turnaround',
            value: row.turnaround,
          ),
          LegalInfoRow(
            icon: Icons.payments_outlined,
            label: 'Invoice',
            value: row.invoice,
          ),
          LegalInfoRow(
            icon: Icons.notes_outlined,
            label: 'Notes',
            value: row.notes,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Ledger',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, CoreRoutes.ledger);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.description_outlined,
                  label: 'Contract',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, CoreRoutes.contract);
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

class _BillingRow extends StatelessWidget {
  final LegalBillingRecord row;
  final LegalStatus status;
  final VoidCallback onDetail;
  final VoidCallback onBill;

  const _BillingRow({
    required this.row,
    required this.status,
    required this.onDetail,
    required this.onBill,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 16,
      padding: const EdgeInsets.all(11),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.matter,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              LegalStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${row.client} - ${row.turnaround} - ${row.invoice}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Detail',
                  compact: true,
                  onTap: onDetail,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Bill',
                  compact: true,
                  onTap: onBill,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
