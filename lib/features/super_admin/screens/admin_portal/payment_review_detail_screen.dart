part of '../super_admin_screens.dart';

class PaymentReviewDetailScreen extends StatefulWidget {
  final String? proofId;

  const PaymentReviewDetailScreen({super.key, this.proofId});

  @override
  State<PaymentReviewDetailScreen> createState() =>
      _PaymentReviewDetailScreenState();
}

class _PaymentReviewDetailScreenState extends State<PaymentReviewDetailScreen> {
  Future<AdminPaymentProofDetailDto>? _future;
  bool _deciding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<AdminPaymentProofDetailDto> _load() async {
    final payments = PaymentsScope.of(context);
    var id = widget.proofId;
    if (id == null || id.isEmpty || id == ':id') {
      final proofs = await payments.adminProofs();
      if (proofs.isEmpty) {
        throw const ApiException(
          code: 'payment_proof.not_found',
          message: 'No payment proof is available for review.',
        );
      }
      id = proofs.first.publicId;
    }
    return payments.adminProof(id);
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  Future<void> _decide(
    PaymentProofDto proof,
    String decision, {
    String? reason,
  }) async {
    if (_deciding) return;
    setState(() => _deciding = true);
    try {
      final result = await PaymentsScope.of(context).decideProof(
        proofId: proof.publicId,
        decision: decision,
        reason: reason,
      );
      if (!mounted) return;
      showCoreSnack(
        context,
        result.receipt == null
            ? 'Payment proof updated.'
            : 'Payment verified. Receipt '
                '${result.receipt!.receiptNumber} generated.',
      );
      await _advanceToNext(proof.publicId);
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _deciding = false);
    }
  }

  // A finance admin working the queue expects verifying/rejecting one
  // proof to hand them straight to the next one, not to sit on the same
  // decided proof until they manually go back to the list and pick again.
  Future<void> _advanceToNext(String decidedProofId) async {
    List<PaymentProofDto> proofs;
    try {
      proofs = await PaymentsScope.of(context).adminProofs(force: true);
    } catch (_) {
      if (mounted) _refresh();
      return;
    }
    if (!mounted) return;
    PaymentProofDto? next;
    for (final item in proofs) {
      if (item.publicId != decidedProofId && item.status == 'pending') {
        next = item;
        break;
      }
    }
    if (next != null) {
      Navigator.pushReplacementNamed(
        context,
        SuperAdminRoutes.paymentReviewPath(next.publicId),
      );
      return;
    }
    showCoreSnack(context, 'No more payment proofs are waiting for review.');
    Navigator.pop(context, true);
  }

  Future<void> _decisionWithReason(
    PaymentProofDto proof,
    String decision,
  ) async {
    final reason = await _adminNotePrompt(
      context,
      title: decision == 'rejected'
          ? 'Reject payment proof'
          : 'Request clarification',
      hint: decision == 'rejected'
          ? 'Record the finance rejection reason.'
          : 'Tell the payer what must be corrected or re-uploaded.',
    );
    if (!mounted || reason == null) return;
    await _decide(proof, decision, reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminPaymentProofDetailDto>(
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
                  icon: Icons.receipt_long_outlined,
                  title: 'Payment proof unavailable',
                  message: error is ApiException
                      ? error.message
                      : 'The payment proof could not be loaded.',
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
        return _detailContent(context, snapshot.data!);
      },
    );
  }

