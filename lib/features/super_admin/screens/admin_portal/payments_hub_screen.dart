part of '../super_admin_screens.dart';

class PaymentsHubScreen extends StatelessWidget {
  const PaymentsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final proofs = AdminMockData.paymentProofs.take(3).toList();
    final ledger = AdminMockData.ledgerEntries.take(3).toList();
    final fees = AdminMockData.commissionRules.take(3).toList();
    const metricTiles = [
      AdminMetricTile(
          label: 'Pending Value',
          value: 'PKR 4.2M',
          icon: Icons.account_balance_wallet_outlined,
          tone: AdminDecisionTone.warning),
      AdminMetricTile(
          label: 'High-Value Proofs',
          value: '6',
          icon: Icons.priority_high_rounded,
          tone: AdminDecisionTone.danger),
      AdminMetricTile(
          label: 'Mismatch Alerts',
          value: '3',
          icon: Icons.compare_arrows_rounded,
          tone: AdminDecisionTone.danger),
      AdminMetricTile(
          label: 'Duplicate Warnings',
          value: '2',
          icon: Icons.copy_all_outlined,
          tone: AdminDecisionTone.warning),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                        context, SuperAdminRoutes.paymentReview),
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
