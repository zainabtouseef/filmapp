part of '../super_admin_screens.dart';

class PaymentsHubScreen extends StatefulWidget {
  const PaymentsHubScreen({super.key});

  @override
  State<PaymentsHubScreen> createState() => _PaymentsHubScreenState();
}

class _PaymentsHubScreenState extends State<PaymentsHubScreen> {
  Future<_FinanceHubData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_FinanceHubData> _load() async {
    final payments = PaymentsScope.of(context);
    final results = await Future.wait<Object>([
      payments.adminProofs(force: true),
      payments.ledger(force: true),
      AdminScope.of(context).feeRules(force: true),
    ]);
    return _FinanceHubData(
      proofs: results[0] as List<PaymentProofDto>,
      ledger: results[1] as List<LedgerEntryDto>,
      feeRules: results[2] as List<AdminFeeRuleDto>,
    );
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  AdminPaymentProof _toAdminProof(PaymentProofDto proof) {
    return AdminPaymentProof(
      proofId: proof.publicId,
      bookingId: proof.bookingId,
      contractId: proof.transactionId,
      payer: 'Submitted by ${proof.submittedBy.displayName}',
      payee: 'Milestone ${proof.milestoneId}',
      milestone: proof.status.replaceAll('_', ' '),
      expectedAmount: proof.claimedAmountMinor ~/ 100,
      claimedAmount: proof.claimedAmountMinor ~/ 100,
      method: _methodLabel(proof.method),
      risk: proof.riskScore >= 70
          ? 'Duplicate Proof'
          : proof.riskScore >= 40
              ? 'Amount Mismatch'
              : 'No Risk',
      age: '0h',
      status: proof.status,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FinanceHubData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AdminSurface(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          final error = snapshot.error;
          return AdminSurface(
            child: Column(
              children: [
                AdminEmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Could not load finance operations',
                  message: error is ApiException
                      ? error.message
                      : 'Check the backend connection and try again.',
                ),
                const SizedBox(height: 12),
                AdminActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Retry',
                  secondary: true,
                  onTap: _refresh,
                ),
              ],
            ),
          );
        }
        final data = snapshot.data!;
        final proofs = data.proofs.map(_toAdminProof).take(3).toList();
        final ledger =
            data.ledger.map((entry) => entry.toLedgerRow()).take(3).toList();
        final fees =
            data.feeRules.where((item) => item.active).take(3).toList();
        final pendingValue = proofs.fold<int>(
          0,
          (sum, item) => sum + item.claimedAmount,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MetricActionRail(
              items: [
                AdminMetricTile(
                  label: 'Pending value',
                  value: 'PKR ${_adminMoney(pendingValue)}',
                  icon: Icons.account_balance_wallet_outlined,
                  tone: AdminDecisionTone.warning,
                ).toActionItem(context),
                AdminMetricTile(
                  label: 'High-value proofs',
                  value:
                      '${proofs.where((item) => item.claimedAmount >= 100000).length}',
                  icon: Icons.priority_high_rounded,
                  tone: AdminDecisionTone.danger,
                ).toActionItem(context),
                AdminMetricTile(
                  label: 'Risk alerts',
                  value:
                      '${proofs.where((item) => item.risk != 'No Risk').length}',
                  icon: Icons.warning_amber_rounded,
                  tone: AdminDecisionTone.danger,
                ).toActionItem(context),
                AdminMetricTile(
                  label: 'Active fee rules',
                  value: '${fees.length}',
                  icon: Icons.percent_rounded,
                  tone: AdminDecisionTone.info,
                ).toActionItem(context),
              ],
            ),
            const SizedBox(height: 12),
            AdminSurface(
              padding: const EdgeInsets.fromLTRB(13, 13, 13, 10),
              child: Column(
                children: [
                  AdminSectionHeader(
                    title: 'Payment verification queue',
                    icon: Icons.receipt_long_outlined,
                    action: 'View all',
                    onAction: () => Navigator.pushNamed(
                      context,
                      SuperAdminRoutes.paymentQueue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (proofs.isEmpty)
                    const AdminEmptyState(
                      icon: Icons.verified_outlined,
                      title: 'Payment queue clear',
                      message: 'No uploaded proof needs a decision.',
                    )
                  else
                    for (final proof in proofs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PaymentProofRow(
                          proof: proof,
                          onReview: () => Navigator.pushNamed(
                            context,
                            SuperAdminRoutes.paymentReviewPath(
                              proof.proofId!,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AdminSurface(
              padding: const EdgeInsets.fromLTRB(13, 13, 13, 10),
              child: Column(
                children: [
                  AdminSectionHeader(
                    title: 'Receipts & ledger',
                    icon: Icons.receipt_outlined,
                    action: 'Open ledger',
                    onAction: () => Navigator.pushNamed(
                      context,
                      SuperAdminRoutes.paymentLedger,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (ledger.isEmpty)
                    const AdminEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No ledger entries',
                      message: 'Verified transactions will appear here.',
                    )
                  else
                    for (var index = 0; index < ledger.length; index++)
                      _LedgerRow(
                        entry: ledger[index],
                        showDivider: index != ledger.length - 1,
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AdminSurface(
              padding: const EdgeInsets.fromLTRB(13, 13, 13, 10),
              child: Column(
                children: [
                  AdminSectionHeader(
                    title: 'Commission & fees',
                    icon: Icons.percent_rounded,
                    action: 'Manage',
                    onAction: () =>
                        Navigator.pushNamed(context, SuperAdminRoutes.fees),
                  ),
                  const SizedBox(height: 12),
                  if (fees.isEmpty)
                    const AdminEmptyState(
                      icon: Icons.percent_rounded,
                      title: 'No active fee rules',
                      message: 'Create and activate a commission rule.',
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final rule in fees) _FeeRuleChip(rule: rule),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FinanceHubData {
  final List<PaymentProofDto> proofs;
  final List<LedgerEntryDto> ledger;
  final List<AdminFeeRuleDto> feeRules;

  const _FinanceHubData({
    required this.proofs,
    required this.ledger,
    required this.feeRules,
  });
}

class _LedgerRow extends StatelessWidget {
  final LedgerRowData entry;
  final bool showDivider;

  const _LedgerRow({required this.entry, required this.showDivider});

  static const _toneByStatus = {
    LedgerStatus.verified: AdminDecisionTone.success,
    LedgerStatus.released: AdminDecisionTone.success,
    LedgerStatus.pendingVerification: AdminDecisionTone.warning,
    LedgerStatus.partiallyPaid: AdminDecisionTone.warning,
    LedgerStatus.refunded: AdminDecisionTone.info,
    LedgerStatus.disputed: AdminDecisionTone.danger,
    LedgerStatus.notPaid: AdminDecisionTone.neutral,
    LedgerStatus.closed: AdminDecisionTone.neutral,
  };

  static const _statusLabel = {
    LedgerStatus.verified: 'Verified',
    LedgerStatus.released: 'Released',
    LedgerStatus.pendingVerification: 'Pending',
    LedgerStatus.partiallyPaid: 'Partial',
    LedgerStatus.refunded: 'Refunded',
    LedgerStatus.disputed: 'Disputed',
    LedgerStatus.notPaid: 'Not Paid',
    LedgerStatus.closed: 'Closed',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = _toneByStatus[entry.status] ?? AdminDecisionTone.neutral;
    return Container(
      padding: EdgeInsets.only(bottom: showDivider ? 10 : 2),
      margin: EdgeInsets.only(bottom: showDivider ? 10 : 0),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            entry.direction == LedgerDirection.incoming
                ? Icons.south_west_rounded
                : Icons.north_east_rounded,
            color: entry.direction == LedgerDirection.incoming
                ? colors.success
                : colors.goldDark,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.bookingId} · ${entry.milestone}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.date,
                  style: AppTextStyles.micro.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PKR ${entry.amount}',
                style: AppTextStyles.caption.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              AdminStatusBadge(
                label: _statusLabel[entry.status] ?? '',
                tone: tone,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeeRuleChip extends StatelessWidget {
  final AdminFeeRuleDto rule;

  const _FeeRuleChip({required this.rule});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colors.softSurface.withValues(alpha: colors.isLight ? 1 : 0.6),
        border: Border(
          left: BorderSide(color: colors.goldMid, width: 4),
          top: BorderSide(color: colors.borderMuted),
          right: BorderSide(color: colors.borderMuted),
          bottom: BorderSide(color: colors.borderMuted),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rule.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(rule.basisPoints / 100).toStringAsFixed(2)}% · '
            '${rule.category}',
            style: AppTextStyles.label.copyWith(
              color: colors.goldDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
