import 'package:flutter/material.dart';

import '../../../core/core_contract/screens/contract_viewer_screen.dart';
import '../../../core/core_payment/screens/payment_proof_screen.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/crew_services_demo_data.dart';
import '../models/crew_services_models.dart';
import '../widgets/crew_services_components.dart';

class CR06ContractsPaymentsScreen extends StatefulWidget {
  const CR06ContractsPaymentsScreen({super.key});

  @override
  State<CR06ContractsPaymentsScreen> createState() =>
      _CR06ContractsPaymentsScreenState();
}

class _CR06ContractsPaymentsScreenState
    extends State<CR06ContractsPaymentsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final store = CrewServicesDemoStore.instance;
    final colors = context.appColors;
    final rows = _rows().toList();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MetricActionRail(
              items: [
                MetricActionItem(
                  value: store.contractSigned ? 'Signed' : 'Pending',
                  icon: Icons.draw_outlined,
                  title: 'Contract',
                  subtitle: 'Current',
                  accentColor: crewToneColor(
                    context,
                    store.contractSigned ? CrewTone.green : CrewTone.gold,
                  ),
                ),
                MetricActionItem(
                  value: crewMoney(
                    CrewServicesDemoData.ledger
                        .where(
                            (item) => item.status == CrewBookingStatus.secured)
                        .fold<int>(
                          0,
                          (sum, item) =>
                              sum +
                              int.parse(
                                item.amount.replaceAll(RegExp(r'[^0-9]'), ''),
                              ),
                        ),
                  ),
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Secured',
                  subtitle: 'Current',
                  accentColor: crewToneColor(context, CrewTone.green),
                ),
                MetricActionItem(
                  value: store.paymentProofUploaded ? 'Proof sent' : 'Pending',
                  icon: Icons.upload_file_outlined,
                  title: 'Advance',
                  subtitle: 'Current',
                  accentColor: crewToneColor(
                    context,
                    store.paymentProofUploaded ? CrewTone.blue : CrewTone.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CrewTwoColumn(
              left: CrewSectionCard(
                title: 'Payment ledger',
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
                            'Disputed',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CoreChip(
                                label: filter,
                                selected: _filter == filter,
                                onTap: () {
                                  setState(() => _filter = filter);
                                  crewSnack(
                                      context, '$filter ledger filter applied');
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final row in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LedgerRow(
                          item: row,
                          onReceipt: () =>
                              Navigator.pushNamed(context, CoreRoutes.ledger),
                          onIssue: () => Navigator.pushNamed(
                            context,
                            CoreRoutes.report,
                            arguments: 'Crew payment issue - ${row.label}',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              right: Column(
                children: [
                  CrewSectionCard(
                    title: 'Agreement actions',
                    icon: Icons.description_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crew agreement, payment milestones, proof tracking and receipts use shared contract/payment components.',
                          style: AppTextStyles.smallMeta.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CorePrimaryButton(
                          icon: Icons.draw_outlined,
                          label: store.contractSigned
                              ? 'View contract'
                              : 'Sign contract',
                          compact: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContractViewerScreen(
                                onSigned: () {
                                  store.signContract();
                                  crewSnack(context, 'Crew agreement signed');
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        CoreSecondaryButton(
                          icon: Icons.upload_file_outlined,
                          label: 'Upload proof',
                          compact: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentProofUploadScreen(
                                onSubmitted: store.uploadPaymentProof,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        CoreSecondaryButton(
                          icon: Icons.receipt_long_outlined,
                          label: 'Receipts',
                          compact: true,
                          onTap: () => Navigator.pushNamed(
                            context,
                            CoreRoutes.ledger,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CrewSectionCard(
                    title: 'Milestone timeline',
                    icon: Icons.account_tree_outlined,
                    child: Column(
                      children: const [
                        _TimelineRow(
                          label: 'Agreement generated',
                          value: 'Contract',
                          status: CrewBookingStatus.contractPending,
                        ),
                        _TimelineRow(
                          label: 'Signing advance',
                          value: 'Pending',
                          status: CrewBookingStatus.paymentPending,
                        ),
                        _TimelineRow(
                          label: 'Production day',
                          value: 'Secured',
                          status: CrewBookingStatus.secured,
                        ),
                        _TimelineRow(
                          label: 'Overtime adjustment',
                          value: 'Review',
                          status: CrewBookingStatus.disputed,
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

  Iterable<CrewLedgerItem> _rows() {
    return CrewServicesDemoData.ledger.where((item) {
      return switch (_filter) {
        'Pending' => item.status == CrewBookingStatus.paymentPending,
        'Verified' => item.status == CrewBookingStatus.secured,
        'Disputed' => item.status == CrewBookingStatus.disputed,
        _ => true,
      };
    });
  }
}

class _LedgerRow extends StatelessWidget {
  final CrewLedgerItem item;
  final VoidCallback onReceipt;
  final VoidCallback onIssue;

  const _LedgerRow({
    required this.item,
    required this.onReceipt,
    required this.onIssue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
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
                  '${item.amount} - due ${item.dueDate}',
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
          CrewStatusChip(status: item.status),
          CardMenu<String>(
            items: const [
              CardMenuItem(
                value: 'receipt',
                label: 'Receipt',
                icon: Icons.receipt_long_outlined,
              ),
              CardMenuItem(
                value: 'issue',
                label: 'Report issue',
                icon: Icons.report_problem_outlined,
              ),
            ],
            onSelected: (value) {
              if (value == 'receipt') onReceipt();
              if (value == 'issue') onIssue();
            },
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final String value;
  final CrewBookingStatus status;

  const _TimelineRow({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = crewStatusColor(context, status);
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
