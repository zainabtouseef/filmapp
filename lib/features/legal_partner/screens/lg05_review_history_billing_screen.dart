import 'package:flutter/material.dart';

import '../../../core/contracts/contract_models.dart';
import '../../../core/contracts/contracts_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
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
      contracts.contracts(force: true),
    ]).then(
      (values) => _LegalHistoryBundle(
        reviews: values[0] as List<LegalReviewDto>,
        contracts: values[1] as List<CineContract>,
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
              message:
                  'Review history and contracts are loaded from the server.',
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
                final signed = data.contracts
                    .where((contract) => contract.status == 'signed')
                    .length;
                final totalValue = data.contracts.fold<int>(
                  0,
                  (total, contract) => total + contract.valueMinor,
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
                          icon: Icons.draw_outlined,
                          value: '$signed',
                          title: 'Signed',
                          subtitle: 'Live contracts',
                          accentColor: context.appColors.success,
                        ),
                        MetricActionItem(
                          icon: Icons.payments_outlined,
                          value: compactMoney(totalValue, 'PKR'),
                          title: 'Contract value',
                          subtitle: 'Live total',
                          accentColor: context.appColors.infoBlue,
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
                                title: 'No live review history',
                                message:
                                    'Legal review history will appear after review rows exist in MySQL.',
                              )
                            : Column(
                                children: [
                                  for (final review in data.reviews.take(6))
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: LegalReviewCard(review: review),
                                    ),
                                ],
                              ),
                      ),
                      right: LegalSectionCard(
                        title: 'Billing rollup gap',
                        icon: Icons.receipt_long_outlined,
                        child: Column(
                          children: [
                            const InlineNotice(
                              message:
                                  'Dedicated legal billing invoices are not exposed yet, so this screen does not show fake invoices.',
                              icon: Icons.info_outline_rounded,
                            ),
                            const SizedBox(height: 10),
                            LegalInfoRow(
                              icon: Icons.storage_outlined,
                              label: 'Needed',
                              value: 'Legal billing endpoint',
                            ),
                            LegalInfoRow(
                              icon: Icons.payments_outlined,
                              label: 'Current live value',
                              value: compactMoney(totalValue, 'PKR'),
                            ),
                            LegalInfoRow(
                              icon: Icons.description_outlined,
                              label: 'Contracts',
                              value: '${data.contracts.length}',
                            ),
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
}

class _LegalHistoryBundle {
  final List<LegalReviewDto> reviews;
  final List<CineContract> contracts;

  const _LegalHistoryBundle({
    required this.reviews,
    required this.contracts,
  });
}
