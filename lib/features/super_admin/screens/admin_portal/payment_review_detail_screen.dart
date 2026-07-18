part of '../super_admin_screens.dart';

class PaymentReviewDetailScreen extends StatefulWidget {
  final String? proofId;

  const PaymentReviewDetailScreen({super.key, this.proofId});

  @override
  State<PaymentReviewDetailScreen> createState() =>
      _PaymentReviewDetailScreenState();
}

class _PaymentReviewDetailScreenState extends State<PaymentReviewDetailScreen> {
  String _status = 'Pending Review';
  Future<AdminPaymentProofDetailDto?>? _detailFuture;
  bool _deciding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final payments = PaymentsScope.maybeOf(context);
    final proofId = widget.proofId;
    if (_detailFuture == null && payments != null) {
      _detailFuture = proofId == null || proofId.isEmpty
          ? payments.adminProofs(force: false).then((proofs) => proofs.isEmpty
              ? null
              : payments.adminProof(proofs.first.publicId))
          : payments.adminProof(proofId);
    }
  }

  Future<void> _decide(String decision, {String? reason}) async {
    final payments = PaymentsScope.maybeOf(context);
    final proofId = widget.proofId;
    if (payments == null || proofId == null || proofId.isEmpty) {
      setState(() {
        _status = switch (decision) {
          'approved' => 'Verified',
          'rejected' => 'Rejected',
          'clarification_requested' => 'Clarification Requested',
          _ => 'Suspicious',
        };
      });
      return;
    }
    setState(() => _deciding = true);
    try {
      final result = await payments.decideProof(
        proofId: proofId,
        decision: decision,
        reason: reason,
      );
      if (!mounted) return;
      setState(() {
        _status = result.proof.status.replaceAll('_', ' ');
        _detailFuture = payments.adminProof(proofId);
      });
      showCoreSnack(
        context,
        result.receipt == null
            ? 'Payment proof updated.'
            : 'Payment verified. Receipt ${result.receipt!.receiptNumber} generated.',
      );
    } catch (error) {
      if (!mounted) return;
      final message =
          error is ApiException ? error.message : 'Could not update proof.';
      showCoreSnack(context, message);
    } finally {
      if (mounted) setState(() => _deciding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_detailFuture != null) {
      return FutureBuilder<AdminPaymentProofDetailDto?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Could not load this payment proof.';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InlineNotice(message: message, tone: CoreStatusTone.warning),
                const SizedBox(height: 16),
                _detailContent(context),
              ],
            );
          }
          final detail = snapshot.data;
          if (detail == null) {
            return const AdminEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No payment proof selected',
              message: 'Open a proof from the payment verification queue.',
            );
          }
          return _detailContent(context, detail: detail);
        },
      );
    }
    return _detailContent(context);
  }

  Widget _detailContent(
    BuildContext context, {
    AdminPaymentProofDetailDto? detail,
  }) {
    final proof = detail?.proof;
    final status = proof == null ? _status : proof.status.replaceAll('_', ' ');
    return _TwoPane(
      leftFlex: 5,
      rightFlex: 4,
      left: AdminSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(
              title: 'Proof Viewer',
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            AdminProofViewer(
              title: 'Bank transfer proof preview',
              ocrLines: [
                'Proof ID: ${proof?.publicId ?? 'Demo proof'}',
                'Transaction ID: ${proof?.transactionReference ?? proof?.transactionId ?? 'HBL-884120'}',
                'Amount: PKR ${_adminMoney((proof?.claimedAmountMinor ?? 9000000) ~/ 100)}',
                'Method: ${_methodLabel(proof?.method ?? 'bank_transfer')}',
                'Submitted by: ${proof?.submittedBy.displayName ?? 'Hamza Productions'}',
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tinyAction(context, 'Zoom',
                    () => showCoreSnack(context, 'Zoom simulated')),
                _tinyAction(context, 'Rotate',
                    () => showCoreSnack(context, 'Proof rotated')),
                _tinyAction(context, 'Download',
                    () => showCoreSnack(context, 'Proof download simulated')),
              ],
            ),
          ],
        ),
      ),
      right: AdminSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CASE DETAILS', style: AppTextStyles.panelLabel),
            const SizedBox(height: 10),
            _reviewCard(context, 'Booking Summary', [
              proof?.bookingId ?? 'BK-2048',
              'Milestone ${proof?.milestoneId ?? 'Deposit'}',
              'Payment proof',
              status,
              'Submitted by ${proof?.submittedBy.displayName ?? 'Hamza'}'
            ]),
            _reviewDivider(context),
            _reviewCard(context, 'Contract Payment Schedule', [
              proof?.milestoneId ?? 'Deposit',
              'Expected PKR ${_adminMoney((proof?.claimedAmountMinor ?? 9000000) ~/ 100)}',
              'Schedule attached to booking',
              'Payee locked by contract',
              'Manual bank transfer/card sandbox allowed'
            ]),
            _reviewDivider(context),
            _reviewCard(context, 'Uploaded Claim', [
              'Claimed PKR ${_adminMoney((proof?.claimedAmountMinor ?? 9000000) ~/ 100)}',
              proof?.transactionReference ?? 'HBL-884120',
              'Uploaded by ${proof?.submittedBy.displayName ?? 'Hamza'}',
              'Risk score ${proof?.riskScore ?? 0}',
              proof?.rejectionReason ?? 'No notes'
            ]),
            _reviewDivider(context),
            _reviewCard(context, 'Bank Details on File', [
              'Payment method ${_methodLabel(proof?.method ?? 'bank_transfer')}',
              'Reference ${proof?.transactionReference ?? 'pending manual check'}',
              proof?.reviewedBy == null
                  ? 'Awaiting finance admin decision'
                  : 'Reviewed by ${proof!.reviewedBy!.displayName}'
            ]),
            const SizedBox(height: 12),
            AdminStatusBadge(
              label: status,
              tone: switch (proof?.status ?? _status) {
                'verified' ||
                'Verified' ||
                'approved' =>
                  AdminDecisionTone.success,
                'rejected' ||
                'Rejected' ||
                'Suspicious' =>
                  AdminDecisionTone.danger,
                _ => AdminDecisionTone.warning,
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                AdminActionButton(
                    icon: Icons.verified_outlined,
                    label: _deciding ? 'Saving...' : 'Verify Payment',
                    onTap: _deciding ? null : () => _decide('approved')),
                AdminActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Reject with Reason',
                    secondary: true,
                    onTap: _deciding
                        ? null
                        : () => _noteDialog(
                              context,
                              'Payment rejection reason',
                              onSave: () => _decide(
                                'rejected',
                                reason: 'Rejected after finance review',
                              ),
                            )),
                AdminActionButton(
                    icon: Icons.contact_support_outlined,
                    label: 'Ask Clarification',
                    secondary: true,
                    onTap: _deciding
                        ? null
                        : () => _noteDialog(
                              context,
                              'Clarification message',
                              onSave: () => _decide(
                                'clarification_requested',
                                reason:
                                    'Please upload a clearer payment proof.',
                              ),
                            )),
                AdminActionButton(
                    icon: Icons.warning_amber_rounded,
                    label: 'Mark Suspicious',
                    secondary: true,
                    onTap: _deciding
                        ? null
                        : () => setState(() => _status = 'Suspicious')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
