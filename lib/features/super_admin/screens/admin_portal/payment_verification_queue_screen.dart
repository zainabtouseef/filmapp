part of '../super_admin_screens.dart';

class PaymentVerificationQueueScreen extends StatefulWidget {
  const PaymentVerificationQueueScreen({super.key});

  @override
  State<PaymentVerificationQueueScreen> createState() =>
      _PaymentVerificationQueueScreenState();
}

class _PaymentVerificationQueueScreenState
    extends State<PaymentVerificationQueueScreen> {
  String _filter = 'All';
  bool _sortValue = true;

  bool _matches(AdminPaymentProof proof) {
    final ageHours = int.tryParse(proof.age.replaceAll('h', '')) ?? 0;
    return switch (_filter) {
      'High Value' => proof.claimedAmount >= 100000,
      'Amount Mismatch' => proof.risk == 'Amount Mismatch',
      'Duplicate Proof' => proof.risk == 'Duplicate Proof',
      'Bank Transfer' => proof.method == 'Bank Transfer',
      'Wallet' => proof.method == 'Wallet',
      'Gateway Ref' => proof.method == 'Gateway Ref',
      '24h+' => ageHours >= 24,
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final proofs =
        AdminMockData.paymentProofs.where(_matches).toList()
          ..sort((a, b) => _sortValue
              ? b.claimedAmount.compareTo(a.claimedAmount)
              : b.age.compareTo(a.age));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveGrid(
          minTileWidth: 190,
          childAspectRatio: 2.6,
          children: const [
            AdminMetricTile(
                label: 'Total pending value',
                value: 'PKR 4.2M',
                icon: Icons.account_balance_wallet_outlined,
                tone: AdminDecisionTone.warning),
            AdminMetricTile(
                label: 'High-value proofs',
                value: '6',
                icon: Icons.priority_high_rounded,
                tone: AdminDecisionTone.danger),
            AdminMetricTile(
                label: 'Mismatch alerts',
                value: '3',
                icon: Icons.compare_arrows_rounded,
                tone: AdminDecisionTone.danger),
            AdminMetricTile(
                label: 'Duplicate warnings',
                value: '2',
                icon: Icons.copy_all_outlined,
                tone: AdminDecisionTone.warning),
            AdminMetricTile(
                label: 'Oldest pending proof',
                value: '27h',
                icon: Icons.timer_outlined,
                tone: AdminDecisionTone.warning),
          ],
        ),
        const SizedBox(height: 18),
        AdminFilterBar(
          filters: const [
            'All',
            'High Value',
            'Amount Mismatch',
            'Duplicate Proof',
            'Bank Transfer',
            'Wallet',
            'Gateway Ref',
            '24h+'
          ],
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 12),
        AdminActionButton(
          icon: _sortValue ? Icons.sort_by_alpha_rounded : Icons.timer_outlined,
          label: _sortValue ? 'Sorting by value' : 'Sorting by age',
          secondary: true,
          onTap: () => setState(() => _sortValue = !_sortValue),
        ),
        const SizedBox(height: 16),
        if (proofs.isEmpty)
          const AdminEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching proofs',
            message: 'Try a different filter.',
          )
        else
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
    );
  }
}

class _PaymentProofRow extends StatelessWidget {
  final AdminPaymentProof proof;
  final VoidCallback onReview;

  const _PaymentProofRow({required this.proof, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final risk = proof.risk == 'No Risk'
        ? AdminRiskTone.low
        : proof.risk == 'Duplicate Proof'
            ? AdminRiskTone.high
            : AdminRiskTone.critical;
    return GestureDetector(
      onTap: onReview,
      child: AdminSurface(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colors.goldGlow.withValues(alpha: 0.16),
              ),
              child: Icon(Icons.receipt_long_outlined,
                  color: colors.goldDark, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${proof.bookingId} - ${proof.contractId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${proof.payer} -> ${proof.payee}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.micro.copyWith(
                      color: colors.textSecondary,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      AdminStatusBadge(
                          label: proof.milestone,
                          tone: AdminDecisionTone.neutral),
                      AdminStatusBadge(
                        label: 'Exp ${proof.expectedAmount}',
                        tone: AdminDecisionTone.neutral,
                      ),
                      AdminStatusBadge(
                        label: 'Claim ${proof.claimedAmount}',
                        tone: proof.expectedAmount == proof.claimedAmount
                            ? AdminDecisionTone.success
                            : AdminDecisionTone.danger,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AdminRiskBadge(label: proof.risk, risk: risk),
                const SizedBox(height: 6),
                AdminSlaBadge(age: proof.age),
                const SizedBox(height: 6),
                _ReviewOutlineButton(label: 'Review', onTap: onReview),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
