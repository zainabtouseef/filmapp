part of '../super_admin_screens.dart';

class PaymentsHubScreen extends StatefulWidget {
  const PaymentsHubScreen({super.key});

  @override
  State<PaymentsHubScreen> createState() => _PaymentsHubScreenState();
}

class _PaymentsHubScreenState extends State<PaymentsHubScreen> {
  Future<List<PaymentProofDto>>? _proofsFuture;
  Future<List<LedgerEntryDto>>? _ledgerFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final payments = PaymentsScope.maybeOf(context);
    _proofsFuture ??= payments?.adminProofs(force: true);
    _ledgerFuture ??= payments?.ledger(force: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_proofsFuture != null || _ledgerFuture != null) {
      return FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _proofsFuture ?? Future<List<PaymentProofDto>>.value(const []),
          _ledgerFuture ?? Future<List<LedgerEntryDto>>.value(const []),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final proofDtos = snapshot.hasError
              ? const <PaymentProofDto>[]
              : (snapshot.data?[0] as List<PaymentProofDto>? ?? const []);
          final ledgerDtos = snapshot.hasError
              ? const <LedgerEntryDto>[]
              : (snapshot.data?[1] as List<LedgerEntryDto>? ?? const []);
          final proofs = proofDtos
              .map((proof) => AdminPaymentProof(
                    proofId: proof.publicId,
                    bookingId: proof.bookingId,
                    contractId: proof.transactionId,
                    payer: 'Submitted by ${proof.submittedBy.displayName}',
                    payee: 'Milestone ${proof.milestoneId}',
                    milestone: proof.status.replaceAll('_', ' '),
                    expectedAmount: proof.claimedAmountMinor ~/ 100,
                    claimedAmount: proof.claimedAmountMinor ~/ 100,
                    method: _methodLabel(proof.method),
                    risk: proof.riskScore >= 40 ? 'Amount Mismatch' : 'No Risk',
                    age: '0h',
                    status: proof.status,
                  ))
              .take(3)
              .toList();
          final ledger =
              ledgerDtos.map((entry) => entry.toLedgerRow()).take(3).toList();
          return _hubContent(
            context,
            proofs: proofs.isEmpty
                ? AdminMockData.paymentProofs.take(3).toList()
                : proofs,
            ledger: ledger.isEmpty
                ? AdminMockData.ledgerEntries.take(3).toList()
                : ledger,
            notice: snapshot.hasError
                ? 'Live finance hub unavailable; showing demo rows.'
                : null,
          );
        },
      );
    }
    return _hubContent(
      context,
      proofs: AdminMockData.paymentProofs.take(3).toList(),
      ledger: AdminMockData.ledgerEntries.take(3).toList(),
    );
  }

  Widget _hubContent(
    BuildContext context, {
    required List<AdminPaymentProof> proofs,
    required List<LedgerRowData> ledger,
    String? notice,
  }) {
    final fees = AdminMockData.commissionRules.take(3).toList();
    final pendingValue =
        proofs.fold<int>(0, (sum, item) => sum + item.claimedAmount);
    final metricTiles = [
      AdminMetricTile(
          label: 'Pending Value',
          value: 'PKR ${_adminMoney(pendingValue)}',
          icon: Icons.account_balance_wallet_outlined,
          tone: AdminDecisionTone.warning),
      AdminMetricTile(
          label: 'High-Value Proofs',
          value:
              '${proofs.where((proof) => proof.claimedAmount >= 100000).length}',
          icon: Icons.priority_high_rounded,
          tone: AdminDecisionTone.danger),
      AdminMetricTile(
          label: 'Mismatch Alerts',
          value:
              '${proofs.where((proof) => proof.risk == 'Amount Mismatch').length}',
          icon: Icons.compare_arrows_rounded,
          tone: AdminDecisionTone.danger),
      AdminMetricTile(
          label: 'Duplicate Warnings',
          value:
              '${proofs.where((proof) => proof.risk == 'Duplicate Proof').length}',
          icon: Icons.copy_all_outlined,
          tone: AdminDecisionTone.warning),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (notice != null) ...[
          InlineNotice(message: notice, tone: CoreStatusTone.warning),
          const SizedBox(height: 12),
        ],
        MetricActionRail(
          items: [
            for (final tile in metricTiles) tile.toActionItem(context),
          ],
        ),
        const SizedBox(height: 12),
        AdminSurface(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 10),
          child: Column(
            children: [
              _ReviewSectionHeader(
                title: 'Payment Verification Queue',
                icon: Icons.receipt_long_outlined,
                action: 'View All',
                onAction: () =>
                    Navigator.pushNamed(context, SuperAdminRoutes.paymentQueue),
              ),
              const SizedBox(height: 12),
              ...proofs.map(
                (proof) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PaymentProofRow(
                    proof: proof,
                    onReview: () => Navigator.pushNamed(
                      context,
                      SuperAdminRoutes.paymentReview,
                      arguments: proof.proofId,
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
              _ReviewSectionHeader(
                title: 'Receipts & Ledger',
                icon: Icons.receipt_outlined,
                action: 'Open Ledger',
                onAction: () => Navigator.pushNamed(
                    context, SuperAdminRoutes.paymentLedger),
              ),
              const SizedBox(height: 12),
              ...ledger.asMap().entries.map(
                    (entry) => _LedgerRow(
                      entry: entry.value,
                      showDivider: entry.key != ledger.length - 1,
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
              _ReviewSectionHeader(
                title: 'Commission & Fees',
                icon: Icons.percent_rounded,
                action: 'Manage',
                onAction: () =>
                    Navigator.pushNamed(context, SuperAdminRoutes.fees),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: fees.map((rule) => _FeeRuleChip(rule: rule)).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.bookingId} - ${entry.milestone}',
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.micro.copyWith(
                    color: colors.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
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
                  label: _statusLabel[entry.status] ?? '', tone: tone),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeeRuleChip extends StatelessWidget {
  final (String, String, String) rule;

  const _FeeRuleChip({required this.rule});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colors.softSurface.withValues(alpha: colors.isLight ? 1 : 0.6),
        border: Border.all(color: colors.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rule.$1,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rule.$2,
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
