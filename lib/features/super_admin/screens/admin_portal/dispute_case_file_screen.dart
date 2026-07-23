part of '../super_admin_screens.dart';

class DisputeCaseFileScreen extends StatefulWidget {
  final String? disputeId;

  const DisputeCaseFileScreen({super.key, this.disputeId});

  @override
  State<DisputeCaseFileScreen> createState() => _DisputeCaseFileScreenState();
}

class _DisputeCaseFileScreenState extends State<DisputeCaseFileScreen> {
  Future<DisputeDto>? _future;
  final _ruling = TextEditingController();
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void dispose() {
    _ruling.dispose();
    super.dispose();
  }

  Future<DisputeDto> _load({bool force = false}) async {
    final trust = TrustSafetyScope.of(context);
    final id = widget.disputeId;
    if (id != null && id.isNotEmpty && id != ':id') {
      return trust.adminDispute(id, force: force);
    }
    final rows = await trust.adminDisputes(force: force);
    if (rows.isEmpty) {
      throw const ApiException(
        code: 'dispute.not_found',
        message: 'No dispute case is available.',
      );
    }
    return rows.first;
  }

  void _refresh() {
    setState(() => _future = _load(force: true));
  }

  Future<void> _decide(DisputeDto dispute, String decision) async {
    final note = _ruling.text.trim();
    if (note.isEmpty) {
      showCoreSnack(context, 'Write a ruling before recording a decision.');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await TrustSafetyScope.of(context).decideDispute(
        disputeId: dispute.publicId,
        decision: decision,
        note: note,
      );
      if (!mounted) return;
      _ruling.clear();
      showCoreSnack(context, 'Decision recorded and both parties notified.');
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DisputeDto>(
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
                  icon: Icons.gpp_bad_outlined,
                  title: 'Dispute case unavailable',
                  message: error is ApiException
                      ? error.message
                      : 'The dispute could not be loaded.',
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
        final dispute = snapshot.data!;
        final amount = dispute.valueMinor == null
            ? 'Value not stated'
            : '${dispute.currency} '
                '${(dispute.valueMinor! / 100).toStringAsFixed(0)}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSurface(
              padding: EdgeInsets.zero,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 6,
                      decoration: BoxDecoration(
                        color: dispute.severity == 'high'
                            ? context.appColors.danger
                            : context.appColors.goldMid,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _headline(context, dispute.type),
                                ),
                                AdminStatusBadge(
                                  label: dispute.status,
                                  tone: dispute.status == 'open'
                                      ? AdminDecisionTone.warning
                                      : dispute.status == 'escalated'
                                          ? AdminDecisionTone.danger
                                          : AdminDecisionTone.success,
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            _text(context, dispute.description),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                AdminStatusBadge(
                                  label: dispute.publicId,
                                  tone: AdminDecisionTone.info,
                                ),
                                AdminRiskBadge(
                                  label: dispute.severity,
                                  risk: dispute.severity == 'high'
                                      ? AdminRiskTone.high
                                      : AdminRiskTone.medium,
                                ),
                                AdminStatusBadge(
                                  label: amount,
                                  tone: AdminDecisionTone.warning,
                                ),
                                AdminStatusBadge(
                                  label: dispute.assignedAdmin?.displayName ??
                                      'Unassigned',
                                  tone: AdminDecisionTone.neutral,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _ThreePane(
              left: AdminSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionHeader(
                      title: 'Case timeline',
                      icon: Icons.history_rounded,
                    ),
                    const SizedBox(height: 10),
                    if (dispute.events.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.history_toggle_off_rounded,
                        title: 'No case events',
                        message: 'Decisions and evidence events appear here.',
                      )
                    else
                      AdminTimeline(
                        items: [
                          for (final event in dispute.events.reversed)
                            '${event.eventType} · '
                                '${event.actor?.displayName ?? 'System'}'
                                '${event.note == null ? '' : ' · ${event.note}'}',
                        ],
                      ),
                  ],
                ),
              ),
              center: AdminSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionHeader(
                      title: 'Evidence room',
                      icon: Icons.folder_copy_outlined,
                    ),
                    const SizedBox(height: 10),
                    _kv(
                      context,
                      'Opened by',
                      dispute.openedBy?.displayName ?? 'Unknown member',
                    ),
                    _kv(
                      context,
                      'Respondent',
                      dispute.respondent?.displayName ?? 'Unknown member',
                    ),
                    _kv(context, 'Booking', dispute.bookingId),
                    const SizedBox(height: 8),
                    if (dispute.evidence.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.folder_off_outlined,
                        title: 'No evidence uploaded',
                        message: 'Request evidence before a final ruling.',
                      )
                    else
                      for (final evidence in dispute.evidence) ...[
                        _bullet(
                          context,
                          '${evidence.evidenceType} · '
                          '${evidence.submittedBy?.displayName ?? 'Member'}'
                          '${evidence.description.isEmpty ? '' : ' · ${evidence.description}'}',
                        ),
                      ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _tinyAction(
                          context,
                          'Open booking',
                          () => Navigator.pushNamed(
                            context,
                            SuperAdminRoutes.bookingPath(dispute.bookingId),
                          ),
                        ),
                        _tinyAction(
                          context,
                          'Payment ledger',
                          () => Navigator.pushNamed(
                            context,
                            SuperAdminRoutes.paymentLedger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              right: AdminSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionHeader(
                      title: 'Decision panel',
                      icon: Icons.gavel_outlined,
                    ),
                    const SizedBox(height: 12),
                    CoreTextField(
                      controller: _ruling,
                      label: 'Evidence-based admin ruling',
                      icon: Icons.gavel_outlined,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 10),
                    _text(
                      context,
                      'A saved decision is written to the dispute timeline '
                      'and notifies both parties.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AdminActionButton(
                          icon: Icons.task_alt_outlined,
                          label: 'Resolve',
                          onTap:
                              _busy ? null : () => _decide(dispute, 'resolved'),
                        ),
                        AdminActionButton(
                          icon: Icons.close_rounded,
                          label: 'Reject claim',
                          secondary: true,
                          onTap:
                              _busy ? null : () => _decide(dispute, 'rejected'),
                        ),
                        AdminActionButton(
                          icon: Icons.priority_high_rounded,
                          label: 'Escalate',
                          secondary: true,
                          onTap: _busy
                              ? null
                              : () => _decide(dispute, 'escalated'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
