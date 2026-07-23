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
  Future<List<PaymentProofDto>>? _proofsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _proofsFuture ??= PaymentsScope.of(context).adminProofs(force: true);
  }

  void _refresh() {
    setState(
      () => _proofsFuture = PaymentsScope.of(context).adminProofs(force: true),
    );
  }

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

  AdminPaymentProof _toAdminProof(PaymentProofDto proof) {
    return AdminPaymentProof(
      proofId: proof.publicId,
      bookingId: proof.bookingId.isEmpty ? 'Booking' : proof.bookingId,
      contractId:
          proof.transactionId.isEmpty ? 'Payment proof' : proof.transactionId,
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
    return FutureBuilder<List<PaymentProofDto>>(
      future: _proofsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AdminSurface(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return AdminSurface(
            child: Column(
              children: [
                AdminEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Could not load payment proofs',
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
        final proofs = (snapshot.data ?? const []).map(_toAdminProof).toList();
        return _queueContent(context, proofs);
      },
    );
  }

  Widget _queueContent(BuildContext context, List<AdminPaymentProof> source) {
    final filtered = source.where(_matches).toList()
      ..sort((a, b) => _sortValue
          ? b.claimedAmount.compareTo(a.claimedAmount)
          : b.age.compareTo(a.age));
    final pending = source.where((proof) => proof.status == 'pending').toList();
    final totalPending =
        pending.fold<int>(0, (total, proof) => total + proof.claimedAmount);
    final highValue =
        source.where((proof) => proof.claimedAmount >= 100000).length;
    final mismatch =
        source.where((proof) => proof.risk == 'Amount Mismatch').length;
    final duplicate =
        source.where((proof) => proof.risk == 'Duplicate Proof').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveGrid(
          minTileWidth: 190,
          childAspectRatio: 2.6,
          children: [
            AdminMetricTile(
                label: 'Total pending value',
                value: 'PKR ${_adminMoney(totalPending)}',
                icon: Icons.account_balance_wallet_outlined,
                tone: AdminDecisionTone.warning),
            AdminMetricTile(
                label: 'High-value proofs',
                value: '$highValue',
                icon: Icons.priority_high_rounded,
                tone: AdminDecisionTone.danger),
            AdminMetricTile(
                label: 'Mismatch alerts',
                value: '$mismatch',
                icon: Icons.compare_arrows_rounded,
                tone: AdminDecisionTone.danger),
            AdminMetricTile(
                label: 'Duplicate warnings',
                value: '$duplicate',
                icon: Icons.copy_all_outlined,
                tone: AdminDecisionTone.warning),
            const AdminMetricTile(
                label: 'Oldest pending proof',
                value: 'Live',
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
        if (filtered.isEmpty)
          const AdminEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching proofs',
            message: 'Try a different filter.',
          )
        else
          ...filtered.map(
            (proof) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PaymentProofRow(
                proof: proof,
                onReview: () => Navigator.pushNamed(
                  context,
                  SuperAdminRoutes.paymentReviewPath(proof.proofId!),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _methodLabel(String value) {
  return switch (value) {
    'bank_transfer' => 'Bank Transfer',
    'card_sandbox' => 'Gateway Ref',
    'wallet' => 'Wallet',
    _ => value.replaceAll('_', ' '),
  };
}

String _adminMoney(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return '$value';
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final identity = Column(
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
              ],
            );
            final statuses = Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                AdminStatusBadge(
                  label: proof.milestone,
                  tone: AdminDecisionTone.neutral,
                ),
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
            );
            final reviewControls = Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AdminRiskBadge(label: proof.risk, risk: risk),
                AdminSlaBadge(age: proof.age),
                _tinyAction(context, 'Review', onReview),
              ],
            );
            final receiptIcon = Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colors.goldGlow.withValues(alpha: 0.16),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: colors.goldDark,
                size: 22,
              ),
            );

            if (constraints.maxWidth < 380) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      receiptIcon,
                      const SizedBox(width: 10),
                      Expanded(child: identity),
                    ],
                  ),
                  const SizedBox(height: 10),
                  statuses,
                  const SizedBox(height: 10),
                  reviewControls,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                receiptIcon,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      identity,
                      const SizedBox(height: 6),
                      statuses,
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 190),
                  child: reviewControls,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