  Widget _detailContent(
    BuildContext context,
    AdminPaymentProofDetailDto detail,
  ) {
    final proof = detail.proof;
    final status = proof.status.replaceAll('_', ' ');
    return _TwoPane(
      leftFlex: 5,
      rightFlex: 4,
      left: AdminSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(
              title: 'Proof viewer',
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            _PaymentProofMedia(proof: proof),
            const SizedBox(height: 12),
            AdminProofViewer(
              title: 'Submitted payment data',
              ocrLines: [
                'Proof ID: ${proof.publicId}',
                'Transaction: ${proof.transactionReference ?? proof.transactionId}',
                'Amount: ${proof.amountLabel}',
                'Method: ${_methodLabel(proof.method)}',
                'Submitted by: ${proof.submittedBy.displayName}',
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
            _reviewCard(context, 'Booking summary', [
              proof.bookingId,
              'Milestone ${proof.milestoneId}',
              'Submitted by ${proof.submittedBy.displayName}',
              status,
            ]),
            _reviewDivider(context),
            _reviewCard(context, 'Uploaded claim', [
              proof.amountLabel,
              proof.transactionReference ?? 'No bank reference supplied',
              'Risk score ${proof.riskScore}',
              proof.rejectionReason ?? 'No prior decision note',
            ]),
            _reviewDivider(context),
            _reviewCard(context, 'Decision history', [
              proof.reviewedBy == null
                  ? 'Awaiting finance admin decision'
                  : 'Reviewed by ${proof.reviewedBy!.displayName}',
              _adminDateTime(proof.reviewedAt),
              '${detail.bookingEvents.length} linked booking events',
            ]),
            const SizedBox(height: 12),
            AdminStatusBadge(
              label: status,
              tone: switch (proof.status) {
                'verified' => AdminDecisionTone.success,
                'rejected' => AdminDecisionTone.danger,
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
                  label: _deciding ? 'Saving...' : 'Verify payment',
                  onTap: _deciding || proof.status == 'verified'
                      ? null
                      : () => _decide(proof, 'approved'),
                ),
                AdminActionButton(
                  icon: Icons.cancel_outlined,
                  label: 'Reject with reason',
                  secondary: true,
                  onTap: _deciding
                      ? null
                      : () => _decisionWithReason(proof, 'rejected'),
                ),
                AdminActionButton(
                  icon: Icons.contact_support_outlined,
                  label: 'Ask clarification',
                  secondary: true,
                  onTap: _deciding
                      ? null
                      : () => _decisionWithReason(
                            proof,
                            'clarification_requested',
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentProofMedia extends StatefulWidget {
  final PaymentProofDto proof;

  const _PaymentProofMedia({required this.proof});

  @override
  State<_PaymentProofMedia> createState() => _PaymentProofMediaState();
}

class _PaymentProofMediaState extends State<_PaymentProofMedia> {
  int _quarterTurns = 0;
  final _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Payment proofs are private uploads — `filePublicUrl` is only ever
    // populated for publicly-visible files, so it's always null here.
    // `fileDownloadUrl` (server-relative) is what actually resolves for
    // an authorized admin, given the client's origin and an auth header.
    final apiClient = AuthScope.of(context).apiClient;
    final url = widget.proof.fileDownloadUrl != null
        ? apiClient.resolve(widget.proof.fileDownloadUrl!).toString()
        : widget.proof.filePublicUrl;
    final imageHeaders = apiClient.accessToken == null
        ? null
        : {'Authorization': 'Bearer ${apiClient.accessToken}'};
    return Container(
      width: double.infinity,
      height: 360,
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: url == null || url.isEmpty
                ? Center(
                    child: AdminEmptyState(
                      icon: Icons.insert_drive_file_outlined,
                      title: 'No public proof preview',
                      message: widget.proof.fileMimeType == null
                          ? 'Review the submitted payment metadata.'
                          : 'File type: ${widget.proof.fileMimeType}',
                    ),
                  )
                : InteractiveViewer(
                    transformationController: _transform,
                    minScale: 0.7,
                    maxScale: 5,
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: _quarterTurns,
                        child: Image.network(
                          url,
                          headers: imageHeaders,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const AdminEmptyState(
                            icon: Icons.broken_image_outlined,
                            title: 'Preview could not be rendered',
                            message: 'Use the proof metadata for this review.',
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Row(
              children: [
                AdminIconButton(
                  icon: Icons.center_focus_strong_rounded,
                  tooltip: 'Reset zoom',
                  onTap: () => _transform.value = Matrix4.identity(),
                ),
                const SizedBox(width: 6),
                AdminIconButton(
                  icon: Icons.rotate_right_rounded,
                  tooltip: 'Rotate proof',
                  onTap: () => setState(
                    () => _quarterTurns = (_quarterTurns + 1) % 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
