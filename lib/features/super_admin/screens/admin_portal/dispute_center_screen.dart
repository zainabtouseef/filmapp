part of '../super_admin_screens.dart';

class DisputeCenterScreen extends StatefulWidget {
  const DisputeCenterScreen({super.key});

  @override
  State<DisputeCenterScreen> createState() => _DisputeCenterScreenState();
}

class _DisputeCenterScreenState extends State<DisputeCenterScreen> {
  Future<List<DisputeDto>>? _future;
  String _filter = 'All';
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= TrustSafetyScope.of(context).adminDisputes(force: true);
  }

  void _refresh() {
    setState(
      () => _future = TrustSafetyScope.of(context).adminDisputes(force: true),
    );
  }

  List<DisputeDto> _visible(List<DisputeDto> disputes) {
    return disputes.where((dispute) {
      final type = dispute.type.toLowerCase();
      return switch (_filter) {
        'Open' => dispute.status == 'open',
        'Escalated' => dispute.status == 'escalated',
        'Resolved' => {'resolved', 'rejected'}.contains(dispute.status),
        'Payment' => type.contains('payment'),
        'Completion' => type.contains('completion'),
        'Cancellation' => type.contains('cancellation'),
        'Damage' => type.contains('damage'),
        'Safety' => type.contains('safety') || type.contains('harassment'),
        _ => true,
      };
    }).toList();
  }

  Future<void> _decide(DisputeDto dispute, String decision) async {
    final note = await _adminNotePrompt(
      context,
      title: '${decision[0].toUpperCase()}${decision.substring(1)} dispute',
      hint: 'Record the ruling, evidence basis, and next operational step.',
    );
    if (!mounted || note == null || _busyId != null) return;
    setState(() => _busyId = dispute.publicId);
    try {
      await TrustSafetyScope.of(context).decideDispute(
        disputeId: dispute.publicId,
        decision: decision,
        note: note,
      );
      if (!mounted) return;
      showCoreSnack(context, 'Dispute changed to $decision.');
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSurface(
          child: Column(
            children: [
              AdminFilterBar(
                filters: const [
                  'All',
                  'Open',
                  'Escalated',
                  'Resolved',
                  'Payment',
                  'Completion',
                  'Cancellation',
                  'Damage',
                  'Safety',
                ],
                selected: _filter,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: AdminActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Refresh',
                  secondary: true,
                  onTap: _refresh,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<DisputeDto>>(
          future: _future,
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
                      icon: Icons.gpp_bad_outlined,
                      title: 'Could not load disputes',
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
            final all = snapshot.data ?? const <DisputeDto>[];
            final rows = _visible(all);
            if (rows.isEmpty) {
              return const AdminEmptyState(
                icon: Icons.verified_user_outlined,
                title: 'No matching disputes',
                message: 'This dispute view is currently clear.',
              );
            }
            return Column(
              children: [
                _ResponsiveGrid(
                  minTileWidth: 180,
                  childAspectRatio: 2.7,
                  children: [
                    AdminMetricTile(
                      label: 'Open',
                      value:
                          '${all.where((item) => item.status == 'open').length}',
                      icon: Icons.folder_open_outlined,
                      tone: AdminDecisionTone.warning,
                    ),
                    AdminMetricTile(
                      label: 'Escalated',
                      value:
                          '${all.where((item) => item.status == 'escalated').length}',
                      icon: Icons.priority_high_rounded,
                      tone: AdminDecisionTone.danger,
                    ),
                    AdminMetricTile(
                      label: 'Resolved',
                      value: '${all.where((item) => {
                            'resolved',
                            'rejected',
                          }.contains(item.status)).length}',
                      icon: Icons.task_alt_outlined,
                      tone: AdminDecisionTone.success,
                    ),
                    AdminMetricTile(
                      label: 'High severity',
                      value:
                          '${all.where((item) => item.severity == 'high').length}',
                      icon: Icons.health_and_safety_outlined,
                      tone: AdminDecisionTone.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final dispute in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LiveDisputeCard(
                      dispute: dispute,
                      busy: _busyId == dispute.publicId,
                      onOpen: () => Navigator.pushNamed(
                        context,
                        SuperAdminRoutes.disputePath(dispute.publicId),
                      ),
                      onResolve: () => _decide(dispute, 'resolved'),
                      onEscalate: () => _decide(dispute, 'escalated'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LiveDisputeCard extends StatelessWidget {
  final DisputeDto dispute;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onResolve;
  final VoidCallback onEscalate;

  const _LiveDisputeCard({
    required this.dispute,
    required this.busy,
    required this.onOpen,
    required this.onResolve,
    required this.onEscalate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final high = dispute.severity == 'high';
    final amount = dispute.valueMinor == null
        ? 'Value not stated'
        : '${dispute.currency} '
            '${(dispute.valueMinor! / 100).toStringAsFixed(0)}';
    return AdminSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: high ? colors.danger : colors.goldMid,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dispute.type,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        _text(
                          context,
                          '${dispute.publicId} · Booking ${dispute.bookingId}',
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            AdminStatusBadge(
                              label: dispute.status,
                              tone: dispute.status == 'open'
                                  ? AdminDecisionTone.warning
                                  : dispute.status == 'escalated'
                                      ? AdminDecisionTone.danger
                                      : AdminDecisionTone.success,
                            ),
                            AdminRiskBadge(
                              label: dispute.severity,
                              risk: high
                                  ? AdminRiskTone.high
                                  : AdminRiskTone.medium,
                            ),
                            AdminStatusBadge(
                              label: amount,
                              tone: AdminDecisionTone.info,
                            ),
                            AdminStatusBadge(
                              label: '${dispute.evidenceCount} evidence',
                              tone: AdminDecisionTone.neutral,
                            ),
                          ],
                        ),
                      ],
                    );
                    final actions = Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tinyAction(context, 'Open', busy ? null : onOpen),
                        _tinyAction(
                          context,
                          'Resolve',
                          busy ||
                                  {'resolved', 'rejected'}
                                      .contains(dispute.status)
                              ? null
                              : onResolve,
                        ),
                        _tinyAction(
                          context,
                          'Escalate',
                          busy || dispute.status == 'escalated'
                              ? null
                              : onEscalate,
                        ),
                      ],
                    );
                    if (constraints.maxWidth < 720) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          details,
                          const SizedBox(height: 10),
                          actions,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: details),
                        const SizedBox(width: 12),
                        actions,
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
