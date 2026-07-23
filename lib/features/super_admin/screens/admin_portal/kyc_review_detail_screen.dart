part of '../super_admin_screens.dart';

class KycReviewDetailScreen extends StatefulWidget {
  final String? submissionId;

  const KycReviewDetailScreen({super.key, this.submissionId});

  @override
  State<KycReviewDetailScreen> createState() => _KycReviewDetailScreenState();
}

class _KycReviewDetailScreenState extends State<KycReviewDetailScreen> {
  String _document = 'CNIC Front';
  double _zoom = 1;
  int _quarterTurns = 0;
  final Set<String> _checked = {'Identity document readable'};
  final _note = TextEditingController();
  Future<verification.KycSubmission>? _submissionFuture;
  bool _savingDecision = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final submissionId = widget.submissionId;
    if (_submissionFuture == null && submissionId != null) {
      _submissionFuture =
          AuthScope.of(context).adminKycSubmission(submissionId);
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.submissionId == null) {
      return const AdminEmptyState(
        icon: Icons.fact_check_outlined,
        title: 'Open a submission from the queue',
        message: 'Choose a KYC row first so the admin review can load.',
      );
    }
    return FutureBuilder<verification.KycSubmission>(
      future: _submissionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AdminSurface(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          final error = snapshot.error;
          return AdminSurface(
            child: Column(
              children: [
                AdminEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: error is ApiException && error.statusCode == 403
                      ? 'KYC review permission required'
                      : 'Could not load KYC submission',
                  message: error is ApiException
                      ? error.message
                      : 'Check your connection and try again.',
                ),
                const SizedBox(height: 12),
                AdminActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Retry',
                  secondary: true,
                  onTap: () => setState(() {
                    _submissionFuture = AuthScope.of(context)
                        .adminKycSubmission(widget.submissionId!);
                  }),
                ),
              ],
            ),
          );
        }
        final submission = snapshot.data!;
        return _content(context, submission);
      },
    );
  }

  Widget _content(BuildContext context, verification.KycSubmission submission) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Matches _ThreePane's threshold so this screen's three-column
        // layout switches together with the side nav rather than showing
        // desktop chrome next to still-stacked content.
        final wide =
            MediaQuery.sizeOf(context).width >= AppBreakpoints.wideDesktop;
        final children = [
          _applicantPanel(context, submission),
          _documentPanel(context, submission),
          _decisionPanel(context, submission),
        ];
        if (!wide) {
          return Column(
            children: children
                .map((child) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: child,
                    ))
                .toList(),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 270, child: children[0]),
            const SizedBox(width: 16),
            Expanded(child: children[1]),
            const SizedBox(width: 16),
            SizedBox(width: 330, child: children[2]),
          ],
        );
      },
    );
  }

  Widget _applicantPanel(
      BuildContext context, verification.KycSubmission submission) {
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminUserMiniCard(
            name: submission.applicantName,
            detail: '${submission.roleName} - ${submission.applicantEmail}',
            badge: submission.status,
          ),
          const SizedBox(height: 14),
          AdminRiskBadge(
            label: 'Risk ${submission.riskLevel}',
            risk: submission.riskLevel == 'high'
                ? AdminRiskTone.high
                : AdminRiskTone.low,
          ),
          const SizedBox(height: 14),
          _kv(context, 'Email', submission.applicantEmail),
          _kv(context, 'Submission', submission.publicId),
          _kv(context, 'Status', submission.status),
          _kv(context, 'Documents', '${submission.files.length} uploaded'),
          _kv(
            context,
            'Scan state',
            submission.files.isEmpty
                ? 'No files'
                : submission.files
                    .map((file) => '${file.originalName}: ${file.scanStatus}')
                    .join(', '),
          ),
          const SizedBox(height: 14),
          AdminActionButton(
            icon: Icons.manage_search_outlined,
            label: 'Open Audit Logs',
            secondary: true,
            onTap: () =>
                Navigator.pushNamed(context, SuperAdminRoutes.auditLogs),
          ),
          const SizedBox(height: 10),
          AdminActionButton(
            icon: Icons.upload_file_outlined,
            label: 'View user KYC flow',
            secondary: true,
            onTap: () => Navigator.pushNamed(context, CoreRoutes.kyc),
          ),
        ],
      ),
    );
  }

  Widget _documentPanel(
      BuildContext context, verification.KycSubmission submission) {
    final filters = submission.documentTypes.isEmpty
        ? const ['Document']
        : submission.documentTypes;
    final selectedDocument =
        filters.contains(_document) ? _document : filters.first;
    final documentIndex = filters.indexOf(selectedDocument);
    final file = documentIndex >= 0 && documentIndex < submission.files.length
        ? submission.files[documentIndex]
        : submission.files.isEmpty
            ? null
            : submission.files.first;
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminFilterBar(
            filters: filters,
            selected: selectedDocument,
            onSelected: (value) => setState(() => _document = value),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 360,
            decoration: BoxDecoration(
              color: context.appColors.softSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.appColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: file?.publicUrl != null &&
                    file!.mimeType.startsWith('image/')
                ? InteractiveViewer(
                    minScale: 0.7,
                    maxScale: 5,
                    child: Center(
                      child: Transform.scale(
                        scale: _zoom,
                        child: RotatedBox(
                          quarterTurns: _quarterTurns,
                          child: Image.network(
                            file.publicUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => AdminEvidenceViewer(
                              title: selectedDocument,
                              icon: Icons.broken_image_outlined,
                              details: [file.originalName],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : AdminEvidenceViewer(
                    title: selectedDocument,
                    icon: Icons.article_outlined,
                    details: file == null
                        ? const ['No file attached']
                        : [
                            file.originalName,
                            file.mimeType,
                            file.scanStatus,
                          ],
                  ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AdminActionButton(
                icon: Icons.zoom_in_rounded,
                label: 'Zoom in',
                secondary: true,
                onTap: () =>
                    setState(() => _zoom = (_zoom + .08).clamp(1, 1.3)),
              ),
              AdminActionButton(
                icon: Icons.zoom_out_rounded,
                label: 'Zoom out',
                secondary: true,
                onTap: () =>
                    setState(() => _zoom = (_zoom - .08).clamp(1, 1.3)),
              ),
              AdminActionButton(
                icon: Icons.rotate_right_rounded,
                label: 'Rotate',
                secondary: true,
                onTap: () => setState(
                  () => _quarterTurns = (_quarterTurns + 1) % 4,
                ),
              ),
              AdminActionButton(
                icon: Icons.center_focus_strong_rounded,
                label: 'Reset view',
                secondary: true,
                onTap: () => setState(() {
                  _zoom = 1;
                  _quarterTurns = 0;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _decisionPanel(
      BuildContext context, verification.KycSubmission submission) {
    final checks = const [
      'Identity document readable',
      'Selfie matches document',
      'Name matches account',
      'Role-specific docs valid',
      'Bank account title matches user',
      'Address proof verified',
      'No duplicate CNIC',
      'No duplicate device risk',
    ];
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Review Checklist',
            icon: Icons.checklist_rounded,
          ),
          const SizedBox(height: 8),
          ...checks.map(
            (check) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _checked.contains(check),
              onChanged: (value) {
                setState(() {
                  if (value ?? false) {
                    _checked.add(check);
                  } else {
                    _checked.remove(check);
                  }
                });
              },
              title: Text(check),
            ),
          ),
          const SizedBox(height: 12),
          CoreTextField(
            controller: _note,
            label: 'Add internal risk note...',
            icon: Icons.note_alt_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 14),
          AdminActionButton(
            icon: Icons.verified_outlined,
            label: _savingDecision ? 'Saving...' : 'Approve',
            onTap: _savingDecision
                ? null
                : () => _decision(
                      context,
                      submission,
                      decision: 'approved',
                      message: 'User approved. Marketplace access unlocked.',
                    ),
          ),
          const SizedBox(height: 10),
          AdminActionButton(
            icon: Icons.cancel_outlined,
            label: 'Reject with Reason',
            secondary: true,
            onTap: _savingDecision
                ? null
                : () => _decision(
                      context,
                      submission,
                      decision: 'rejected',
                      message: 'KYC rejected and reason saved.',
                    ),
          ),
          const SizedBox(height: 10),
          AdminActionButton(
            icon: Icons.contact_support_outlined,
            label: 'Request More Info',
            secondary: true,
            onTap: _savingDecision
                ? null
                : () => _decision(
                      context,
                      submission,
                      decision: 'needs_resubmission',
                      message: 'User asked to resubmit KYC information.',
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> _decision(
    BuildContext context,
    verification.KycSubmission submission, {
    required String decision,
    required String message,
  }) async {
    setState(() => _savingDecision = true);
    final auth = AuthScope.of(context);
    try {
      final updated = await auth.adminKycDecision(
        publicId: submission.publicId,
        decision: decision,
        reason: _note.text.trim(),
      );
      if (!context.mounted) return;
      setState(() {
        _submissionFuture = Future.value(updated);
        _savingDecision = false;
      });
      showCoreSuccessDialog(
        context,
        title: 'Decision Saved',
        message: message,
        onDone: () => showCoreSnack(context, 'Decision written to audit log.'),
      );
    } on ApiException catch (error) {
      if (!context.mounted) return;
      setState(() => _savingDecision = false);
      showCoreSnack(context, error.message);
    }
  }
}
